extends CharacterBody2D

@export var speed := 100
@export var accel := 800

@export var projectile_scene: PackedScene

@onready var input: PlayerInput = $Input
@onready var hand: Node2D = $Hand
@onready var shot_point = $Hand/ShotPoint


func _ready():
	input.just_pressed.connect(_on_just_pressed)

func _on_just_pressed(ev: InputEvent):
	if ev.is_action_pressed("throw"):
		var projectile = projectile_scene.instantiate()
		projectile.global_position = shot_point.global_position
		projectile.global_rotation = shot_point.global_rotation
		get_tree().current_scene.add_child(projectile)

func _process(delta):
	hand.global_rotation = Vector2.RIGHT.angle_to(global_position.direction_to(get_global_mouse_position()))

func _physics_process(delta):
	var motion_x = input.get_action_strength("move_right") - input.get_action_strength("move_left")
	var motion_y = input.get_action_strength("move_down") - input.get_action_strength("move_up")
	
	velocity = velocity.move_toward(Vector2(motion_x, motion_y) * speed, accel * delta)
	move_and_slide()
