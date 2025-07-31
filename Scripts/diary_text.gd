extends Label
class_name DiaryText

@export var diary_entries: Dictionary[int, String] = {}

@export var back_button: Button
@export var forward_button: Button

var page: int = 0

func _ready() -> void:
	text = diary_entries.get(page)
	turn_page(0)

func turn_page(direction: int):
	page += direction
	forward_button.visible = true
	back_button.visible = true
	
	if (page == len(diary_entries) - 1):
		forward_button.visible = false
	if (page == 0):
		back_button.visible = false

	text = diary_entries.get(page)
