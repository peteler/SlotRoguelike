# Enemy.gd - Main enemy class
class_name Enemy
extends Character

## Enemy configuration and AI state
@export var enemy_data: EnemyData
var current_intent: EnemyAction
var action_cooldowns: Dictionary = {}  # Track cooldowns for each action
var turns_since_last_special: int = 0


##TODO: Intent display (UI element)
# @onready var intent_display: Control = $IntentDisplay

func _ready():
	print("entered player's ready")
	super._ready()  # Call Character._ready()
	
	if enemy_data:
		initialize_from_enemy_data(enemy_data)
	else:
		push_error("Enemy has no EnemyData assigned!")

func initialize_from_enemy_data(data: EnemyData):
	"""Initialize enemy specific features from EnemyData resource"""
	# init base character data, stats, ui, etc.
	initialize_character_stats(data)
	initialize_character_ui(data)
	
	# Initialize specific enemy data
	for action in enemy_data.possible_actions:
		action_cooldowns[action] = 0

# --- Turn Management (called by BattleManager) ---

func start_turn():
	"""Called by BattleManager when it's this enemy's turn"""
	print("entered start_turn for, ", self)
	
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
	
	#TODO: Apply end-of-turn effects (DOT, buffs, etc.)

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
	
	#TODO: Show intent to player

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


func update_cooldowns():
	"""Update action cooldowns at start of turn"""
	for action in action_cooldowns:
		if action_cooldowns[action] > 0:
			action_cooldowns[action] -= 1
	
	turns_since_last_special += 1


# --- Utility Functions ---

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
