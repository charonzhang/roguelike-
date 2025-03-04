extends Area2D

var direction = Vector2.RIGHT
var speed = 300
var damage = 10
var knockback_strength = 100

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		# 对敌人造成伤害
		body.take_damage(damage, direction, knockback_strength)
		
		# 销毁子弹
		queue_free()

func _on_生命周期_timeout():
	# 子弹生命周期结束，销毁子弹
	queue_free() 