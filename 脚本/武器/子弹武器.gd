extends Node2D

@onready var bullet_scene = preload("res://场景/武器/子弹.tscn")  # 使用@onready确保资源加载
var bullet_count = 1        # 每次发射的子弹数量
var bullet_spread = 15.0    # 子弹散布角度
var auto_aim_range = 500.0  # 自动瞄准范围
var critical_chance = 0.1   # 暴击几率
var critical_multiplier = 2.0  # 暴击伤害倍数
var shotgun_spread = 30.0   # 散弹枪散布角度
var is_shotgun = false      # 是否为散弹模式
var damage = 15
var attack_speed = 1.5
var level = 1

func _ready():
	# 设置定时器用于自动攻击
	var timer = Timer.new()
	timer.wait_time = 1.0 / attack_speed
	timer.timeout.connect(attack)
	add_child(timer)
	timer.start()

func attack():
	var _player = get_parent().get_parent()
	
	# 寻找最近的敌人
	var target_direction = find_nearest_enemy()
	if target_direction == null:
		# 如果没有找到敌人，使用鼠标方向
		target_direction = (get_global_mouse_position() - global_position).normalized()
	
	# 根据是否为散弹模式决定发射方式
	if is_shotgun:
		shoot_shotgun(target_direction)
	else:
		shoot_normal(target_direction)

func shoot_normal(target_direction):
	for i in range(bullet_count):
		spawn_bullet(target_direction, bullet_spread)

func shoot_shotgun(target_direction):
	var total_spread = shotgun_spread
	var bullets_per_shot = bullet_count * 3  # 散弹模式发射更多子弹
	
	for i in range(bullets_per_shot):
		var spread_angle = randf_range(-total_spread/2, total_spread/2)
		spawn_bullet(target_direction, spread_angle)

func spawn_bullet(direction: Vector2, spread: float):
	var bullet = bullet_scene.instantiate()
	
	# 设置子弹属性
	bullet.damage = damage * (1.0 if !is_shotgun else 0.6)  # 散弹伤害略低
	bullet.critical_chance = critical_chance
	bullet.critical_multiplier = critical_multiplier
	
	# 添加散布角度
	var final_direction = direction.rotated(deg_to_rad(randf_range(-spread, spread)))
	bullet.direction = final_direction
	bullet.global_position = global_position
	bullet.auto_aim = true
	
	# 将子弹添加到场景
	get_tree().root.add_child(bullet)

func find_nearest_enemy():
	var nearest_enemy = null
	var min_distance = auto_aim_range
	
	# 获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	if nearest_enemy:
		return (nearest_enemy.global_position - global_position).normalized()
	return null

func upgrade_to_shotgun():
	is_shotgun = true
	bullet_count = max(bullet_count, 2)  # 确保至少有2发子弹
	attack_speed *= 0.8  # 降低射速作为平衡

func upgrade():
	level += 1
	
	# 每2级增加一个子弹
	if level % 2 == 0:
		bullet_count += 1
	
	# 每3级增加子弹散布和自动瞄准范围
	if level % 3 == 0:
		if is_shotgun:
			shotgun_spread += 10.0
		else:
			bullet_spread += 5.0
		auto_aim_range += 100.0
	
	# 每4级增加暴击几率
	if level % 4 == 0:
		critical_chance += 0.05
	
	# 每5级增加暴击伤害
	if level % 5 == 0:
		critical_multiplier += 0.5 
