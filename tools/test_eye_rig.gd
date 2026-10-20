extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/chibi_heroine_model.tscn")
	var instance = scene.instantiate()
	var face_eye = instance.find_child("Face_Eye", true, false) as MeshInstance3D
	var brow = instance.find_child("Brow", true, false) as MeshInstance3D
	var eye_star = instance.find_child("EyeStar", true, false) as MeshInstance3D
	var skeleton = instance.find_child("Skeleton3D", true, false) as Skeleton3D

	print("face_eye:", face_eye != null)
	if face_eye:
		for i in range(face_eye.mesh.get_blend_shape_count()):
			var name = face_eye.mesh.get_blend_shape_name(i)
			print("Face_Eye BS:", i, name)

	print("skeleton:", skeleton != null)
	if skeleton:
		var head_idx = skeleton.find_bone("head")
		print("head bone index:", head_idx)

	quit()
