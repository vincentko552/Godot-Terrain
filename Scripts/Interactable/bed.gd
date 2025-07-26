extends Interactable

@export var day_night_manager: DayNightManager

func interact():
	day_night_manager.advance_time()
