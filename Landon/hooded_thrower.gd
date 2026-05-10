extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var move_speed = 50.0
var detect_range = 500.0
var throw_range = 250.0
var throw_cooldown = 0.0
var throw_cooldown_time = 2.0
var facing = 1
var hp = 5
var blink_timer = 0.0
var blink_duration = 0.15
var is_blinking = false
var active := false 
var is_dead: bool = false

const PROJECTILE_SCENE = preload("res://thrower_projectile.tscn")
const GRAVITY = 900.0

enum State { IDLE, WALK, THROW_WINDUP, THROW_ACTIVE, THROW_RECOVER }
var state = State.IDLE
var state_timer = 0.0

const WINDUP_TIME = 0.3
const ACTIVE_TIME = 0.1
const RECOVER_TIME = 0.3

func _ready():
	anim.play("idle")

func _process(delta):
	if is_blinking:
		blink_timer += delta
		if blink_timer >= blink_duration:
			is_blinking = false
			blink_timer = 0.0
			anim.modulate = Color(1, 1, 1, 1)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		move_and_slide()
		return

	if throw_cooldown > 0:
		throw_cooldown -= delta

	var distance = global_position.distance_to(player.global_position)
	var is_throwing = state in [State.THROW_WINDUP, State.THROW_ACTIVE, State.THROW_RECOVER]

	if not is_throwing:
		if player.global_position.x > global_position.x:
			facing = 1
		else:
			facing = -1
		anim.flip_h = facing == 1

	state_timer += delta

	match state:
		State.IDLE:
			velocity.x = 0
			if distance <= throw_range and throw_cooldown <= 0:
				_enter_state(State.THROW_WINDUP)
			elif distance <= detect_range:
				_enter_state(State.WALK)

		State.WALK:
			if distance <= throw_range and throw_cooldown <= 0:
				_enter_state(State.THROW_WINDUP)
			elif distance <= detect_range:
				var direction = sign(player.global_position.x - global_position.x)
				velocity.x = direction * move_speed
				anim.play("walk")
			else:
				_enter_state(State.IDLE)

		State.THROW_WINDUP:
			velocity.x = 0
			if state_timer >= WINDUP_TIME:
				_enter_state(State.THROW_ACTIVE)

		State.THROW_ACTIVE:
			velocity.x = 0
			if state_timer >= ACTIVE_TIME:
				_spawn_projectile()
				_enter_state(State.THROW_RECOVER)

		State.THROW_RECOVER:
			velocity.x = 0
			if state_timer >= RECOVER_TIME:
				throw_cooldown = throw_cooldown_time
				if distance <= detect_range:
					_enter_state(State.WALK)
				else:
					_enter_state(State.IDLE)

	move_and_slide()
	if not active or player == null:
		return
	chase_player(delta)
	
func _enter_state(new_state):
	state = new_state
	state_timer = 0.0
	match new_state:
		State.IDLE:
			anim.play("idle")
		State.WALK:
			anim.play("walk")
		State.THROW_WINDUP:
			anim.play("throw")
		State.THROW_ACTIVE:
			pass
		State.THROW_RECOVER:
			pass

func _spawn_projectile():
	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = facing

func take_hit(damage):
	hp -= damage
	blink()
	if hp <= 0:
		queue_free()

func die() -> void:
	is_dead = true
	set_physics_process(false)
	$AnimatedSprite2D.play("death")  # make sure you have a "death" animation
	await $AnimatedSprite2D.animation_finished
	queue_free()

func blink():
	is_blinking = true
	blink_timer = 0.0
	anim.modulate = Color(1, 0.3, 0.3, 1)

# TODO: Add mob health and damage system when player weapon is implemented
func set_active(value: bool) -> void:
	active = value
	
func chase_player(_delta: float) -> void:
	# Update target position
	navigation_agent.target_position = player.global_position

	# Move toward next path point
	var next_point = navigation_agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
