extends passive_entity
class_name friendly_entity

## 우호적 생물 클래스
## 플레이어를 도와주며, 선물을 주고받을 수 있습니다

## 우호적 특성
@export var gift_items : Array[Item] = [] ## 줄 수 있는 선물 아이템 목록
@export var gift_cooldown : float = 60.0 ## 선물 쿨타임 (초)
@export var follow_player : bool = false ## 플레이어 따라다니기 여부
@export var help_in_combat : bool = false ## 전투 지원 여부
@export var trade_enabled : bool = true ## 거래 가능 여부

## 플레이어가 인식 범위에 들어왔을 때 호출되는 함수
## 우호적인 생물은 플레이어에게 반갑게 반응하고 거래나 선물을 제공합니다
## player: 들어온 플레이어 노드
## entity_node: 이 entity를 가진 씬 노드 (StaticBody3D)
func on_player_enter(player, entity_node):
	print("우호적 생물이 반갑게 맞이합니다!")
	# TODO: 플레이어에게 다가가거나 반응 표시
	# TODO: trade_enabled가 true면 거래 UI 활성화
	# TODO: 선물 쿨타임 체크 후 gift_items에서 아이템 드롭
	# TODO: follow_player가 true면 플레이어 따라다니기 시작


