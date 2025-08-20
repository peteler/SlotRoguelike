# EventData.gd - abstract resource for map events: shop, battle, special event, etc.
@tool
class_name EventData
extends Resource

enum EVENT_TYPE {
	ENCOUNTER     # standard battle encounter
}

@export var event_type: EVENT_TYPE

@export_group("Presentation")
@export var background_texture: Texture2D
@export var background_music: AudioStream
@export var ambient_sound: AudioStream
