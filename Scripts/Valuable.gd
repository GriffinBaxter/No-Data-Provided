extends Node3D

@onready var phone = $phone
@onready var passport = $passport
@onready var license = $license


func _ready():
	while true:
		license.visible = false
		phone.visible = true
		await get_tree().create_timer(1).timeout
		phone.visible = false
		passport.visible = true
		await get_tree().create_timer(1).timeout
		passport.visible = false
		license.visible = true
		await get_tree().create_timer(1).timeout
