extends NinePatchRect

@onready var tile_map_layer = $TileMapLayer
@onready var mob = $mob
func _ready():
	Gamemaneger.m_tile = mob
func _process(delta):

	var ch_pos = Gamemaneger.tilemap.to_local(Gamemaneger.character.global_position)
	var ch_t_pos: Vector2i = Gamemaneger.tilemap.local_to_map(ch_pos)
	for i in range(0,70):
		for j in range(0,70):
			var id = Gamemaneger.tilemap.get_cell_source_id(Vector2(ch_t_pos.x-35+i,ch_t_pos.y-35+j))
			if id >= 0:
				tile_map_layer.set_cell(Vector2i(i,j), 1, Vector2i(0, 0))
			else:
				tile_map_layer.erase_cell(Vector2i(i,j))
 
