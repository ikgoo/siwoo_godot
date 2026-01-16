extends CanvasLayer
class_name HUD

## 게임 HUD (HP, 탄약, 무기 이름, 크로스헤어)

# UI 노드 참조
@onready var hp_bar: ProgressBar = $HPContainer/HPBar
@onready var hp_label: Label = $HPContainer/HPLabel
@onready var ammo_label: Label = $AmmoContainer/AmmoLabel
@onready var weapon_name_label: Label = $AmmoContainer/WeaponNameLabel
@onready var crosshair: Control = $Crosshair
@onready var damage_indicator: ColorRect = $DamageIndicator

# 플레이어 참조
var player: PlayerController
var weapon_manager: WeaponManager

# 데미지 표시 효과
var damage_fade_speed: float = 2.0

func _ready():
	# 데미지 인디케이터 초기화
	if damage_indicator:
		damage_indicator.color.a = 0.0

func _process(delta):
	# 데미지 인디케이터 페이드아웃
	if damage_indicator and damage_indicator.color.a > 0:
		damage_indicator.color.a -= damage_fade_speed * delta

# 플레이어 설정 및 시그널 연결
# p: 플레이어 노드
func setup_player(p: PlayerController):
	player = p
	
	# HP 업데이트
	update_hp(player.current_hp, player.max_hp)
	
	# 플레이어 시그널 연결
	player.player_damaged.connect(_on_player_damaged)
	
	# 무기 매니저 찾기
	weapon_manager = _find_weapon_manager(player)
	if weapon_manager:
		weapon_manager.weapon_switched.connect(_on_weapon_switched)
		# 초기 무기 탄약 표시 (약간의 딜레이 후)
		await get_tree().create_timer(0.1).timeout
		var current_weapon = weapon_manager.get_current_weapon()
		if current_weapon:
			_on_weapon_switched(weapon_manager.current_slot, 
				current_weapon.weapon_data.weapon_name if current_weapon.weapon_data else "무기")

# 무기 매니저 찾기
func _find_weapon_manager(node: Node) -> WeaponManager:
	for child in node.get_children():
		if child is WeaponManager:
			return child
		var result = _find_weapon_manager(child)
		if result:
			return result
	return null

# HP 업데이트
# current: 현재 HP
# max_hp: 최대 HP
func update_hp(current: float, max_hp: float):
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current
		
		# HP에 따른 색상 변경
		var hp_ratio = current / max_hp
		if hp_ratio > 0.6:
			hp_bar.modulate = Color(0.2, 1.0, 0.2)  # 초록색
		elif hp_ratio > 0.3:
			hp_bar.modulate = Color(1.0, 1.0, 0.2)  # 노란색
		else:
			hp_bar.modulate = Color(1.0, 0.2, 0.2)  # 빨간색
	
	if hp_label:
		hp_label.text = "HP: %d" % int(current)

# 탄약 업데이트
# current: 현재 탄창 탄약
# reserve: 예비 탄약
func update_ammo(current: int, reserve: int):
	if ammo_label:
		ammo_label.text = "%d / %d" % [current, reserve]

# 무기 이름 업데이트
# weapon_name: 무기 이름
func update_weapon_name(weapon_name: String):
	if weapon_name_label:
		weapon_name_label.text = weapon_name

# 플레이어 피격 시 호출
func _on_player_damaged(damage: float):
	update_hp(player.current_hp, player.max_hp)
	
	# 데미지 인디케이터 표시
	if damage_indicator:
		damage_indicator.color.a = 0.3

# 무기 교체 시 호출
func _on_weapon_switched(slot_index: int, weapon_name: String):
	update_weapon_name(weapon_name)
	
	# 이전 무기의 시그널 연결 해제
	if weapon_manager:
		for i in range(weapon_manager.weapon_slots.size()):
			var weapon = weapon_manager.weapon_slots[i]
			if weapon and weapon.ammo_changed.is_connected(_on_ammo_changed):
				weapon.ammo_changed.disconnect(_on_ammo_changed)
	
	# 현재 무기의 탄약 정보 가져오기
	if weapon_manager:
		var current_weapon = weapon_manager.get_current_weapon()
		if current_weapon and current_weapon.weapon_data:
			if current_weapon.weapon_data.infinite_ammo:
				update_ammo(0, 0)
				if ammo_label:
					ammo_label.text = "∞"
			else:
				update_ammo(current_weapon.current_ammo, current_weapon.reserve_ammo)
				# 탄약 변경 시그널 연결
				if not current_weapon.ammo_changed.is_connected(_on_ammo_changed):
					current_weapon.ammo_changed.connect(_on_ammo_changed)

# 탄약 변경 시 호출
func _on_ammo_changed(current: int, reserve: int):
	update_ammo(current, reserve)

