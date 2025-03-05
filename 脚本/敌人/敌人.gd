extends CharacterBody2D

var health = 100
var max_health = 100
var speed = 150
var damage = 10
var knockback_resistance = 0.5
var experience_value = 10

var target = null

func _ready():
	# 将敌人添加到"enemy"组
	add_to_group("enemy")
	
	# 寻找玩家作为目标
	target = get_tree().get_first_node_in_group("player")
	
	# 更新生命值条
	update_health_bar()

func _physics_process(delta):
	if target:
		# 向玩家移动
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
		move_and_slide()

func take_damage(amount, direction, knockback_strength):
	health -= amount
	
	# 击退效果
	velocity = direction * knockback_strength * (1 - knockback_resistance)
	
	# 更新生命值条
	update_health_bar()
	
	if health <= 0:
		die()

func update_health_bar():
	# 更新生命值条显示
	if has_node("HealthBar"):
		var health_bar = get_node("HealthBar")
		health_bar.value = float(health) / max_health

func die():
	# 生成经验值
	if target and target.has_method("gain_experience"):
		target.gain_experience(experience_value)
	
	# 播放死亡动画或效果（如果有的话）
	# 可以在这里添加粒子效果、声音等
	
	# 销毁敌人
	queue_free() 