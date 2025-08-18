# Enemy.gd - Main enemy class
class_name Enemy
extends Character

## Enemy configuration and AI state
@export var enemy_data: EnemyData
var current_intent: EnemyAction
var action_cooldowns: Dictionary = {}  # Track cooldowns for each action
var turns_since_last_special: int = 0

## Visuals and Placement
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var stats_ui: Control = $StatsUI

## Intent display (UI element)
@onready var intent_display: Control = $IntentDisplay

func _ready():
	super._ready()  # Call Character._ready()
	
	if enemy_data:
		# using a deferred call to ensure the sprite texture is loaded.
		call_deferred("initialize_from_data")

func initialize_from_data():
	"""Initialize enemy stats from EnemyData resource"""
	if not enemy_data:
		push_error("Enemy has no EnemyData assigned!")
		return
	
	# init stats
	max_health = enemy_data.max_health
	current_health = max_health
	block = enemy_data.base_block
	attack = enemy_data.base_attack
	
	# Set sprite if available
	if sprite and enemy_data.sprite:
		sprite.texture = enemy_data.sprite
	
	# Initialize action cooldowns
	for action in enemy_data.possible_actions:
		action_cooldowns[action] = 0
	
	# Apply CollisionShape and Stats UI configuration
	apply_ui_placement()
	
func apply_ui_placement():
	"""
	Applies UI placement configuration from EnemyData.
	Called once from initialize_from_data().
	"""
	if not enemy_data or not sprite:
		push_error("Missing EnemyData or Sprite2D for UI placement!")
		return
	
	# Get the sprite's bounding box in its local coordinate system.
	var sprite_rect = sprite.get_rect()
	var sprite_size = sprite_rect.size
	
	print("Applying UI placement for ", enemy_data.character_name, " - Sprite size: ", sprite_size)
	
	# Apply CollisionShape configuration
	if collision_shape:
		if enemy_data.auto_fit_collision:
			# Auto-fit the collision shape to the sprite's size and scale.
			collision_shape.shape = enemy_data.create_auto_collision_shape(sprite_size)
			collision_shape.scale = enemy_data.get_effective_collision_scale(sprite_size)
		elif enemy_data.custom_collision_shape:
			# Use a manually defined collision shape from the resource.
			collision_shape.shape = enemy_data.custom_collision_shape
			collision_shape.scale = enemy_data.collision_scale
		
		# Set the collision shape's position relative to the sprite.
		collision_shape.position = sprite.position + enemy_data.collision_offset

	# Apply Stats UI placement
	if stats_ui:
		# Get the correct offset based on sprite size.
		var effective_offset = enemy_data.get_effective_stats_offset(sprite_size)
		
		# Get the anchor position relative to the sprite's local coordinates.
		var anchor_pos = enemy_data.get_anchor_position(enemy_data.stats_ui_anchor, sprite_rect)
		
		# The stats UI is a child of the enemy node, so its position is relative to the enemy.
		# This positioning is correct for a UI node placed as a sibling to the Sprite2D.
		stats_ui.position = anchor_pos + effective_offset
		stats_ui.scale = enemy_data.stats_ui_scale
		
		print("Stats UI positioned at: ", stats_ui.position, " (anchor: ", enemy_data.stats_ui_anchor, ")")
	
	# Setup individual UI components within StatsUI
	setup_stats_ui_components()
	
func setup_stats_ui_components():
	"""Position individual components within the StatsUI"""
	if not stats_ui:
		return
	
	# Find health bar component
	var health_bar = stats_ui.get_node_or_null("HealthBar")
	if health_bar:
		health_bar.position = enemy_data.health_bar_local_offset
	
	# Find attack display component
	var attack_display = stats_ui.get_node_or_null("AttackDisplay")
	if attack_display:
		attack_display.position = enemy_data.attack_display_local_offset
	
	# Find block display component
	var block_display = stats_ui.get_node_or_null("BlockDisplay")
	if block_display:
		block_display.position = enemy_data.block_display_local_offset
	
	print("Configured UI components with local offsets")
	
