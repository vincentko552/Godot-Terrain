extends Trigger
class_name EnemyTrigger

@export var enemy: Enemy
@export var thoughts: ThoughtsUI

func do_trigger():
	enemy.spawn()
	await get_tree().create_timer(2.0).timeout
	thoughts.appear("It's here, I have failed.")
	await get_tree().create_timer(5.0).timeout
	thoughts.appear("I can't fight it anymore.")

func on_event():
	super.on_event()
