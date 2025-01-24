extends Node3D
@onready var gpu_trail_3d = $GPUTrail3D
@onready var gpu_trail_3d_2 = $GPUTrail3D2
@onready var gpu_trail_3d_3 = $GPUTrail3D3
@onready var gpu_trail_3d_4 = $GPUTrail3D4
@onready var gpu_trail_3d_5 = $GPUTrail3D5
@onready var gpu_trail_3d_6 = $GPUTrail3D6
@onready var gpu_trail_3d_7 = $GPUTrail3D7
@onready var gpu_trail_3d_8 = $GPUTrail3D8
@onready var gpu_trail_3d_9 = $GPUTrail3D9
@onready var gpu_trail_3d_10 = $GPUTrail3D10
@onready var gpu_trail_3d_11 = $GPUTrail3D11
@onready var gpu_trail_3d_12 = $GPUTrail3D12


func _process(float) -> void:
	get_child(0).position.z += 10
	get_child(0).position.z -= 10

func all_visible(tf):
	gpu_trail_3d.visible = tf
	gpu_trail_3d_2.visible = tf
	gpu_trail_3d_3.visible = tf
	gpu_trail_3d_4.visible = tf
	gpu_trail_3d_5.visible = tf
	gpu_trail_3d_6.visible = tf
	gpu_trail_3d_7.visible = tf
	gpu_trail_3d_8.visible = tf
	gpu_trail_3d_9.visible = tf
	gpu_trail_3d_10.visible = tf
	gpu_trail_3d_11.visible = tf
	gpu_trail_3d_12.visible = tf
	
