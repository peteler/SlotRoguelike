# Enemy.gd - Main enemy class
class_name Enemy
extends BattleNPC

## Enemy configuration and AI state
var enemy_template: EnemyTemplate

func _ready():
	super._ready()
	
	if enemy_template:
		initialize_from_enemy_template(enemy_template)
	else:
		push_error("Enemy has no EnemyData assigned!")

func initialize_from_enemy_template(template: EnemyTemplate):
	"""Initialize enemy specific features from EnemyData resource"""
	# for now everything is in parent's template
	initialize_from_npc_template(template)
