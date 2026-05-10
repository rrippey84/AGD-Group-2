extends Area2D

var speed = 150.0
var direction = 1
var spin_speed = 720.0
var active = false

func _ready():
	connect("body_entered", _on_body_entered)
	monitoring = false
	# Small delay before collision activates so it clears the thrower
	await get_tree().create_timer(0.15).timeout
	monitoring = true
	active = true

func _physics_process(delta):
	position.x += speed * direction * delta
	$Sprite2D.rotation_degrees += spin_speed * delta
	if abs(global_position.x) > 5000:
		queue_free()

func _on_body_entered(body):
	if not active:
		return
	if body.is_in_group("player"):
		body.take_damage()
	queue_free()
