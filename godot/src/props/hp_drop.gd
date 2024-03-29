extends Area2D

@export var amount := 3

func _ready():
	_visible()
	
	GameManager.mirrored.connect(func(mirror): _visible(mirror))
	body_entered.connect(func(player):
		player.heal(amount)
		queue_free()
	)

func _visible(v: bool = GameManager.mirror):
	visible = v
	$CollisionShape2D.set_deferred("disabled", not v)
