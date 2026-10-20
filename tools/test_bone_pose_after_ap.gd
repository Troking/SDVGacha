extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/chibi_heroine_model.tscn")
	var instance = scene.instantiate()
	var ap = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var sk = instance.find_child("Skeleton3D", true, false) as Skeleton3D

	ap.play("Idle")
	ap.advance(0.1)

	var head_idx = sk.find_bone("head")
	var anim_rot = sk.get_bone_pose_rotation(head_idx)
	print("Head anim rot:", anim_rot)

	# Add 10 degrees yaw + 5 degrees pitch
	var offset = Quaternion.from_euler(Vector3(deg_to_rad(-5.0), deg_to_rad(10.0), deg_to_rad(-2.0)))
	sk.set_bone_pose_rotation(head_idx, anim_rot * offset)
	var final_rot = sk.get_bone_pose_rotation(head_idx)
	print("Head final rot after procedural blend:", final_rot)

	quit()
