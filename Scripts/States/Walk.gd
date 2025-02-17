extends LimboState

@onready var armature = $"../../RootNode/Armature"
@onready var state_machine: LimboHSM = $LimboHSM


@export var BASE_SPEED: float = 6.0
@export var MAX_SPEED: float = 11.0
@export var ACCELERATION: float = 10.0 #the higher the value the faster the acceleration
@export var DECELERATION: float = 1.0 #the lower the value the slippier the stop
@export var BASE_DECELERATION: float = 1.0
@export var momentum_deceleration: float = 1.0



@export var JUMP_VELOCITY: float = 10.0
const CUSTOM_GRAVITY: float = 30.0
@export var air_timer: float = 0.0
@export var jump_timer: float = 0.0
@export var jump_counter: float = 0
@export var can_jump: bool = true
var last_ground_position = Vector3.ZERO

var current_speed: float = 0.0
var is_moving: bool = false
var target_speed: float = MAX_SPEED
var velocity = Vector3.ZERO

func _enter() -> void:
    print("Current State:", agent.state_machine.get_active_state())

func _update(delta: float) -> void:
    player_movement(delta)
    player_jump(delta)
    print(velocity.length())
    agent.move_and_slide()

func player_movement(delta: float) -> void:
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (agent.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    direction = direction.rotated(Vector3.UP, Global.spring_arm_pivot.rotation.y)

    if direction != Vector3.ZERO:
        is_moving = true
        armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), Global.armature_rot_speed)

        # Calculate the target rotation (the direction the player should face)
        var target_rotation = atan2(direction.x, direction.z)
        
        # Update speed and direction based on movement input
        if velocity.dot(direction) < 0:
            current_speed = move_toward(current_speed, 0, momentum_deceleration * delta)
        
        if current_speed < target_speed:
            current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)
        else:
            current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)

        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
    else:
        # No movement input, slow down and transition to idle
        is_moving = false
        current_speed = 0
        velocity.x = move_toward(velocity.x, 0, BASE_DECELERATION * delta)
        velocity.z = move_toward(velocity.z, 0, BASE_DECELERATION * delta)

    # ✅ Preserve velocity.y so gravity still applies
    velocity.y = agent.velocity.y  

    if velocity.length() <= 0:
        agent.state_machine.dispatch("to_idle")

    agent.velocity = velocity




func _unhandled_input(event):
    if event is InputEventMouseMotion:

        var rotation_x = Global.spring_arm_pivot.rotation.x - event.relative.y * Global.mouse_sensitivity
        var rotation_y = Global.spring_arm_pivot.rotation.y - event.relative.x * Global.mouse_sensitivity

        rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

        Global.spring_arm_pivot.rotation.x = rotation_x
        Global.spring_arm_pivot.rotation.y = rotation_y


func player_jump(delta: float) -> void:
    if Input.is_action_just_pressed("move_jump") and agent.is_on_floor():
        agent.state_machine.dispatch("to_jump")
        #agent.velocity.y = JUMP_VELOCITY
