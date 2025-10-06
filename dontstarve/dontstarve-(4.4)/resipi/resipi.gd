extends Resource
class_name resipi
enum r_type {
	tool,
	meterial,
	weopon,
	
}
@export var item_need : Array[resipi_resorce]
@export var end_tem : Item
@export var type : r_type
