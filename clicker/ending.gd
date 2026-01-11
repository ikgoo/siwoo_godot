extends Node2D

# ========================================
# 다이아 → Auto Money 교환 시스템
# ========================================

# === Export 설정 ===
@export var diamond_cost: int = 1000  # 필요한 다이아 개수
@export var auto_money_reward: int = 100  # 받을 auto_money 개수

# Area2D 노드 참조
@onready var area_2d = $Area2D if has_node("Area2D") else null

# 플레이어가 영역 안에 있는지 추적
var is_player_inside: bool = false


func _ready():
	# Area2D 시그널 연결
	if area_2d:
		area_2d.body_entered.connect(_on_area_2d_body_entered)
		area_2d.body_exited.connect(_on_area_2d_body_exited)
	
	print("교환소 준비 완료! 다이아 💎", diamond_cost, " → Auto Money 🪙", auto_money_reward)


func _process(_delta):
	# 플레이어가 영역 안에 있고 F키를 누르면 교환
	if is_player_inside and Input.is_action_just_pressed("f"):
		exchange_diamond_to_auto_money()


# 다이아를 auto_money로 교환
func exchange_diamond_to_auto_money():
	# 다이아가 충분한지 확인
	if Globals.money >= diamond_cost:
		# 다이아 차감
		Globals.money -= diamond_cost
		
		# auto_money 추가
		Globals.auto_money += auto_money_reward
		
		print("✨ 교환 완료! 다이아 💎", diamond_cost, " → Auto Money 🪙", auto_money_reward)
		print("   현재 보유: 다이아 💎", Globals.money, ", Auto Money 🪙", Globals.auto_money)
		
		# 액션 텍스트 업데이트
		Globals.show_action_text(get_exchange_info_text())
	else:
		var needed = diamond_cost - Globals.money
		print("💎 부족! 필요: 💎", diamond_cost, ", 보유: 💎", Globals.money, " (부족: 💎", needed, ")")


# 교환소 정보 텍스트 생성
func get_exchange_info_text() -> String:
	var can_afford = Globals.money >= diamond_cost
	
	if can_afford:
		return "교환소 [F]\n다이아 💎%d → Auto Money 🪙%d\n보유 다이아: 💎%d" % [diamond_cost, auto_money_reward, Globals.money]
	else:
		var needed = diamond_cost - Globals.money
		return "교환소 [F]\n다이아 💎%d → Auto Money 🪙%d\n보유 다이아: 💎%d (💎%d 부족)" % [diamond_cost, auto_money_reward, Globals.money, needed]


# 플레이어가 영역에 들어왔을 때
func _on_area_2d_body_entered(body):
	if body is CharacterBody2D:
		is_player_inside = true
		print("플레이어가 교환소 영역에 들어왔습니다!")
		
		# 액션 텍스트로 교환 정보 표시
		Globals.show_action_text(get_exchange_info_text())


# 플레이어가 영역에서 나갔을 때
func _on_area_2d_body_exited(body):
	if body is CharacterBody2D:
		is_player_inside = false
		print("플레이어가 교환소 영역에서 나갔습니다!")
		
		# 액션 텍스트 숨김
		Globals.hide_action_text()

