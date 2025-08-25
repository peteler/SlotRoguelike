#GlobalBattle - global battle helper hub
extends Node

enum TARGET_TYPE {
	SELF,
	PLAYER_CHARACTER, # Applies to the player
	SINGLE_ENEMY,     # Applies to one enemy
	ALL_ENEMIES,      # Applies to all enemies
	RANDOM_ENEMY,     # Applies to a random enemy
	ALL_CHARACTERS,   # Applies to everyone
	NONE              # No target (global effects)
}

func _ready():
	# Set up the singleton to persist between scenes
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_targets_by_target_type(target_type: TARGET_TYPE, caller: Character) -> Array:
	"""Determine targets for a symbol based on its target type"""
	match target_type:
		TARGET_TYPE.SELF:
			return [caller] if caller else []
		
		TARGET_TYPE.PLAYER_CHARACTER:
			var player = get_tree().get_first_node_in_group("player_character")
			return [player] if player else []
		
		TARGET_TYPE.SINGLE_ENEMY:
			var enemies = get_tree().get_nodes_in_group("enemies")
			var alive_enemies = enemies.filter(func(e): return e.is_alive())
			return [alive_enemies[0]] if not alive_enemies.is_empty() else []
		
		TARGET_TYPE.ALL_ENEMIES:
			var enemies = get_tree().get_nodes_in_group("enemies")
			return enemies.filter(func(e): return e.is_alive())
		
		TARGET_TYPE.RANDOM_ENEMY:
			var enemies = get_tree().get_nodes_in_group("enemies")
			var alive_enemies = enemies.filter(func(e): return e.is_alive())
			if alive_enemies.is_empty():
				return []
			return [alive_enemies[randi() % alive_enemies.size()]]
		
		TARGET_TYPE.ALL_CHARACTERS:
			var all_chars: Array[Character] = []
			var player = get_tree().get_first_node_in_group("player_character")
			if player:
				all_chars.append(player)
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			all_chars.append_array(enemies.filter(func(e): return e.is_alive()))
			return all_chars
		
		TARGET_TYPE.NONE:
		# Global effects that don't target specific characters
			return []
		
		_:
			return []
