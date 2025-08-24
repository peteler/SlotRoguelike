# Enemy.gd - Main enemy class
class_name Enemy
extends Character

## Enemy configuration and AI state
@export var enemy_data: EnemyData
var current_intent: EnemyAction
var action_cooldowns: Dictionary = {}  # Track cooldowns for each action
var turns_since_last_special: int = 0

@onready var battle_ui: EnemyBattleUI = $EnemyBattleUI

## These change during combat, EnemyActions use these, NOT WHAT'S ON DISPLAY!!!
var attack_val: int
var block_val: int


func _ready():
	print("entered player's ready")
	super._ready()  # Call Character._ready()
	
	if enemy_data:
		initialize_from_enemy_data(enemy_data)
	else:
		push_error("Enemy has no EnemyData assigned!")

func initialize_from_enemy_data(data: EnemyData):
	"""Initialize enemy specific features from EnemyData resource"""
	
	init_battle_ui(data)
	
	## Initialize specific enemy data
	for action in enemy_data.possible_actions:
		action_cooldowns[action] = 0
	# for now init attack, block like this since it's an enemy specific system
	attack_val = data.base_attack
	block_val = data.base_block

# --- Turn Management (called by BattleManager) ---

func start_turn():
	"""Called by BattleManager when it's this enemy's turn"""
	print("entered start_turn for, ", self)
	
	# Reduce cooldowns at start of turn
	update_cooldowns()
	
	# AI execution
	
	await execute_current_intent()
	
	# Clean up turn state
	finish_turn()

func finish_turn():
	"""Clean up after turn is complete"""
	current_intent = null ## make sure display is gone too
	if battle_ui and battle_ui.intent_display:
		battle_ui.intent_display.visible = false
	# TODO: update buff timers [if buffs last 3 turns this is where you update them]
	
	#TODO: Apply end-of-turn effects (DOT, buffs, etc.)

## called by battle_manager when player's turn start [entering PLAYER_ROLL state]
func call_on_start_of_player_turn():
	select_intent()

# --- intent system ---
func select_intent():
	"""Choose what action to take in upcoming turn"""
	if not enemy_data or enemy_data.possible_actions.is_empty():
		push_error("no enemy_data/ enemy_data.possible_actions")
		return
	
	var available_actions = get_available_actions()
	
	# Select action based on AI type
	match enemy_data.ai_type:
		## TODO: rework enemy AI:
		#"aggressive":
			#current_intent = select_aggressive_action(available_actions)
		#"defensive":
			#current_intent = select_defensive_action(available_actions)
		#"random":
			#current_intent = available_actions[randi() % available_actions.size()]
		#"custom":
			#current_intent = select_custom_action(available_actions)
		_:
			current_intent = select_weighted_action(available_actions)
	
	#TODO: Show intent to player ---- probably best by adding another ui child element? that's inside enemy_data

	Global.enemy_intent_updated.emit(self, current_intent)

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
# ---------------------------------
## TODO: rework enemy AI:
#func select_aggressive_action(actions: Array[EnemyAction]) -> EnemyAction:
	#"""Prioritize attacks and damage-dealing abilities"""
	#var attack_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.ATTACK)
	#if not attack_actions.is_empty():
		#return attack_actions[randi() % attack_actions.size()]
	#
	#var special_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.SPECIAL_ABILITY)
	#if not special_actions.is_empty():
		#return special_actions[randi() % special_actions.size()]
	#
	#return actions[randi() % actions.size()]
#
#func select_defensive_action(actions: Array[EnemyAction]) -> EnemyAction:
	#"""Prioritize defense and healing when health is low"""
	#var health_percent = float(current_health) / float(max_health)
	#
	#if health_percent < 0.5:
		#var heal_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.HEAL)
		#if not heal_actions.is_empty():
			#return heal_actions[randi() % heal_actions.size()]
	#
	#var defend_actions = actions.filter(func(a): return a.action_type == EnemyAction.ActionType.DEFEND)
	#if not defend_actions.is_empty():
		#return defend_actions[randi() % defend_actions.size()]
	#
	#return actions[randi() % actions.size()]

func select_weighted_action(actions: Array[EnemyAction]) -> EnemyAction:
	"""Select action based on configured weights"""
	if actions.is_empty():
		push_error("No available actions for enemy: ", self)
	
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

#func select_custom_action(actions: Array[EnemyAction]) -> EnemyAction:
	#"""Override this in enemy-specific scripts for custom AI"""
	#return actions[randi() % actions.size()]

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
			await execute_basic_attack_action()
		EnemyAction.ActionType.DEFEND:
			await execute_basic_defend_action()
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

func execute_basic_attack_action():
	"""Deal damage to player"""
	var player = get_tree().get_first_node_in_group("player_character")
	if player and attack_val > 0:
		player.take_basic_attack_damage(attack_val)

func execute_basic_defend_action():
	"""Gain block"""
	if block_val > 0:
		current_block = block_val
		await get_tree().create_timer(0.2).timeout

func execute_special_action():
	"""Execute custom special ability"""
	if current_intent.custom_effect_script:
		var effect_instance = current_intent.custom_effect_script.new()
		if effect_instance.has_method("execute_effect"):
			effect_instance.execute_effect(self, current_intent)
	await get_tree().create_timer(0.4).timeout

func execute_heal_action():
	pass

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

# --- EnemyBattleUI functions ---

func init_battle_ui(data: EnemyData):
	if not battle_ui:
		push_error("battle_ui not available when needed for enemy: ", self)
		
	# init base character data, stats, ui, etc.
	init_character_battle_stats(data) # only sets up health,max health for now
	init_character_battle_ui(data, battle_ui)
	
	# init enemy specific UI
	init_intent_ui(data)


func init_intent_ui(data: EnemyData):
	"""
	Applies UI placement configuration from EnemyData.
	Called once from init_battle_ui.
	"""
	if not data or not sprite or not battle_ui.intent_display:
		push_error("Missing EnemyData, Sprite2D, or IntentDisplay for UI placement!")
		return
	
	# Get the sprite's bounding box in its local coordinate system.
	var sprite_rect = sprite.get_rect()
	
	# Get the anchor position relative to the sprite's local coordinates.
	var anchor_pos = data.get_anchor_position(data.intent_ui_anchor, sprite_rect)
	
	# Position the intent display relative to the main character node
	battle_ui.intent_display.position = anchor_pos + data.intent_ui_offset
	battle_ui.intent_display.scale = data.intent_ui_scale
	
	print("Intent UI positioned at: ", battle_ui.intent_display.position, " (anchor: ", data.intent_ui_anchor, ")")

# --- Helper Functions ---

func update_cooldowns():
	"""Update action cooldowns at start of turn"""
	for action in action_cooldowns:
		if action_cooldowns[action] > 0:
			action_cooldowns[action] -= 1
	
	turns_since_last_special += 1
