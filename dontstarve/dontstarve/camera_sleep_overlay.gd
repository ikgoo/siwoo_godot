extends Camera3D

## 카메라에 수면 졸림 효과 오버레이를 자동으로 적용하는 스크립트
## 
## 사용법:
## 1. Camera3D 노드에 이 스크립트 연결
## 2. 자식으로 CanvasLayer 생성
## 3. CanvasLayer 자식으로 ColorRect 생성
##    - Anchor Preset: Full Rect
##    - Color: 투명 (Alpha = 0)
##    - Material → New ShaderMaterial → Shader: shder/sleep.gdshader
## 4. 아래 변수 경로 확인 후 게임 실행

@export var overlay_path: NodePath = "CanvasLayer/ColorRect"  ## 오버레이 ColorRect 경로

var overlay_material: ShaderMaterial = null

func _ready():
	# 오버레이 머티리얼 가져오기
	var overlay_node = get_node_or_null(overlay_path)
	if overlay_node and overlay_node is ColorRect:
		overlay_material = overlay_node.material
		if not overlay_material:
			push_warning("카메라 수면 오버레이: ColorRect에 ShaderMaterial이 설정되지 않았습니다.")
	else:
		push_warning("카메라 수면 오버레이: 경로 '%s'에서 ColorRect를 찾을 수 없습니다." % overlay_path)

func _process(_delta):
	if not overlay_material:
		return
	
	# 플레이어 찾기 (player 그룹에 속한 노드)
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# 플레이어에 셰이더 업데이트 함수가 있는지 확인
	if player.has_method("update_sleep_overlay_external"):
		player.update_sleep_overlay_external(overlay_material)


