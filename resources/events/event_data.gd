# EventData.gd - Enhanced for map generation
@tool
class_name EventData
extends Resource

enum EVENT_TYPE {
	ENCOUNTER,     # standard battle encounter
	SHOP,          # shop event (to be implemented)
	SPECIAL,       # special event (to be implemented)
	REST,          # rest site (to be implemented)
	TREASURE,      # treasure room (to be implemented)
	BOSS           # boss encounter
}

@export var event_type: EVENT_TYPE

# Map generation properties
@export var min_row: int = 0           # Earliest row this can appear
@export var max_row: int = 999         # Latest row this can appear  
@export var difficulty: int = 1        # Difficulty level
@export var is_final_event: bool = false  # Is this the final event of a map?

@export_group("Presentation")
@export var icon: Texture2D            # Map icon
@export var background_texture: Texture2D
@export var background_music: AudioStream
@export var ambient_sound: AudioStream
