# Description: Very simple enemy that moves back and forth.
# If it touches the player, knock the player back

extends CharacterBody2D

var health = 50
var SPEED = health * 2 # Idea: speed is proportional to health. The more damaged the enemy is, the slower it moves
var direction = 1  # 1 = right, -1 = left
@onready var hurtbox = $Hurtbox

var damage_to_player = 10 # damages delt to player when touches

func _ready():
	# Connect the built-in 'area_entered' signal from this Area2D (hurtbox) to the custom function that runs when another area touches it
	hurtbox.connect("area_entered", Callable(self, "_on_hurtbox_area_entered"))
	
func _physics_process(delta):
	# Basic horizontal movement
	velocity.x = direction * SPEED

	# Move and slide using built-in method
	move_and_slide()

	# Flip direction when hitting a wall
	if is_on_wall():
		direction *= -1

func _take_damage():
	health -= 10

func _deal_damage(player):
	player._take_damage(10)

# IMPORTANT - Player needs to have an attack hitbox
func _on_hurtbox_area_entered(area):
	# Check if the area is the player's attack hitbox
	if area.name == "AttackHitbox":
		_take_damage()
		print("Enemy hit! Health:", health)
		if health <= 0:
			die()
			
func _on_collision_player(player):
	# Deal damage
	_deal_damage(player)
	
	# Knockback
	var knockback_strength = 200 # amount the player will be knocked back
	var knockback_direction = sign(player.global_position.x - global_position.x) # knockback direction
	player.velocity.x = knockback_direction * knockback_strength # push player back

func die():
	print("Enemy defeated!")
	queue_free()
