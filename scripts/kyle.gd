extends CharacterBody2D
enum Direction { LEFT, RIGHT }

@onready var animation_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree

@onready var idle_timer = $IdleTimer
@onready var running_timer = $RunningTimer
@onready var run_cooldown_timer = $RunCooldownTimer
@onready var is_running_label = $"../Debug/is_running"


@export var has_gun = true

@export var walking_speed = 100
@export var running_speed = 300
#@export var increment_speed = 0.9
@export var gravity = 30
@export var jump_force = 900

# debug shit
@onready var switching_direction_label = $"../Debug/switching_direction"
@onready var switching_while_running_label = $"../Debug/switching_while_running"
@onready var run_cooldown_label = $"../Debug/run_cooldown"


var facing: Direction = Direction.RIGHT
var is_running = false
var direction = 0
var switching_while_running = false
var run_cooldown = false

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
		# fall down
		velocity.y += gravity

	velocity.y = minf(velocity.y, 1000)

	#if (Input.is_action_just_pressed("jump")):
		#velocity.y = -jump_force

	#var can_change_direction = !switching_while_running
	var can_change_direction = true
	if (can_change_direction):
		direction = Input.get_axis("move_left", "move_right")
	
	var just_switched_direction = false # switched direction this frame!

	if (direction < 0 && facing == Direction.RIGHT):
		facing = Direction.LEFT
		just_switched_direction = true
	if (direction > 0 && facing == Direction.LEFT):
		facing = Direction.RIGHT
		just_switched_direction = true
		
	#if (is_running && just_switched_direction):
		#switching_while_running = true
	if (is_running && !run_cooldown && (abs(direction) == 0)):
		# ending the run cooldown animation sets this to false again
		is_running = false
		run_cooldown = true
		print('cooldown animation started', abs(direction) )
		
	var standing_still = abs(direction) == 0

	if (is_running): 
		running_timer.stop()
		#print('switching')

	if (!standing_still && !is_running && running_timer.time_left == 0):
		# if walking we start a timer to start running after a specified amount of time
		running_timer.start()

	if (just_switched_direction || standing_still):
		running_timer.stop()
	
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
	
	if (run_cooldown):
		animation_tree["parameters/conditions/switching"] = true
		
	elif (standing_still):
		#print('standing still')
		is_running = false
		animation_tree["parameters/conditions/standing"] = true
		animation_tree["parameters/conditions/walking"] = false
		animation_tree["parameters/conditions/running"] = false
		#animation_tree.get("parameters/playback").travel("una-run-right-windup")
	else:
		#print('not standing still')
		animation_tree["parameters/conditions/standing"] = false
		animation_tree["parameters/conditions/walking"] = !is_running
		animation_tree["parameters/conditions/running"] = is_running
		animation_tree["parameters/conditions/switching"] = false
		animation_tree["parameters/conditions/idleing"] = false
		#animation_tree.get("parameters/playback").travel("una-idle")

	move_and_slide()

	# inform debug overlay
	switching_direction_label.text = "switching_direction:" + str(switching_direction)
	switching_while_running_label.text = "switching_while_running:" + str(switching_while_running)
	run_cooldown_label.text = "run_cooldown:" + str(run_cooldown)
	is_running_label.text = "is_running:" + str(is_running)
	
func _on_idle_timer_timeout():
	animation_tree["parameters/conditions/idleing"] = true
	await animation_tree.animation_finished
	animation_tree["parameters/conditions/idleing"] = false
	animation_tree["parameters/conditions/standing"] = true
	

func _on_running_timer_timeout():
	# moves from walking to running
	print('running cooldown timeout, we start running now')
	is_running = true


func _on_run_cooldown_timer_timeout():
	# the grace period where user can change direction but still keep
	# runninng is now expired
	pass
	
func _on_run_turn_finished():
	print("finished turning..")
	run_cooldown = false
	is_running = false
	#animation_tree["parameters/conditions/standing"] = true
	animation_tree.get("parameters/playback").travel("una-stand")
