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

func _on_enemy_intent_updated(updated_character: Enemy, intent: EnemyAction, action_val: int, action_targets: Array):
	# Only update if this is our character
	if updated_character == enemy and intent:
		# Update the icon and text based on the new intent.
		if intent.icon:
			intent_icon.texture = intent.icon
			
			# icon scaling:
			intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			intent_icon.stretch_mode = TextureRect.STRETCH_SCALE
			var scale_factor = intent.icon_scale_factor
			var original_size: Vector2 = intent_icon.texture.get_size()  # Requires a texture to be assigned
			var desired_size: Vector2 = original_size * scale_factor
			## Set the custom minimum size to enforce the scaled-down dimensions
			intent_icon.custom_minimum_size = desired_size
			 
			intent_icon.size_flags_horizontal = 0
			intent_icon.size_flags_vertical = 0
			intent_label.size_flags_vertical = 0

		else:
			# You might want a default "question mark" icon here
			intent_icon.texture = null 

		intent_label.text = str(action_val)
		#TODO: add targets display
		#match action_targets:
			#pass
		
		# Make the whole display visible.
		intent_display.visible = true
		
	
	elif updated_character == enemy:
		# Hide if the intent is cleared (e.g: after action execution)
		intent_display.visible = false
