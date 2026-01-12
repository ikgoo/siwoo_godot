extends Resource
class_name Item

## /** 기본 아이템 클래스
##  * 상점에서 판매되는 모든 아이템의 기본 클래스
##  */

@export var id: String = ""
@export var name: String = ""
@export var price: int = 0
@export var description: String = ""

func _init(p_id: String = "", p_name: String = "", p_price: int = 0, p_description: String = ""):
	id = p_id
	name = p_name
	price = p_price
	description = p_description
