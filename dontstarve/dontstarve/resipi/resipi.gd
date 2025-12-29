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

@export_group("제작 요구사항")
## 제작에 필요한 제작대 tier (0 = 제작대 불필요, 1+ = 해당 tier 제작대 필요)
@export var required_tier : int = 0
