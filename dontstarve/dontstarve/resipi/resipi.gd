extends Resource
class_name resipi
enum r_type {
	tool,
	meterial,
	weopon,
	obsticles,
	
}
enum where_type {
	none,
	craft_table,
	blue_print_maker
}
@export var item_need : Array[resipi_resorce]
@export var end_tem : Item
@export var type : r_type
@export var where : where_type
@export var end_obsticle : obsticle
