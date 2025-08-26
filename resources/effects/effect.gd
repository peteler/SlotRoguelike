# effect.gd
@tool
class_name Effect
extends Resource

enum EFFECT_TYPE {
	BASIC,
	SPECIAL,
	CUSTOM
}


@export var effect_name: String = "effect_name"
@export var description: String = ""
@export var texture: Texture2D
@export var type: EFFECT_TYPE = EFFECT_TYPE.BASIC

@export_group("Gameplay variables")
@export var target_type: GlobalBattle.TARGET_TYPE

@export_group("BASIC EFFECT VARIABLES")
@export var stat_name: String = ""
@export var stat_change_amount: int = 0

@export_group("SPECIAL EFFECT VARIABLES")

@export_group("CUSTOM EFFECT VARIABLES")
@export var custom_script: GDScript

@export_group("Visual and audio")
@export var visual_effect_scene: PackedScene
@export var sound_effect: AudioStream
@export var animation_duration: float = 0.3


func apply():
	
	var targets = GlobalBattle.get_targets_by_target_type(target_type, null)
	
	match type:
		EFFECT_TYPE.BASIC:
			for target in targets:
				target.modify_property_by_amount(stat_name, stat_change_amount)
			
		_:
			push_error("Effect type not supported for: ", self.name)
			pass
