extends "res://脚本/武器/武器.gd"

var bullet_scene = preload("res://场景/武器/子弹.tscn")
var bullet_count = 1
var bullet_spread = 15.0  # 子弹散布角度
var auto_aim_range = 500.0  # 自动瞄准范围
var critical_chance = 0.1  # 暴击几率
var critical_multiplier = 2.0  # 暴击伤害倍数

func _ready():
	super._ready()
	damage = 15
	attack_speed = 1.5

func attack():
	var player = get_parent().get_parent()
	
	# 寻找最近的敌人
	var target_direction = find_nearest_enemy()
	if target_direction == null:
		# 如果没有找到敌人，使用鼠标方向
		target_direction = (get_global_mouse_position() - global_position).normalized()
	
	# 生成子弹
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		
		# 设置子弹属性
		bullet.damage = damage
		bullet.critical_chance = critical_chance
		bullet.critical_multiplier = critical_multiplier
		# 添加散布角度
		bullet.direction = target_direction.rotated(deg_to_rad(randf_range(-bullet_spread, bullet_spread)))
		bullet.global_position = global_position
		bullet.auto_aim = true  # 启用自动瞄准
		
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

func upgrade():
	super.upgrade()
	
	# 每2级增加一个子弹
	if level % 2 == 0:
		bullet_count += 1
	
	# 每3级增加子弹散布和自动瞄准范围
	if level % 3 == 0:
		bullet_spread += 5.0
		auto_aim_range += 100.0
	
	# 每4级增加暴击几率
	if level % 4 == 0:
		critical_chance += 0.05
	
	# 每5级增加暴击伤害
	if level % 5 == 0:
		critical_multiplier += 0.5 