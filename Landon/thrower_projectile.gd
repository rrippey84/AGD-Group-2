extends Area2D

var speed = 200.0
var direction = 1
var spin_speed = 360.0

func _ready():
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position.x += speed * direction * delta
	$Sprite2D.rotation_degrees += spin_speed * delta
	if abs(position.x) > 1200:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
	queue_free()
