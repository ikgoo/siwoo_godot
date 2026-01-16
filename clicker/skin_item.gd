extends Item
class_name SkinItem

## /** 스킨 아이템 클래스
##  * auto_scene의 Sprite2D 또는 Sprite2D2 텍스처를 변경하는 스킨
##  */

## 스킨 타입: 1 = Sprite2D(캐릭터), 2 = Sprite2D2(배경/도구)
@export_enum("Sprite1:1", "Sprite2:2") var target_sprite: int = 1
@export var texture: Texture2D = null           # 적용할 텍스처
@export var region_rect: Rect2 = Rect2()        # region_rect (비어있으면 기본값 사용)
@export var flip_h: bool = false                # 수평 반전 (좌우 뒤집기)
@export var flip_v: bool = false                # 수직 반전 (상하 뒤집기)

func _init(p_id: String = "", p_name: String = "", p_price: int = 0, p_description: String = "",
		   p_target_sprite: int = 1, p_texture: Texture2D = null, p_region_rect: Rect2 = Rect2(),
		   p_flip_h: bool = false, p_flip_v: bool = false):
	super._init(p_id, p_name, p_price, p_description)
	target_sprite = p_target_sprite
	texture = p_texture
	region_rect = p_region_rect
	flip_h = p_flip_h
	flip_v = p_flip_v

## /** 씬에 스킨을 적용한다
##  * @param scene_node Node 스킨을 적용할 씬 노드
##  * @returns void
##  */
func apply_to_scene(scene_node: Node) -> void:
	var sprite_name = "Sprite2D" if target_sprite == 1 else "Sprite2D2"
	var sprite: Sprite2D = scene_node.get_node_or_null(sprite_name)
	
	if sprite and texture:
		sprite.texture = texture
		if region_rect.size != Vector2.ZERO:
			sprite.region_enabled = true
			sprite.region_rect = region_rect
		# 반전 적용
		sprite.flip_h = flip_h
		sprite.flip_v = flip_v
		print("스킨 적용: ", sprite_name, " <- ", id, " (flip_h: ", flip_h, ", flip_v: ", flip_v, ")")
