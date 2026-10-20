extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/chibi_heroine_model.tscn")
	var instance = scene.instantiate()
	var ap = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var sk = instance.find_child("Skeleton3D", true, false) as Skeleton3D

	print("ap has Idle:", ap.has_animation("Idle"))
	ap.play("Idle")
	# Advance animation by 0.1s
	ap.advance(0.1)

	var head_idx = sk.find_bone("head")
	var orig_rot = sk.get_bone_pose_rotation(head_idx)
	print("orig head rot after advance:", orig_rot)

	# Try adding a rotation offset
	var add_rot = Quaternion(Vector3.UP, deg_to_rad(15.0))
	sk.set_bone_pose_rotation(head_idx, orig_rot * add_rot)
	var new_rot = sk.get_bone_pose_rotation(head_idx)
	print("new head rot:", new_rot)

	# Advance again
	ap.advance(0.1)
	var after_advance_rot = sk.get_bone_pose_rotation(head_idx)
	print("rot after next advance (did AP overwrite?):", after_advance_rot)

	quit()
