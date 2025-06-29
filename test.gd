extends Node2D

# Print all groups and their nodes
# Add this to any node's script
func _ready():
	# Print all groups and their members
	for group in get_tree().get_nodes_in_group(""):
		print("Group:", group)
		for member in get_tree().get_nodes_in_group(group):
			print("\t", member.name, " (", member.get_class(), ")")
