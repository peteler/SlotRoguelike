# SymbolData.gd
@tool
class_name SymbolData
extends Resource

enum APPLY_TIME {
	FIRST,
	BY_ORDER,
	LAST
}
enum RARITY {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}
enum EDITION {
	NORMAL
	# like foil, polychrome, etc.. some additional random modifier
}
enum SPECIAL_EFFECT {
	
}

@export var symbol_name: String = "Basic Symbol"
@export var description: String = ""
@export var texture: Texture2D
@export var rarity: RARITY = RARITY.COMMON

@export_group("Effects Array")
@export var effect_array: Array[Effect]

@export_group("Gameplay flags")
@export var edition: EDITION = EDITION.NORMAL
@export var apply_time: APPLY_TIME = APPLY_TIME.BY_ORDER

@export_group("Visual and audio")
@export var visual_effect_scene: PackedScene
@export var sound_effect: AudioStream
@export var animation_duration: float = 0.3
