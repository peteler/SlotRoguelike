# PlayerCharacterBattleUI.gd
class_name EnemyBattleUI
extends CharacterBattleUI

## parent vars
# @onready var block_label: Label = $BlockDisplay/BlockLabel
# @onready var health_label: Label = $HealthBar/HealthLabel

@onready var intent_display: Control = $IntentDisplay
@onready var intent_icon: TextureRect = $IntentDisplay/IntentIcon
@onready var intent_label: Label = $IntentDisplay/IntentLabel

var enemy: Enemy

func _ready():
	super._ready()
	
	# player_character specific signals: 
	Global.enemy_intent_updated.connect(_on_enemy_intent_updated)
	
	enemy = get_parent() as Enemy
	if not enemy:
		push_error("EnemyBattleUI must be a direct child of an Enemy node.")

func _on_enemy_intent_updated(updated_character: Enemy, intent: EnemyAction):
	# Only update if this is our character
	if updated_character == enemy and intent:
		# Update the icon and text based on the new intent.
		if intent.icon:
			intent_icon.texture = intent.icon
		else:
			# You might want a default "question mark" icon here
			intent_icon.texture = null 

		intent_label.text = intent.get_intent_description()
		
		# Make the whole display visible.
		intent_display.visible = true
	elif updated_character == enemy:
		# Hide if the intent is cleared (after action execution)
		intent_display.visible = false
