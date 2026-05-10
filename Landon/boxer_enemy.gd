extends CharacterBody2D
@onready var anim = $AnimatedSprite2D
@onready var punch_hitbox = $PunchHitBox
var player = null
var punch_timer = 0.0
var punch_cooldown = 0.0
var punch_interval = 0.1
var punch_cooldown_time = 1.5
var move_speed = 15.0
var punch_range = 35
var detect_range = 350.0
var hitbox_offset_x = 20.0
var facing = 1
var hp = 5
var blink_timer = 0.0
var blink_duration = 0.15
var is_blinking = false
var punch_facing_locked = false
enum State { IDLE, WALK, PUNCH_WINDUP, PUNCH_ACTIVE, PUNCH_RECOVER }
var state = State.IDLE
var state_timer = 0.0
const GRAVITY = 900.0
const WINDUP_TIME = 0.3
const ACTIVE_TIME = 0.2
const RECOVER_TIME = 0.3
const ACTIVE_HITBOX_DELAY = 0.025

func _ready():
	punch_hitbox.monitoring = false
	anim.play("idle")
	punch_hitbox.body_entered.connect(_on_punch_hit)
	punch_hitbox.position.x = hitbox_offset_x

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
	if punch_cooldown > 0:
		punch_cooldown -= delta
	var distance = global_position.distance_to(player.global_position)
	if not punch_facing_locked:
		if player.global_position.x > global_position.x:
			facing = 1
		else:
			facing = -1
		anim.flip_h = facing == 1
		punch_hitbox.position.x = facing * hitbox_offset_x
	state_timer += delta
	match state:
		State.IDLE:
			velocity.x = 0
			punch_hitbox.monitoring = false
			if distance <= punch_range and punch_cooldown <= 0:
				punch_timer += delta
				if punch_timer >= punch_interval:
					punch_timer = 0.0
					_enter_state(State.PUNCH_WINDUP)
			elif distance <= detect_range:
				_enter_state(State.WALK)
		State.WALK:
			punch_hitbox.monitoring = false
			if distance <= punch_range and punch_cooldown <= 0:
				_enter_state(State.PUNCH_WINDUP)
			elif distance <= detect_range:
				var direction = sign(player.global_position.x - global_position.x)
				velocity.x = direction * move_speed
				anim.play("walk")
			else:
				_enter_state(State.IDLE)
		State.PUNCH_WINDUP:
			velocity.x = 0
			punch_hitbox.monitoring = false
			if state_timer >= WINDUP_TIME:
				_enter_state(State.PUNCH_ACTIVE)
		State.PUNCH_ACTIVE:
			velocity.x = 0
			punch_hitbox.monitoring = state_timer >= ACTIVE_HITBOX_DELAY
			if state_timer >= ACTIVE_TIME:
				_enter_state(State.PUNCH_RECOVER)
		State.PUNCH_RECOVER:
			velocity.x = 0
			punch_hitbox.monitoring = false
			if state_timer >= RECOVER_TIME:
				punch_cooldown = punch_cooldown_time
				if distance <= punch_range:
					_enter_state(State.IDLE)
				else:
					_enter_state(State.WALK)
	move_and_slide()

func _enter_state(new_state):
	state = new_state
	state_timer = 0.0
	match new_state:
		State.IDLE:
			anim.play("idle")
			punch_facing_locked = false
		State.WALK:
			anim.play("walk")
			punch_facing_locked = false
		State.PUNCH_WINDUP:
			anim.play("punch")
			punch_facing_locked = true

func _on_punch_hit(body):
	if body.is_in_group("player"):
		body.take_damage()

func take_hit(damage):
	hp -= damage
	blink()
	if hp <= 0:
		queue_free()

func blink():
	is_blinking = true
	blink_timer = 0.0
	anim.modulate = Color(1, 0.3, 0.3, 1)
