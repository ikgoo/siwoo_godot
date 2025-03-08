extends Resource


class_name Inv

signal update

@export var slots : Array[InvSlot]


func insert(item:Inven_Item):
	# 빈 슬롯 찾기
	var emptyslots = slots.filter(func(slot): return slot.item == null)
	# 빈 슬롯이 있다면 아이템 추가
	if !emptyslots.is_empty():
		emptyslots[0].item = item
		emptyslots[0].amout = 1  # 수량은 항상 1
	update.emit()
