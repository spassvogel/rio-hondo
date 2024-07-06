extends CharacterBody2D
enum Direction { LEFT, RIGHT }

@onready var animation_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree

@onready var idle_timer = $IdleTimer
@onready var running_timer = $RunningTimer
@onready var run_cooldown_timer = $RunCooldownTimer

@export var has_gun = true

@export var walking_speed = 100
@export var running_speed = 300
#@export var increment_speed = 0.9
@export var gravity = 30
@export var jump_force = 900

var facing: Direction = Direction.RIGHT
var is_running = false
var direction = 0

func _ready():
	animation_tree.active = true

func _process(_delta):
	
	if (Input.is_action_just_pressed("jump")):
		has_gun = !has_gun

	#var sprite: AnimatedSprite2D
		

	
	#var direction = Input.get_axis("move_left", "move_right")
	#if (direction != 0):
		#animation.scale = Vector2(direction, 1)
	
func _physics_process(_delta):
	if !is_on_floor():
		velocity.y += gravity

	velocity.y = minf(velocity.y, 1000)

	#if (Input.is_action_just_pressed("jump")):
		#velocity.y = -jump_force

	if (run_cooldown_timer.time_left == 0):
		direction = Input.get_axis("move_left", "move_right")
	
	var switching_direction = false

	if (direction < 0 && facing == Direction.RIGHT):
		facing = Direction.LEFT
		switching_direction = true
	if (direction > 0 && facing == Direction.LEFT):
		facing = Direction.RIGHT
		switching_direction = true
	
	if (is_running && switching_direction):
		run_cooldown_timer.start()
		
	var standing_still = abs(direction) == 0 && run_cooldown_timer.time_left == 0

	if (switching_direction && is_running): 
		running_timer.stop()
		print('switching')

	if (!standing_still && !is_running && running_timer.time_left == 0):
		# if walking we start a timer to start running after a specified amount of time
		running_timer.start()

	
	# start or stop idle timer	
	if (!standing_still):
		idle_timer.stop()
	elif (idle_timer.time_left == 0):
		idle_timer.start()
		
	# mirror the sprite
	animation_sprite.flip_h = facing == Direction.LEFT

	var speed = walking_speed
	if (is_running):
		speed = running_speed
	velocity.x = speed * direction
	
	if (standing_still):
		print('standing still')
		is_running = false
		animation_tree["parameters/conditions/standing"] = true
		animation_tree["parameters/conditions/walking"] = false
		animation_tree["parameters/conditions/running"] = false
		#animation_tree.get("parameters/playback").travel("una-run-right-windup")
	else:
		print('not standing still')
		animation_tree["parameters/conditions/standing"] = false
		animation_tree["parameters/conditions/walking"] = !is_running
		animation_tree["parameters/conditions/running"] = is_running
		animation_tree["parameters/conditions/switching"] = switching_direction
		animation_tree["parameters/conditions/idleing"] = false
		#animation_tree.get("parameters/playback").travel("una-idle")

	move_and_slide()
	

func _on_idle_timer_timeout():
	animation_tree["parameters/conditions/idleing"] = true
	await animation_tree.animation_finished
	animation_tree["parameters/conditions/idleing"] = false
	animation_tree["parameters/conditions/standing"] = true
	

func _on_running_timer_timeout():
	# moves from walking to running
	is_running = true


func _on_run_cooldown_timer_timeout():
	# the grace period where user can change direction but still keep
	# runninng is now expired
	pass
