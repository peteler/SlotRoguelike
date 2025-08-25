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

@export_group("Basic Stat Effect Arrays [MUST BE SAME SIZE]")
# example: player heals 2 hp
# stat_name[i] = current_health
# stat_change_amount[i] = 2
# target_type[i] = SymbolData.TARGET_TYPE.PLAYER_CHARACTER
@export var basic_effect_stat_name: Array[String] = []
@export var basic_effect_stat_change_amount: Array[int] = []
@export var basic_effect_target_type: Array[GlobalBattle.TARGET_TYPE] = []

@export_group("Special Effects [String, TARGET_TYPE]")
# String = effect name [Apply Weak, Apply Strength , etc.]
@export var special_effects: Dictionary[SPECIAL_EFFECT, GlobalBattle.TARGET_TYPE] = {}

@export_group("Custom Effects [GDScript, TARGET_TYPE]")
@export var custom_effects: Dictionary[GDScript, GlobalBattle.TARGET_TYPE] = {}

@export_group("Gameplay flags")
@export var edition: EDITION = EDITION.NORMAL
@export var apply_time: APPLY_TIME = APPLY_TIME.BY_ORDER

@export_group("Visual and audio")
@export var visual_effect_scene: PackedScene
@export var sound_effect: AudioStream
@export var animation_duration: float = 0.3
