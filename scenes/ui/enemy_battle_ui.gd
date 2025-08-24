# PlayerCharacterBattleUI.gd
class_name EnemyBattleUI
extends CharacterBattleUI

## parent vars
# @onready var block_label: Label = $BlockDisplay/BlockLabel
# @onready var health_label: Label = $HealthBar/HealthLabel

@onready var attack_label: Label = $AttackDisplay/AttackLabel

var enemy: Enemy

func _ready():
	super._ready()
	
	# player_character specific signals: 
	Global.enemy_intent_updated.connect(_on_enemy_intent_updated)
	
	## is this needed?
	#player_character = get_parent() as PlayerCharacter
	#if player_character:
		#_on_player_character_attack_updated(player_character, player_character.current_attack)

func _on_enemy_intent_updated(updated_character: Enemy, intent: EnemyAction):
	# Only update if this is our character
	if updated_character == enemy:
		# TODO: UPDATE INTENT DISPLAY ACCORDINGLY
		pass
