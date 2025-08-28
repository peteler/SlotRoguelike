class_name BattleNPC
extends Character

var npc_template: BattleNPCTemplate
@onready var battle_ui: NPCBattleUI = $NPCBattleUI
@onready var intent_component: IntentComponent = $IntentComponent
@onready var level_component: LevelComponent = $LevelComponent

func _ready():
	super._ready()

func initialize_from_npc_template(template: BattleNPCTemplate):
	"""Initialize enemy specific features from EnemyData resource"""
	# get reference to template
	npc_template = template
	
	# init base character stats & nodes
	init_character_basic_battle_stats(template)
	init_character_sprite_and_collision(template)
	
	# init components from template
	battle_ui.initialize(template, sprite)
	intent_component.initialize(template)
	level_component.initialize(template)
	
	print("Enemy initialized: ", template.character_name)

# --- Turn Management (called by BattleManager) ---

#TODO: switch to signal for turns? probably not ..
func play_turn():
	"""Called by BattleManager when it's this npc's turn"""
	
	# Reduce cooldowns at start of turn
	intent_component.update_cooldowns()
	
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

	#TODO: update buff timers [if buffs last 3 turns this is where you update them]
	
	#TODO: Apply end-of-turn effects (DOT, buffs, etc.)

## called by battle_manager when player's turn start [entering PLAYER_ROLL state]
## PROBABLY BETTER TO HAVE INTENT LISTEN FOR SIGNALS, THEN NO NEED TO DO THIS FOR SUMMONS !!!
func on_enter_player_roll():
	intent_component.select_intent()

# --- Helper Functions ---

func get_possible_actions() -> Array[Action]:
	return npc_template.possible_actions

func get_possible_action_weights() -> Array[int]:
	return npc_template.action_weights