# --- Turn Management (called by BattleManager) ---

func start_turn():
	"""Called by BattleManager when it's this enemy's turn"""
	# is_my_turn = true
	
	# Reduce cooldowns at start of turn
	update_cooldowns()
	
	# AI decision making and execution
	select_intent()
	await execute_current_intent()
	
	# Clean up turn state
	finish_turn()

func finish_turn():
	"""Clean up after turn is complete"""
	# is_my_turn = false
	current_intent = null
	
	# Apply end-of-turn effects (DOT, buffs, etc.)
	apply_end_of_turn_effects()

func select_intent():
	"""Choose what action to take this turn"""
	if not enemy_data or enemy_data.possible_actions.is_empty():
		# Fallback: basic attack
		current_intent = create_basic_attack_action()
		return
	
	var available_actions = get_available_actions()
	
	if available_actions.is_empty():
		# All actions on cooldown, use basic attack
		current_intent = create_basic_attack_action()
		return
	
	# Select action based on AI type
	match enemy_data.ai_type:
		"aggressive":
			current_intent = select_aggressive_action(available_actions)
		"defensive":
			current_intent = select_defensive_action(available_actions)
		"random":
			current_intent = available_actions[randi() % available_actions.size()]
		"custom":
			current_intent = select_custom_action(available_actions)
		_:
			current_intent = select_weighted_action(available_actions)
	
	# Show intent to player
	display_intent()
	Global.enemy_intent_selected.emit(self, current_intent)

func get_available_actions() -> Array[EnemyAction]:
	"""Get actions that can be used this turn"""
	var available: Array[EnemyAction] = []
	var health_percent = float(current_health) / float(max_health)
	
	for action in enemy_data.possible_actions:
		# Check cooldown
		if action_cooldowns.get(action, 0) > 0:
			continue
		
		# Check health requirements
		if health_percent < action.min_health_percent:
			continue
		if health_percent > action.max_health_percent:
			continue
		
		available.append(action)
	
	return available

func select_aggressive_action(actions: Array[EnemyAction]) -> EnemyAction:
	"""Prioritize attacks and damage-dealing abilities"""
	var attack_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.ATTACK)
	if not attack_actions.is_empty():
		return attack_actions[randi() % attack_actions.size()]
	
	var special_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.SPECIAL_ABILITY)
	if not special_actions.is_empty():
		return special_actions[randi() % special_actions.size()]
	
	return actions[randi() % actions.size()]

func select_defensive_action(actions: Array[EnemyAction]) -> EnemyAction:
	"""Prioritize defense and healing when health is low"""
	var health_percent = float(current_health) / float(max_health)
	
	if health_percent < 0.5:
		var heal_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.HEAL)
		if not heal_actions.is_empty():
			return heal_actions[randi() % heal_actions.size()]
	
	var defend_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.DEFEND)
	if not defend_actions.is_empty():
		return defend_actions[randi() % defend_actions.size()]
	
	return actions[randi() % actions.size()]

func select_weighted_action(actions: Array[EnemyAction]) -> EnemyAction:
	"""Select action based on configured weights"""
	if enemy_data.action_weights.is_empty():
		return actions[randi() % actions.size()]
	
	# Simple weighted selection
	var total_weight = 0
	for i in range(min(actions.size(), enemy_data.action_weights.size())):
		total_weight += enemy_data.action_weights[i]
	
	var rand_value = randi() % total_weight
	var current_weight = 0
	
	for i in range(min(actions.size(), enemy_data.action_weights.size())):
		current_weight += enemy_data.action_weights[i]
		if rand_value < current_weight:
			return actions[i]
	
	return actions[0]

func select_custom_action(actions: Array[EnemyAction]) -> EnemyAction:
	"""Override this in enemy-specific scripts for custom AI"""
	return actions[randi() % actions.size()]

# --- Action Execution ---

