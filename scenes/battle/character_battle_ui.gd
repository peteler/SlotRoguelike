# CharacterBattleUI.gd
class_name CharacterBattleUI
extends Control

@onready var block_label: Label = $BlockDisplay/BlockLabel
@onready var health_label: Label = $HealthBar/HealthLabel

var character: Character

func _ready():
	
	character = get_parent() as Character
	
	Global.character_block_updated.connect(_on_character_block_updated)
	Global.character_health_updated.connect(_on_character_health_updated)

# In character_battle_ui.gd

func initialize(character_template: CharacterTemplate, parent_sprite: Sprite2D):
	# This logic is MOVED FROM Character.gd's init_character_battle_ui
	var sprite_rect = parent_sprite.get_rect()
	var anchor_pos = character_template.get_anchor_position(character_template.battle_ui_anchor, sprite_rect)
	
	# The UI positions itself
	self.position = anchor_pos + character_template.battle_ui_offset
	self.scale = character_template.battle_ui_scale
	
	# The UI positions its own children
	var health_bar = get_node_or_null("HealthBar")
	if health_bar:
		health_bar.position = character_template.health_bar_local_offset

	var block_display = get_node_or_null("BlockDisplay")
	if block_display:
		block_display.position = character_template.block_display_local_offset

func _on_character_block_updated(updated_character: Character, block: int):
	# Only update if this is our character
	print("Signal received for block update. Character: ", updated_character.name, ", block: ", block)
	if updated_character == character:
		block_label.text = str(block)
		block_label.visible = block > 0
		print("block_label: ", block_label)

func _on_character_health_updated(updated_character: Character, health: int, max_health: int):
	print("Signal received for health update. Character: ", updated_character.name, ", health: ", health)
	if updated_character == character:
		health_label.text = str(health) + "/" + str(max_health)

# TODO: buff/debuff diplay
