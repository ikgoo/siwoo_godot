extends Resource
class_name AlbaData

## ========================================
## 알바 데이터 리소스
## ========================================
## 알바의 모든 정보를 담는 리소스 클래스
## .tres 파일로 저장하여 여러 알바를 쉽게 만들 수 있습니다

## 알바 이름 (UI 표시용)
@export var alba_name: String = "알바"

## 처음 구매 가격
@export var initial_price: int = 600

## 처음 샀을 때 초당 돈
@export var initial_income: int = 25

## 업그레이드 비용 배열 (Lv1, Lv2, Lv3...)
@export var upgrade_costs: Array[int] = [1000, 2000, 4000]

## 업그레이드 후 초당 수입 배열 (Lv1, Lv2, Lv3...)
@export var upgrade_incomes: Array[int] = [50, 100, 150]

## 알바 이미지 (스프라이트 텍스처)
@export var alba_texture: Texture2D

## 펫 크기 배율
@export var pet_scale: Vector2 = Vector2(1.0, 1.0)

## 펫 오프셋 (캐릭터 기준 뒤쪽 위치)
@export var pet_offset: Vector2 = Vector2(-40, -10)

## 파티클 색상 (구매 가능 표시용)
@export var particle_color: Color = Color(0.3, 0.8, 1.0, 0.6)

## ========================================
## 헬퍼 함수들
## ========================================

## 특정 레벨의 업그레이드 비용을 반환합니다
## @param level: 업그레이드 레벨 (0부터 시작)
## @returns: 업그레이드 비용 (-1이면 MAX 레벨)
func get_upgrade_cost(level: int) -> int:
	if level < upgrade_costs.size():
		return upgrade_costs[level]
	return -1  # MAX 레벨

## 특정 레벨의 업그레이드 후 수입을 반환합니다
## @param level: 업그레이드 레벨 (0부터 시작)
## @returns: 업그레이드 후 초당 수입
func get_upgrade_income(level: int) -> int:
	if level < upgrade_incomes.size():
		return upgrade_incomes[level]
	return initial_income  # MAX 레벨이면 현재 수입 유지

## MAX 레벨인지 확인합니다
## @param current_level: 현재 레벨
## @returns: MAX 레벨이면 true
func is_max_level(current_level: int) -> bool:
	return current_level >= upgrade_costs.size()