func execute_current_intent():
	"""Execute the selected action"""
	if not current_intent:
		push_error("No intent selected for enemy turn!")
		return
	
	print(enemy_data.character_name + " uses " + current_intent.action_name)
	
	# Add visual delay for better game feel
	await get_tree().create_timer(0.5).timeout
	
	match current_intent.action_type:
		EnemyAction.ActionType.ATTACK:
			await execute_attack_action()
		EnemyAction.ActionType.DEFEND:
			await execute_defend_action()
		EnemyAction.ActionType.HEAL:
			await execute_heal_action()
		EnemyAction.ActionType.SPECIAL_ABILITY:
			await execute_special_action()
		EnemyAction.ActionType.BUFF_SELF:
			await execute_buff_action()
		EnemyAction.ActionType.DEBUFF_PLAYER:
			await execute_debuff_action()
	
	# Set cooldown
	if current_intent.cooldown_turns > 0:
		action_cooldowns[current_intent] = current_intent.cooldown_turns
	
	Global.enemy_action_executed.emit(self, current_intent)

func execute_attack_action():
	"""Deal damage to player"""
	var player = get_tree().get_first_node_in_group("player_character")
	if player and current_intent.damage_amount > 0:
		player.take_basic_attack_damage(current_intent.damage_amount)
		# Add animation delay
		await get_tree().create_timer(0.3).timeout

func execute_defend_action():
	"""Gain block"""
	if current_intent.block_amount > 0:
		modify_block(current_intent.block_amount)
		await get_tree().create_timer(0.2).timeout

func execute_heal_action():
	"""Restore health"""
	if current_intent.heal_amount > 0:
		heal(current_intent.heal_amount)
		await get_tree().create_timer(0.3).timeout

func execute_special_action():
	"""Execute custom special ability"""
	if current_intent.custom_effect_script:
		var effect_instance = current_intent.custom_effect_script.new()
		if effect_instance.has_method("execute_effect"):
			effect_instance.execute_effect(self, current_intent)
	await get_tree().create_timer(0.4).timeout

func execute_buff_action():
	"""Apply temporary buff to self"""
	# TODO: Implement buff system
	print("Buff action not yet implemented")
	await get_tree().create_timer(0.2).timeout

func execute_debuff_action():
	"""Apply debuff to player"""
	# TODO: Implement debuff system
	print("Debuff action not yet implemented")
	await get_tree().create_timer(0.2).timeout

# --- Helper Functions ---

func create_basic_attack_action() -> EnemyAction:
	"""Fallback basic attack when no actions are available"""
	var action = EnemyAction.new()
	action.action_name = "Basic Attack"
	action.action_type = EnemyAction.ActionType.ATTACK
	action.damage_amount = enemy_data.base_attack if enemy_data else 5
	return action

func display_intent():
	"""Show the player what this enemy plans to do"""
	if intent_display and current_intent:
		# TODO: Update intent display UI
		# For now, just print to console
		print(enemy_data.enemy_name + " intends to: " + current_intent.get_intent_description())

func update_cooldowns():
	"""Update action cooldowns at start of turn"""
	for action in action_cooldowns:
		if action_cooldowns[action] > 0:
			action_cooldowns[action] -= 1
	
	turns_since_last_special += 1

func apply_end_of_turn_effects():
	"""Handle end-of-turn effects like DOT, buffs, etc."""
	# TODO: Implement status effect system
	pass

# --- Utility Functions ---

func is_alive() -> bool:
	"""Check if enemy is still alive"""
	return current_health > 0

func get_reward_symbols() -> Array[SymbolData]:
	"""Get symbols to reward player on defeat"""
	if not enemy_data or enemy_data.symbol_rewards.is_empty():
		return []
	
	var rewards: Array[SymbolData] = []
	var available_rewards = enemy_data.symbol_rewards.duplicate()
	
	for i in range(min(enemy_data.reward_count, available_rewards.size())):
		var reward_index = randi() % available_rewards.size()
		rewards.append(available_rewards[reward_index])
		available_rewards.remove_at(reward_index)
	
	return rewards
