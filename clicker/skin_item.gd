extends Item
class_name SkinItem

## /** 스킨 아이템 클래스
##  * auto_scene 배경에 적용할 수 있는 스킨 아이템
##  */

@export var bg_color: Color = Color.BLACK
@export var texture: Texture2D = null
@export var has_particles: bool = false
@export var particle_config: Dictionary = {}

func _init(p_id: String = "", p_name: String = "", p_price: int = 0, p_description: String = "",
		   p_bg_color: Color = Color.BLACK, p_texture: Texture2D = null, 
		   p_has_particles: bool = false, p_particle_config: Dictionary = {}):
	super._init(p_id, p_name, p_price, p_description)
	bg_color = p_bg_color
	texture = p_texture
	has_particles = p_has_particles
	particle_config = p_particle_config

## /** 씬에 스킨을 적용한다
##  * @param scene_node Node 스킨을 적용할 씬 노드
##  * @returns void
##  */
func apply_to_scene(scene_node: Node) -> void:
	# 배경 ColorRect 찾거나 생성
	var bg_rect: ColorRect = scene_node.get_node_or_null("BackgroundRect")
	
	if not bg_rect:
		bg_rect = ColorRect.new()
		bg_rect.name = "BackgroundRect"
		bg_rect.z_index = -100
		bg_rect.anchor_right = 1.0
		bg_rect.anchor_bottom = 1.0
		scene_node.add_child(bg_rect)
		scene_node.move_child(bg_rect, 0)
	
	# 배경색 적용
	bg_rect.color = bg_color
	
	# 텍스처가 있으면 TextureRect 적용
	if texture != null:
		var tex_rect = scene_node.get_node_or_null("BackgroundTexture")
		if not tex_rect:
			tex_rect = TextureRect.new()
			tex_rect.name = "BackgroundTexture"
			tex_rect.z_index = -99
			tex_rect.anchor_right = 1.0
			tex_rect.anchor_bottom = 1.0
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			scene_node.add_child(tex_rect)
			scene_node.move_child(tex_rect, 1)
		
		tex_rect.texture = texture
		tex_rect.visible = true
	else:
		var tex_rect = scene_node.get_node_or_null("BackgroundTexture")
		if tex_rect:
			tex_rect.visible = false
	
	# 파티클 효과 적용
	if has_particles:
		var particles = scene_node.get_node_or_null("BackgroundParticles")
		if not particles:
			particles = GPUParticles2D.new()
			particles.name = "BackgroundParticles"
			particles.z_index = -98
			scene_node.add_child(particles)
			
			# 기본 파티클 설정
			particles.amount = particle_config.get("amount", 50)
			particles.lifetime = particle_config.get("lifetime", 3.0)
			particles.preprocess = particle_config.get("preprocess", 2.0)
			particles.emitting = true
			
			# ProcessMaterial 생성
			var material = ParticleProcessMaterial.new()
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			material.emission_box_extents = Vector3(300, 200, 0)
			material.direction = Vector3(0, -1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, particle_config.get("gravity", 98.0), 0)
			material.initial_velocity_min = particle_config.get("velocity_min", 20.0)
			material.initial_velocity_max = particle_config.get("velocity_max", 50.0)
			material.scale_min = particle_config.get("scale_min", 0.5)
			material.scale_max = particle_config.get("scale_max", 1.5)
			
			particles.process_material = material
		
		particles.visible = true
		particles.emitting = true
	else:
		var particles = scene_node.get_node_or_null("BackgroundParticles")
		if particles:
			particles.visible = false
			particles.emitting = false
