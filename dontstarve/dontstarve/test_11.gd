extends Node3D

@onready var raycast = $RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# RayCast가 충돌했는지 확인
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		if collider:
			# 충돌한 노드 정보 출력
			print("=== RayCast 충돌 ===")
			print("노드 이름: %s" % collider.name)
			print("노드 타입: %s" % collider.get_class())
			
			# CollisionObject3D인 경우 레이어 정보 출력
			if collider is CollisionObject3D:
				var collision_layer = collider.collision_layer
				
				# 활성화된 레이어 번호 추출
				var active_layers = []
				for layer_idx in range(32):
					var layer_bit = 1 << layer_idx
					if (collision_layer & layer_bit) != 0:
						active_layers.append(layer_idx + 1)
				
				print("Collision Layer (비트): %d" % collision_layer)
				print("활성화된 레이어: %s" % active_layers)
			else:
				print("CollisionObject3D가 아님 - 레이어 정보 없음")
			
			print("충돌 위치: %s" % raycast.get_collision_point())
			print("====================")
