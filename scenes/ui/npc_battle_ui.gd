# PlayerCharacterBattleUI.gd
class_name NPCBattleUI
extends CharacterBattleUI

## parent vars
# @onready var block_label: Label = $BlockDisplay/BlockLabel
# @onready var health_label: Label = $HealthBar/HealthLabel

@onready var intent_display: Control = $IntentDisplay
@onready var intent_icon: TextureRect = $IntentDisplay/IntentIcon
@onready var intent_label: Label = $IntentDisplay/IntentLabel

var npc: BattleNPC

func _ready():
	super._ready()
	
	# player_character specific signals: 
	Global.intent_updated.connect(_on_intent_updated)
	
	npc = get_parent() as BattleNPC
	if not npc:
		push_error("NPCBattleUI must be a direct child of an npc node.")

# In enemy_battle_ui.gd

func initialize(character_template: CharacterTemplate, parent_sprite: Sprite2D):
	super.initialize(character_template, parent_sprite) # Call the parent function first!
	
	##TODO: add battleNPC_template for ui placement !!
	# This logic is MOVED FROM Enemy.gd's init_intent_ui
	var npc_template = character_template as BattleNPCTemplate
	if not npc_template: return
	
	var sprite_rect = parent_sprite.get_rect()
	var anchor_pos = npc_template.get_anchor_position(npc_template.intent_ui_anchor, sprite_rect)
	intent_display.position = anchor_pos + npc_template.intent_ui_offset

func _on_intent_updated(updated_npc: BattleNPC, intent: Action, action_val: int, action_targets: Array):
	# Only update if this is our character
	if updated_npc == npc and intent:
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
			# might want a default "question mark" icon here
			intent_icon.texture = null 

		intent_label.text = str(action_val)
		#TODO: add targets display
		#match action_targets:
			#pass
		
		# Make the whole display visible.
		intent_display.visible = true
		
	
	elif updated_npc == npc:
		# Hide if the intent is cleared (e.g: after action execution)
		intent_display.visible = false
