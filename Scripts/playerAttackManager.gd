extends Node

# will deal with attack damage from player, move swapping
# Player will be able to swap out launchers + slammers + grabs
# There are 3 types of swappables: Launchers, Slammers, and Grabs
# Launchers: Upwards hitting moves (multihit launchers, hard launchers)
# Slammers: Downwards hitting moves (multihit slammers, hard slammers)
# Grabs: Grab based moves (reCombo grabs, Throws)
# On special moves enter, check for what kind of swappable the player has --> execute property


# (For now just debug the swappables) 
#Attack state scripts will look at swappable script and check to see which swappble 
#is selected then execute code accordingly 


@export var lightAttackDamage: float = 5
@export var MediumAttackDamage: float = 10
@export var HeavyAttackDamage: float = 15
@export var LauncherAttackDamage: float = 17
@export var AirLightAttackDamage: float = 5
@export var AirMediumAttackDamage: float = 10
@export var AirHeavyAttackDamage: float = 15
@export var AirSlamAttackDamage: float = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
