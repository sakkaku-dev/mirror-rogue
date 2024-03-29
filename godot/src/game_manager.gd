extends Node2D

signal mirrored(mirror)

const SHARD_EMITTER = preload("res://src/props/shard_emitter.tscn")
const GAMEOVER = preload("res://src/game_over.tscn")

@onready var canvas_modulate = $CanvasModulate
@onready var canvas_layer = $CanvasLayer
@onready var mirror_effect = $CanvasLayer/MirrorEffect
@onready var enemy_death_sound = $EnemyDeathSound
@onready var enemy_hit_sound = $EnemyHitSound
@onready var glass_break = $GlassBreak
@onready var glass_crack = $GlassCrack
@onready var mirror_sound = $MirrorSound

const NORMAL_COLOR = Color("ccf8ff")
const MIRROR_COLOR = Color("ff9c9c")

var mirror := false
var mirror_tw = TweenCreator.new(self)
var death_tex: Texture2D

var kills := 0
var mirror_kills := 0
var bubbles := 0
var playtime := 0.0
var mirror_time := 0.0

var game_started = false
var room_finished = true

func _ready():
	reset()
	
func _play_shatter(restore = false):
	get_tree().paused = true
	PhysicsServer2D.set_active(true)
	
	var window_scale = get_viewport_rect().size / Vector2(get_window().size)
	var tex_scale = max(window_scale.x, window_scale.y)
	
	var img = get_viewport().get_texture().get_image()
	death_tex = ImageTexture.create_from_image(img)
	var death_screen = Sprite2D.new()
	death_screen.process_mode = PROCESS_MODE_ALWAYS
	death_screen.texture = death_tex
	death_screen.z_index = 10
	death_screen.scale = Vector2(tex_scale, tex_scale)
	death_screen.position = (img.get_size() / 2) * tex_scale
	death_screen.show()
	
	var shard = SHARD_EMITTER.instantiate()
	canvas_layer.add_child(death_screen)
	death_screen.add_child(shard)
	glass_crack.play()
	get_tree().create_timer(1.0).timeout.connect(func():
		shard.shatter()
		glass_break.play()
		get_tree().create_timer(1.0).timeout.connect(func(): get_tree().paused = false)
		get_tree().create_timer(1.0).timeout.connect(func(): canvas_layer.remove_child(death_screen))
	)

func game_start():
	game_started = true
	room_finished = false

func room_start():
	room_finished = false

func room_done():
	room_finished = true

func gameover():
	game_started = false
	_play_shatter()
	get_tree().change_scene_to_packed(GAMEOVER)

func reset():
	mirror = false
	canvas_modulate.color = _get_mirror_color()
	_set_mirror_effect(1.0)
	kills = 0
	mirror_kills = 0
	bubbles = 0
	playtime = 0
	mirror_time = 0

func _process(delta):
	if game_started:
		playtime += delta
		
		if not room_finished and mirror:
			mirror_time += delta

func reflected():
	if mirror_tw.new_tween(func(): get_tree().paused = false, false):
		get_tree().paused = true
		
		mirror_tw.method(_set_mirror_effect, 1.0, -1.5, 1.).set_ease(Tween.EASE_IN)
		mirror_sound.play()
		
		mirror = not mirror
		mirror_effect.material.set_shader_parameter("in_out", 1 if mirror else 0)
		mirror_tw.fn(func(): mirrored.emit(mirror))
		mirror_tw.prop(canvas_modulate, "color", canvas_modulate.color, _get_mirror_color(), 0.1)
		
		mirror_tw.method(_set_mirror_effect, -1.0, 1.5, 1.).set_ease(Tween.EASE_OUT)

func _get_mirror_color():
	return MIRROR_COLOR if mirror else NORMAL_COLOR

func _set_mirror_effect(value: float):
	mirror_effect.material.set_shader_parameter("position", value)

func killed_enemy():
	if mirror:
		mirror_kills += 1
	else:
		kills += 1
	
	enemy_death_sound.play()

func bubble_popped():
	bubbles += 1

func hit():
	enemy_hit_sound.play()
