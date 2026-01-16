extends Resource
class_name WeaponData

## 무기의 스탯과 특성을 정의하는 데이터 리소스
## 각 무기는 이 리소스를 상속받아 고유한 값을 설정함

# 무기 기본 정보
@export var weapon_name: String = "무기"
@export_enum("주무기", "보조무기", "근접무기") var weapon_type: int = 0

# 데미지 관련
@export var damage: float = 30.0
@export var headshot_multiplier: float = 2.0

# 탄약 관련
@export var magazine_size: int = 30
@export var reserve_ammo: int = 120
@export var infinite_ammo: bool = false  # 근접 무기용

# 발사 관련
@export var fire_rate: float = 0.1  # 발사 간격 (초)
@export_enum("자동", "반자동", "단발", "점사", "근접") var fire_mode: int = 0
@export var burst_count: int = 3  # 점사 모드일 때 발사 수
@export var burst_delay: float = 0.05  # 점사 간 딜레이

# 정확도 관련
@export var base_spread: float = 0.5  # 기본 탄퍼짐
@export var aim_spread: float = 0.1  # 조준 시 탄퍼짐
@export var moving_spread_multiplier: float = 2.0  # 이동 중 탄퍼짐 배율
@export var jumping_spread_multiplier: float = 3.0  # 점프 중 탄퍼짐 배율

# 반동 관련
@export var recoil_amount: float = 0.5  # 카메라 반동 크기
@export var recoil_recovery: float = 5.0  # 반동 회복 속도

# 재장전 관련
@export var reload_time: float = 2.0  # 재장전 시간 (초)

# 샷건용 (여러 발 동시 발사)
@export var pellets_per_shot: int = 1  # 한 번에 발사되는 탄환 수
@export var pellet_spread: float = 5.0  # 샷건 탄환 퍼짐 각도

# 근접 무기용
@export var attack_range: float = 2.0  # 공격 범위
@export var attack_speed: float = 0.5  # 공격 속도 (초당)

# 시각/사운드 효과
@export var use_muzzle_flash: bool = true
@export var use_shell_eject: bool = true

