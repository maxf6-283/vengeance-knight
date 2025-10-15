extends Area2D

@export var heal_amount := 20 # HEAL AMOUNT DEFINED HERE

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.name == "Knight":
		if body.has_method("heal"):
			body.heal(heal_amount)
		queue_free()
