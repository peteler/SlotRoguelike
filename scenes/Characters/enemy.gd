# Enemy.gd - Main enemy class
class_name Enemy
extends Character

## Enemy configuration and AI state
@export var enemy_data: EnemyTemplate
var action_cooldowns: Dictionary = {}  # Track cooldowns for each action
var turns_since_last_special: int = 0

@onready var battle_ui: EnemyBattleUI = $EnemyBattleUI
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
	
	if enemy_data:
		initialize_from_enemy_template(enemy_data)
	else:
		push_error("Enemy has no EnemyData assigned!")

func initialize_from_enemy_template(template: EnemyTemplate):
	"""Initialize enemy specific features from EnemyData resource"""
	
	init_battle_ui(template)
	
	#TODO: BattleNPC class inheritence! Initialize specific enemy data
	for action in enemy_data.possible_actions:
		action_cooldowns[action] = 0
	
	#TODO: LEVELCOMPONENT!
	# setup curr values that'll change throughout the encounter due to buffs and such
	curr_attack_level = template.attack_level
	curr_block_level = template.block_level
	curr_heal_level = template.heal_level
	curr_buff_level = template.buff_level

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
	current_intent = null ## make sure display is gone too
	if battle_ui and battle_ui.intent_display:
		battle_ui.intent_display.visible = false
	# TODO: update buff timers [if buffs last 3 turns this is where you update them]
	
	#TODO: Apply end-of-turn effects (DOT, buffs, etc.)

## called by battle_manager when player's turn start [entering PLAYER_ROLL state]
## PROBABLY BETTER TO LISTEN FOR SIGNALS !!!
func call_on_start_of_player_turn():
	intent_component.select_intent()

# --- EnemyBattleUI functions ---
##TODO: move these into battlenpc class
func init_battle_ui(template: EnemyTemplate):
	if not battle_ui:
		push_error("battle_ui not available when needed for enemy: ", self)
		
	# init base character data, stats, ui, etc.
	init_character_battle_stats(template) # only sets up health,max health for now
	init_character_battle_ui(template, battle_ui)
	
	# init enemy specific UI
	init_intent_ui(template)

func init_intent_ui(template: EnemyTemplate):
	"""
	Applies UI placement configuration from EnemyData.
	Called once from init_battle_ui.
	"""
	if not template or not sprite or not battle_ui.intent_display:
		push_error("Missing EnemyData, Sprite2D, or IntentDisplay for UI placement!")
		return
	
	# Get the sprite's bounding box in its local coordinate system.
	var sprite_rect = sprite.get_rect()
	
	# Get the anchor position relative to the sprite's local coordinates.
	var anchor_pos = template.get_anchor_position(template.intent_ui_anchor, sprite_rect)
	
	# Position the intent display relative to the main character node
	battle_ui.intent_display.position = anchor_pos + template.intent_ui_offset
	
	print("Intent UI positioned at: ", battle_ui.intent_display.position, " (anchor: ", template.intent_ui_anchor, ")")

# --- Helper Functions ---

func update_cooldowns():
	"""Update action cooldowns at start of turn"""
	for action in action_cooldowns:
		if action_cooldowns[action] > 0:
			action_cooldowns[action] -= 1
	
	turns_since_last_special += 1
