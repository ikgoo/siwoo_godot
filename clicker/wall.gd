extends StaticBody2D

@export var require_tier : int  # 오타 수정: requier → require
# CollisionShape2D 노드 참조
@onready var collision_shape = $CollisionShape2D
# Sprite2D 노드 참조
@onready var sprite = $Sprite2D
# 벽이 열렸는지 여부
var is_opened : bool = false

func _ready():
	# Globals의 tier_up Signal 구독 (매 프레임 체크 대신)
	Globals.tier_up.connect(_on_tier_up)
	
	# Globals의 money_changed Signal도 구독 (초기 체크용)
	Globals.money_changed.connect(_on_money_changed)
	
	# 초기 티어 체크 (다음 프레임에 실행하여 모든 노드가 준비된 후 체크)
	call_deferred("check_tier")

# 티어가 올라갔을 때 호출되는 콜백
func _on_tier_up(_new_tier: int):
	check_tier()

# 돈이 변경될 때 호출되는 콜백 (초기 체크용)
func _on_money_changed(_new_amount: int, _delta: int):
	check_tier()

# 티어를 체크하여 벽을 열거나 닫음
func check_tier():
	# 이미 열린 벽은 다시 체크하지 않음
	if is_opened:
		return
	
	print("벽 티어 체크: require_tier=", require_tier, ", Globals.max_tier=", Globals.max_tier, ", Globals.current_tier=", Globals.current_tier)
	
	# 현재 최대 티어가 필요한 티어보다 크거나 같으면 벽 열기
	if Globals.max_tier >= require_tier:
		open_wall()

# 벽을 여는 함수
func open_wall():
	is_opened = true
	
	# 페이드 아웃 효과
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	
	# 애니메이션 끝나면 완전히 숨기기
	tween.finished.connect(func():
		visible = false
		# 충돌 비활성화
		if collision_shape:
			collision_shape.disabled = true
	)
	
	print("벽 열림! 티어 ", require_tier, " 필요, 현재 최대 티어: ", Globals.max_tier)
