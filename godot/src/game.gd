extends Node2D

const ROOM = preload("res://src/props/room.tscn")

@onready var cam = $Camera2D
@onready var player = $Player
@onready var music_player = $MusicPlayer
@onready var mirror_viewport = $MirrorViewport
@onready var relative_remote_transform_2d = $Player/RelativeRemoteTransform2D

@export var enemy_value := 5.0
@export var enemy_kills := 5.0

@export var value_increase := 1.5
@export var kill_increase := 1.8

var previous_dir := Vector2.ZERO
var room_dirs := [Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]

var _logger = Logger.new("Game")

func _ready():
	GameManager.game_start()
	_setup_first_room.call_deferred()
	music_player.play("RESET")
	GameManager.mirrored.connect(func(mirror): music_player.play("mirror" if mirror else "normal"))
	
func _setup_first_room():
	var room = _create_room()
	add_child(room)
	room.start(enemy_value, enemy_kills)

func _setup_next_room(current_room: Room):
	var room = _create_room()
	enemy_value *= value_increase
	enemy_kills *= kill_increase
	var dir = room_dirs.filter(func(d): return d != previous_dir).pick_random()
	_logger.debug("Creating room in dir %s" % dir)
	current_room.rooms[dir] = room
	current_room.open_door(dir)
	
	room.global_position = current_room.global_position + dir * room.get_size()
	add_child.call_deferred(room)

func _create_room() -> Room:
	var room = ROOM.instantiate()
	var mat = room.material as ShaderMaterial
	mat.set_shader_parameter("reflection_viewport", mirror_viewport.get_viewport().get_texture())
	
	room.finished.connect(func():
		_setup_next_room(room)
		GameManager.room_done()
	)
	room.entered.connect(func(dir):
		_logger.debug("Player entered in direction %s" % dir)
		var new_room = room.rooms[dir]
		cam.global_position = new_room.global_position
		relative_remote_transform_2d.center = cam.global_position
		
		player.velocity = Vector2.ZERO
		player.global_position = new_room.get_door(-dir).global_position + dir * 10
		player.immediate_return_trident()
		
		previous_dir = -dir
		new_room.start(enemy_value, enemy_kills, dir)
		GameManager.room_start()
		get_tree().create_timer(1.0).timeout.connect(func(): room.queue_free())
	)
	return room

func _on_player_died():
	GameManager.gameover()

func _on_player_reflected():
	_logger.debug("Player reflected in mirror")
	GameManager.reflected()
