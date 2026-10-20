extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/chibi_heroine_model.tscn")
	var instance = scene.instantiate()
	print("--- INSTANTIATED CHIBI HEROINE MODEL ---")
	_inspect_node(instance, 0)
	quit()

func _inspect_node(node: Node, indent: int) -> void:
	var prefix = "  ".repeat(indent)
	var type_str = node.get_class()
	var extra = ""
	if node is MeshInstance3D and node.mesh:
		var bs_count = node.mesh.get_blend_shape_count()
		extra = " (MeshInstance3D, blend_shapes: " + str(bs_count) + ")"
		for i in range(bs_count):
			var bs_name = node.mesh.get_blend_shape_name(i)
			print(prefix + "   [BS " + str(i) + "] " + bs_name)
	elif node is Skeleton3D:
		extra = " (Skeleton3D, bones: " + str(node.get_bone_count()) + ")"
		for b in range(node.get_bone_count()):
			var b_name = node.get_bone_name(b)
			var b_parent = node.get_bone_parent(b)
			print(prefix + "   [Bone " + str(b) + "] " + b_name + " (parent: " + str(b_parent) + ")")
	elif node is AnimationPlayer:
		extra = " (AnimationPlayer, anims: " + str(node.get_animation_list().size()) + ")"

	print(prefix + "- " + node.name + " : " + type_str + extra)
	for child in node.get_children():
		_inspect_node(child, indent + 1)
