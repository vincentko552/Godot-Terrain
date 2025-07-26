extends Button

@export var direction: int = 1
@export var panel: DiaryText

func _on_pressed() -> void:
	panel.turn_page(direction)
