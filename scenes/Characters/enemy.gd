# Enemy.gd - Main enemy class
class_name Enemy
extends BattleNPC

## Enemy configuration and AI state
@export var enemy_template: EnemyTemplate
var action_cooldowns: Dictionary = {}  # Track cooldowns for each action
var turns_since_last_special: int = 0

@onready var battle_ui: NPCBattleUI = $NPCBattleUI
@onready var intent_component: IntentComponent = $IntentComponent

#TODO: make this and INTENT SYSTEM components that'll be shared by other npcs like summons
# levels determine intent action value
var curr_attack_level: int
var curr_block_level: int
var curr_heal_level: int
var curr_buff_level: int


func _ready():
	print("entered player's ready")
	super._ready()  # Call Character._ready()
	
	if enemy_template:
		initialize_from_enemy_template(enemy_template)
	else:
		push_error("Enemy has no EnemyData assigned!")

func initialize_from_enemy_template(template: EnemyTemplate):
	"""Initialize enemy specific features from EnemyData resource"""
	# init base character stats & nodes
	init_character_basic_battle_stats(template)
	init_character_sprite_and_collision(template)
	
	# init battle_ui based on CharacterTemplate & sprite
	battle_ui.initialize(template, sprite)
	
	# initialize enemy-specific stuff
	#TODO: BattleNPC class inheritence! initialize it there
	for action in enemy_template.possible_actions:
		action_cooldowns[action] = 0
	
	#TODO: LEVELCOMPONENT!
	# setup curr values that'll change throughout the encounter due to buffs and such
	curr_attack_level = template.attack_level
	curr_block_level = template.block_level
	curr_heal_level = template.heal_level
	curr_buff_level = template.buff_level
	
	print("Enemy initialized: ", template.character_name)


# --- Turn Management (called by BattleManager) ---

func play_turn():
	"""Called by BattleManager when it's this enemy's turn"""
	
	# Reduce cooldowns at start of turn
	update_cooldowns()
	
	# AI execution
	
	await intent_component.execute_current_intent()
	
	# Clean up turn state
	finish_turn()

func finish_turn():
	"""Clean up after turn is complete"""
	intent_component.clear_intent()
	##TODO: replace this with a battleui function
	if battle_ui and battle_ui.intent_display:
		battle_ui.intent_display.visible = false
	# TODO: update buff timers [if buffs last 3 turns this is where you update them]
	
	#TODO: Apply end-of-turn effects (DOT, buffs, etc.)

## called by battle_manager when player's turn start [entering PLAYER_ROLL state]
## PROBABLY BETTER TO LISTEN FOR SIGNALS !!!
func call_on_start_of_player_turn():
	intent_component.select_intent()

# --- Helper Functions ---

func update_cooldowns():
	"""Update action cooldowns at start of turn"""
	for action in action_cooldowns:
		if action_cooldowns[action] > 0:
			action_cooldowns[action] -= 1
	
	turns_since_last_special += 1
