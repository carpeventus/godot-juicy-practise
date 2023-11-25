extends StaticBody2D

signal energy_brick_destroyed()
signal destroyed(which)

@export var long_full: CompressedTexture2D = preload("res://scenes/brick/visuals/BlockLongFull.png")
@export var long_border: CompressedTexture2D = preload("res://scenes/brick/visuals/BlockLongBorder.png")
@export var small_full: CompressedTexture2D = preload("res://scenes/brick/visuals/BlockSmallFull.png")
@export var small_border: CompressedTexture2D = preload("res://scenes/brick/visuals/BlockSmallBorder.png")

@export var one: CompressedTexture2D = preload("res://scenes/brick/visuals/One.png")
@export var two: CompressedTexture2D = preload("res://scenes/brick/visuals/Two.png")
@export var three: CompressedTexture2D = preload("res://scenes/brick/visuals/Three.png")
@export var bomb: CompressedTexture2D = preload("res://scenes/brick/visuals/Bomb.png")
@export var energy: CompressedTexture2D = preload("res://scenes/brick/visuals/Energy.png")

@export var explode_particles: PackedScene = preload("res://scenes/brick/brick_explode_particles.tscn")
@export var bomb_explode_particles: PackedScene = preload("res://scenes/brick/bomb_explode_particles.tscn")



enum TYPE {
	ONE,
	TWO,
	THREE,
	EXPLOSIVE,
	ENERGY
}

enum SIZE {
	SMALL,
	LONG
}

@export var type: TYPE = TYPE.ONE
@export var size: SIZE = SIZE.SMALL

var health_dict = {
	TYPE.ONE: 1,       # 0.35
	TYPE.TWO: 2,       # 0.3
	TYPE.THREE: 3,	   # 0.20
	TYPE.EXPLOSIVE: 1, # 0.05
	TYPE.ENERGY: 1,    # 0.1
}

@onready var health: int = health_dict[type]
@onready var explosion_area: Area2D = $ExplosionArea
@onready var size_sprite: Sprite2D = $Size
@onready var type_sprite: Sprite2D = $Type
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _destroyed: bool = false
var bounce_tween: Tween;

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)
	
	choose_type_random()
	choose_size_random()
	
	health = health_dict[type]
	
	update_size_visuals()
	update_type_visuals()

func _on_animation_finished(name: String) -> void:
	if name == "appear":
		if type == TYPE.EXPLOSIVE or type == TYPE.ENERGY:
			animation_player.play("wiggle")

func choose_type_random() -> void:
	var rand = randf()
	# 10% chance for explosives
	if rand < 0.05:
		type = TYPE.EXPLOSIVE
	elif rand >= 0.05 && rand < 0.15:
		type = TYPE.ENERGY
	elif rand >= 0.15 && rand < 0.35:
		type = TYPE.THREE
	elif rand >= 0.35 && rand < 0.65:
		type = TYPE.TWO
	else:
		type = TYPE.ONE
		
#	type = randi()%TYPE.size()
	
func choose_size_random() -> void:
	var rand = randf()
	if rand < 0.65:
		size = SIZE.LONG
	else:
		size = SIZE.SMALL

func update_size_visuals() -> void:
	match size:
		SIZE.SMALL:
			$CollisionShapeSmall.disabled = false
			$CollisionShapeLong.disabled = true
			if type == TYPE.EXPLOSIVE or type == TYPE.ENERGY:
				size_sprite.texture = small_border
			else:
				size_sprite.texture = small_full
		SIZE.LONG:
			$CollisionShapeSmall.disabled = true
			$CollisionShapeLong.disabled = false
			if type == TYPE.EXPLOSIVE or type == TYPE.ENERGY:
				size_sprite.texture = long_border
			else:
				size_sprite.texture = long_full

func update_type_visuals() -> void:
	match type:
		TYPE.ONE:
			type_sprite.texture = one
		TYPE.TWO:
			type_sprite.texture = two
		TYPE.THREE:
			type_sprite.texture = three
		TYPE.EXPLOSIVE:
			type_sprite.texture = bomb
		TYPE.ENERGY:
			type_sprite.texture = energy

func damage(value: int) -> void:
	health -= value
	
	if health <= 0:
		_destroyed = true
		match type:
			TYPE.EXPLOSIVE:
				explode()
			TYPE.ENERGY:
				give_energy()
		destroy()
	bounce()
	update_type_health()

func spawn_expolode_partices() -> void:
	var particles = explode_particles.instantiate() as Node2D
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	
func bounce() -> void:
	if bounce_tween and bounce_tween.is_running():
		bounce_tween.kill()
	bounce_tween = create_tween()
	bounce_tween.tween_property(size_sprite, "scale", Vector2(1.15, 1.15), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	bounce_tween.parallel().tween_property(size_sprite, "rotation", deg_to_rad(randf_range(-10.0, 10.0)), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		
	bounce_tween.tween_property(size_sprite, "scale", Vector2.ONE, 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	bounce_tween.parallel().tween_property(size_sprite, "rotation", 0.0, 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	

func update_type_health() -> void:
	match health:
		3:
			type = TYPE.THREE
		2:
			type = TYPE.TWO
		1:
			type = TYPE.ONE
	update_type_visuals()
		
func give_energy() -> void:
	emit_signal("energy_brick_destroyed")


func spawn_bomb_expolode_particles() -> void:
	var particles = bomb_explode_particles.instantiate() as Node2D
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position

func explode() -> void:
	spawn_bomb_expolode_particles()
	var bodies = explosion_area.get_overlapping_bodies()
	for body in bodies:
		if body._destroyed: continue
		# Damage with a high enough value to make sure
		# they're destroyed but also trigger any eventual
		# explosive bricks
		body.damage(10)

func destroy() -> void:
	spawn_expolode_partices()
	emit_signal("destroyed", self)
	queue_free()
