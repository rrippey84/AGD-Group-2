extends CharacterBody2D
enum State { IDLE, RUN, JUMP, FALL, ATTACK }
const SPEED_RUN  := 90.0
const SPEED_WALK := 30.0
const GRAVITY    := 60.0
const MAX_FALL   := 240.0
const ATK_DURATION  := 0.20
const ATK_HIT_START := 0.04
const ATK_HIT_END   := 0.14
static var JUMP_TABLE := _build_jump_table()
static func _build_jump_table() -> PackedFloat32Array:
	var t := PackedFloat32Array()
	for e: Array in [[-360.0, 5], [-300.0, 5], [-180.0, 4], [-120.0, 4], [0.0, 12]]:
		for _i in e[1]: t.append(e[0])
	return t
var state       := State.IDLE
var facing      := 1
var jump_idx    := 0
var attacking   := false
var attack_time := 0.0
@onready var sprite       : Sprite2D         = $Sprite2D
@onready var anim_player  : AnimationPlayer  = $AnimationPlayer
@onready var attack_area  : Area2D           = $"Attack Area"
@onready var attack_shape : CollisionShape2D = $"Attack Area/CollisionShape2D"
@onready var agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	attack_area.monitoring = false
	attack_shape.disabled  = true
	_update_facing()
	agent.target_position = global_position  # start at current position

func _physics_process(delta: float) -> void:
	var ix  := int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	var run := Input.is_action_pressed("Run")
	var jmp := Input.is_action_just_pressed("Jump")
	var atk := Input.is_action_just_pressed("Attack")
	attack_time = maxf(attack_time - delta, 0.0)
	if attack_time == 0.0: attacking = false
	match state:
		State.IDLE:
			if atk: _do_attack(); return
			if jmp: _do_jump();   return
			if ix != 0:
				_update_facing(ix)
				velocity.x = _speed(run) * facing
				state = State.RUN
			else:
				velocity = Vector2.ZERO
		State.RUN:
			if atk: _do_attack(); return
			if jmp: _do_jump();   return
			if ix == 0:
				velocity.x = 0.0
				state = State.IDLE
			else:
				_update_facing(ix)
				velocity.x = _speed(run) * facing
		State.JUMP:
			if atk: _do_attack()
			if jump_idx < JUMP_TABLE.size():
				velocity.y  = JUMP_TABLE[jump_idx]
				jump_idx   += 1
			else:
				state = State.FALL
			velocity.x = _air_speed(ix, run)
		State.FALL:
			if atk: _do_attack()
			velocity.y = minf(velocity.y + GRAVITY, MAX_FALL)
			velocity.x = _air_speed(ix, run)
		State.ATTACK:
			if not attacking:
				velocity.x = 0.0
				state = State.IDLE
	# var next_point = agent.get_next_path_position()
	# var direction = (next_point - global_position).normalized()
	# velocity = direction * SPEED_RUN  # or SPEED_WALK depending on your state
	move_and_slide()
	if is_on_floor():
		if state == State.JUMP or state == State.FALL:
			state = State.IDLE; jump_idx = 0; velocity.y = 0.0
	elif state == State.IDLE or state == State.RUN:
		state = State.FALL

	var hitbox := attacking and attack_time > ATK_HIT_START and attack_time <= ATK_HIT_END
	attack_area.monitoring = hitbox
	attack_shape.disabled  = not hitbox
	_update_anim(run)
func _do_jump() -> void:
	jump_idx   = 1
	state      = State.JUMP
	velocity.y = JUMP_TABLE[0]
func _do_attack() -> void:
	attacking   = true
	attack_time = ATK_DURATION
	if state != State.JUMP and state != State.FALL:
		state    = State.ATTACK
		velocity = Vector2.ZERO
func _speed(running: bool) -> float:
	return SPEED_RUN if running else SPEED_WALK
func _air_speed(ix: int, running: bool) -> float:
	if ix == 0: return velocity.x
	return (SPEED_RUN if running and ix == facing else SPEED_WALK) * signi(ix)
func _update_facing(ix: int = 0) -> void:
	if ix != 0: facing = signi(ix)
	sprite.flip_h           = facing == -1
	sprite.position.x       = 11.0 * facing
	attack_shape.position.x = 20.0 * facing
func _update_anim(running: bool) -> void:
	var anim  := "Idle"
	var speed := 1.0
	match state:
		State.RUN:              anim = "Walk"; speed = 1.5 if running else 0.6
		State.JUMP, State.FALL: anim = "Jump"
		State.ATTACK:           anim = "Attack"
	if attacking and state != State.ATTACK:
		anim = "Attack"
	if anim_player.current_animation != anim:
		anim_player.play(anim)
	anim_player.speed_scale = speed


func _on_attack_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("mobs"):
		area.take_hit(1)
