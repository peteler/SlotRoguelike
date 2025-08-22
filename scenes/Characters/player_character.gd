# PlayerCharacter.gd - Player character class
class_name PlayerCharacter
extends Character

## Player-specific stats
var mana: int = 0:
	set(value):
		mana = max(0, value)
		Global.player_mana_updated.emit(mana)

## Player character data resource
@export var player_data: PlayerData

## battle manager helper fields [should eventually be changed into a function if mechanic will be updated]
var can_attack: bool = false

func _ready():
	super._ready()  # Call Character._ready()
	
	# Add player to group for easy finding
	add_to_group("player_character")
	
	# Initialize from player data if available
	if player_data:
		initialize_from_player_data(player_data)
	else:
		push_error("Player has no PlayerData assigned!")

func initialize_from_player_data(data: PlayerData):
	"""Initialize player character from PlayerData resource"""
	if not data:
		push_error("PlayerCharacter requires valid PlayerData to initialize!")
		return
	
	self.player_data = data
	
	# Initialize base character stats
	initialize_character_stats(data)
	print("called initialize_character_stats on: ", self)
	
	initialize_character_ui(player_data.class_data)
	print("called initialize_character_ui on: ", self)
	
	# Set player-specific stats
	mana = data.current_mana
	
	# Apply any temporary modifiers
	max_health = data.get_total_health()
	current_health = data.current_health
	attack = data.get_total_attack()
	block = data.get_total_block()
	
	print("Player character initialized: ", data.character_name)

## Player-specific functions

func modify_mana(amount: int):
	"""Modify mana by amount"""
	mana += amount

func can_cast_spell(spell_cost: int) -> bool:
	"""Check if player has enough mana for a spell"""
	return mana >= spell_cost

func cast_spell(spell_cost: int) -> bool:
	"""Attempt to cast a spell, returns true if successful"""
	if can_cast_spell(spell_cost):
		mana -= spell_cost
		return true
	return false

func calc_and_return_basic_attack_damage() -> int:
	return attack

## Override take_basic_attack_damage to add player-specific effects
func take_basic_attack_damage(amount: int):
	super.take_basic_attack_damage(amount)
	
	# Add screen shake, damage effects, etc. here
	add_damage_effect()

func add_damage_effect():
	"""Add visual/audio effects when player takes damage"""
	# TODO: Add screen shake, damage popup, sound effect
	print("Player took damage!")

## Player death is handled by the Global.character_died signal in BattleManager
