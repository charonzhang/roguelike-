extends Node2D

var damage = 10
var attack_speed = 1.0
var level = 1
var bullet_speed = 300
var bullet_count = 1
var bullet_spread = 0
var knockback_strength = 100

@onready var attack_timer = $攻击计时器
@onready var player = get_parent().get_parent()

func _ready():
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _on_attack_timer_timeout():
	attack()

func attack():
	# 寻找最近的敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return
		
	var closest_enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	if closest_enemy:
		# 发射子弹
		for i in range(bullet_count):
			var bullet_scene = load("res://场景/武器/子弹.tscn")
			if bullet_scene:
				var bullet_instance = bullet_scene.instantiate()
				bullet_instance.global_position = global_position
				
				# 计算子弹方向（添加一些随机扩散）
				var direction = global_position.direction_to(closest_enemy.global_position)
				if bullet_spread > 0 and bullet_count > 1:
					var spread_angle = randf_range(-bullet_spread, bullet_spread)
					direction = direction.rotated(deg_to_rad(spread_angle))
				
				bullet_instance.direction = direction
				bullet_instance.speed = bullet_speed
				bullet_instance.damage = damage
				bullet_instance.knockback_strength = knockback_strength
				
				# 将子弹添加到场景中
				get_tree().root.add_child(bullet_instance)

func upgrade():
	level += 1
	
	# 根据等级提升武器属性
	match level:
		2:
			damage += 5
			attack_speed += 0.2
		3:
			bullet_count += 1
			bullet_spread = 15
		4:
			damage += 10
			knockback_strength += 50
		5:
			attack_speed += 0.3
			bullet_count += 1
		_:
			damage += 5
			attack_speed += 0.1
	
	# 更新攻击速度
	attack_timer.wait_time = 1.0 / attack_speed 