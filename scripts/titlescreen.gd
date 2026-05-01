extends Node

func _ready():
	reset_framing(Vector2i(800, 600))

func reset_framing(content_size: Vector2i):
	get_window().set_content_scale_size(content_size)
	%CenteringParent.set_size(content_size)
	%CenteringParent.set_position(
		(get_viewport().get_visible_rect().size / 2.0) - (content_size / 2.0))
	%ClippingParent.set_size(content_size)
	%ClippingParent.set_position(Vector2(0,0))


func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/topscenes/gameplay_topscene.tscn")


func _on_settings_button_pressed():
	pass # Replace with function body.


func _on_extras_button_pressed():
	pass # Replace with function body.


func _on_quit_button_pressed():
	get_tree().quit()
