# PlayerCharacterBattleUI.gd
class_name PlayerCharacterBattleUI
extends CharacterBattleUI

## parent vars
# @onready var block_label: Label = $BlockDisplay/BlockLabel
# @onready var health_label: Label = $HealthBar/HealthLabel

@onready var attack_display: HBoxContainer = $AttackDisplay
@onready var attack_label: Label = $AttackDisplay/AttackLabel

var player_character: PlayerCharacter

func _ready():
	super._ready()
	
	attack_label = get_node_or_null("AttackDisplay/AttackLabel")
	if not attack_label:
		print("attack label is null")
		push_error("AttackLabel not found in PlayerCharacterBattleUI")
		return
	else:
		print("attack label isn't null")
	
	
	# player_character specific signals: 
	Global.player_character_attack_updated.connect(_on_player_character_attack_updated)
	
	player_character = get_parent() as PlayerCharacter
	if not player_character:
		push_error("PlayerCharacterBattleUI must be a direct child of an Enemy node.")

func _on_player_character_attack_updated(updated_character: PlayerCharacter, attack: int):
	# Only update if this is our character
	if updated_character == player_character:
		attack_label.text = str(attack)
		attack_label.visible = attack > 0
