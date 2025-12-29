extends Node

var mouse_pos = Vector3.ZERO


## 텍스처 알파 데이터 캐시 (텍스처 경로 -> Image 데이터)
## 픽셀 단위 감지를 위해 게임 시작 시 모든 Obsticle 텍스처를 미리 로드
var texture_alpha_cache: Dictionary = {}

## 마우스에 걸린 obsticle (픽셀퍼펙트 성공한 obsticle)d
## 마우스가 obsticle 위에 있으면 해당 obsticle, 없으면 null
var mouse_on_obsticle = null

# 시간대 enum 정의
enum time_of_day {
	day,        # 낮
	afternoon,  # 오후
	night,      # 밤
	midnight    # 자정
}

# 현재 시간대 (midnight에서 시작하여 첫 주기가 완전하도록 함)
var now_time : time_of_day = time_of_day.midnight
var now_date : int = 0

## 하루 길이 설정 (초 단위)
## 이 값을 변경하면 낮/밤 주기와 시침 회전 속도가 모두 변경됩니다
const DAY_DURATION: float = 30.0  # 기본값: 30초
enum moon_phase {
	nothing,
	small,
	middle,
	high,
	middle_end,
	small_end,
}
var now_moon : moon_phase = moon_phase.nothing

## 지형 타입 enum 정의
enum global_tiles {
	GRASS,   # 초원
	DIRT,    # 흙
	SAND,    # 모래
	STONE,   # 돌
	SNOW,    # 눈
	NOTHING, # 아무것도 없음
	SEA,     # 바다
	SHORE    # 해변
}

var ob_re_need
var ob_re_resipis : resipi
var is_near_making_note = false
## 현재 making_note에 투입된 재료 정보
var ob_re_contributed : Dictionary = {}
## 현재 making_note 인스턴스 참조
var current_making_note = null

## 활성화된 모든 making_note들을 추적하는 배열
var active_making_notes : Array = []

## Area에 들어간 making_note들을 추적하는 배열 (플레이어 근처)
var nearby_making_notes : Array = []

## making_note를 활성 리스트에 등록하는 함수
func register_making_note(note: Node3D):
	if note and not active_making_notes.has(note):
		active_making_notes.append(note)
		print("making_note 등록됨: ", note.thing.name if note.thing else "없음")

## making_note를 활성 리스트에서 제거하는 함수
func unregister_making_note(note: Node3D):
	if note and active_making_notes.has(note):
		active_making_notes.erase(note)
		print("making_note 제거됨: ", note.thing.name if note.thing else "없음")

## making_note를 근처 리스트에 추가하는 함수 (Area 진입)
func add_nearby_making_note(note: Node3D):
	if note and not nearby_making_notes.has(note):
		nearby_making_notes.append(note)
		print("making_note 근처 추가: ", note.thing.name if note.thing else "없음")

## making_note를 근처 리스트에서 제거하는 함수 (Area 이탈)
func remove_nearby_making_note(note: Node3D):
	if note and nearby_making_notes.has(note):
		nearby_making_notes.erase(note)
		print("making_note 근처 제거: ", note.thing.name if note.thing else "없음")
