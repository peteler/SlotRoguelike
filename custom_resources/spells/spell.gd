# Spell.gd

# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
class_name Spell
extends Resource

@export var name: String = "Spell"
@export var mana_cost: int = 1
@export var texture: Texture2D
@export var effect_scene: PackedScene

# Execute spell on target
func execute(target: Node):
	# Create visual effect
	if effect_scene:
		var effect = effect_scene.instantiate()
		target.get_parent().add_child(effect)
		effect.global_position = target.global_position
	
	# Apply spell logic
	match name:
		"Fireball":
			target.take_damage(8)
		"Freeze":
			target.apply_status("frozen", 2)

		# Add more spells here
	
	print("Cast ", name, " on ", target.name)

# Check if target is valid
func is_valid_target(target: Node) -> bool:
	match name:
		"Heal":
			return false
		_:
			return target.is_in_group("enemies")


# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
# BASICALLY NOT USABLE ... JUST A DUMB SCRIPT
