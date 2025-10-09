extends Node3D
@onready var sprite_3d = $Sprite3D
var resipis : resipi
var thing : obsticle

## 노드가 씬 트리에 추가될 때 호출
func _ready():
	if thing:
		sprite_3d.texture = thing.img
		sprite_3d.offset.y = thing.offset


## 매 프레임 호출 (현재 사용 안 함)
func _process(_delta):
	pass


## Area3D에 플레이어가 들어왔을 때 호출
## area: 들어온 Area3D (플레이어의 Area3D)
func _on_area_3d_area_entered(area):
	# 플레이어의 Area3D인지 확인
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		# 현재 making_note의 정보를 Globals에 저장
		Globals.ob_re_need = thing
		Globals.ob_re_resipis = resipis
		Globals.is_near_making_note = true
		print("making_note 근처 진입: ", thing.name if thing else "없음")


## Area3D에서 플레이어가 나갔을 때 호출
## area: 나간 Area3D (플레이어의 Area3D)
func _on_area_3d_area_exited(area):
	# 플레이어의 Area3D인지 확인
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		# Globals 정보 초기화
		Globals.ob_re_need = null
		Globals.ob_re_resipis = null
		Globals.is_near_making_note = false
		print("making_note 근처 이탈")
