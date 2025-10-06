extends Resource


class_name Inven_Item


@export var name_i : String = ""

@export var texture : Texture2D

@export var value : int = 0  # 공격력 또는 허기 회복량

enum i_type {
	ATTACK,
	EAT,
	NOTING
}



@export var type : i_type
