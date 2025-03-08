extends Area2D

var direction = Vector2.RIGHT
var speed = 300
var damage = 10
var knockback_strength = 100
var auto_aim = false  # 是否启用自动瞄准
var turn_speed = 3.0  # 转向速度
var max_turn_angle = 45  # 最大转向角度（度）
var critical_chance = 0.1  # 暴击几率
var critical_multiplier = 2.0  # 暴击伤害倍数
var player_hit = false  # 添加这个变量来跟踪是否击中玩家

func _ready():
	# 设置子弹的生命周期
	var timer = Timer.new()
	timer.wait_time = 3.0  # 3秒后销毁
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _physics_process(delta):
	if auto_aim:
		# 寻找最近的敌人
		var target = find_nearest_enemy()
		if target:
			# 计算目标方向
			var target_direction = (target.global_position - global_position).normalized()
			# 计算当前方向与目标方向的角度
			var angle = direction.angle_to(target_direction)
			# 限制最大转向角度
			angle = clamp(angle, -deg_to_rad(max_turn_angle), deg_to_rad(max_turn_angle))
			# 平滑转向
			direction = direction.rotated(angle * turn_speed * delta)
	
	# 移动子弹
	position += direction * speed * delta

func find_nearest_enemy():
	var nearest_enemy = null
	var min_distance = 500  # 最大追踪距离
	
	# 获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		# 计算实际伤害（包含暴击）
		var actual_damage = calculate_damage()
		
		# 对敌人造成伤害
		if body.has_method("take_damage"):
			body.take_damage(actual_damage, direction, knockback_strength)
			
			# 可以在这里添加击中效果
			create_hit_effect(body, actual_damage)
		
		# 销毁子弹
		queue_free()
	elif body.is_in_group("player"):
		# 标记击中玩家
		if "player_hit" in body:
			body.player_hit = true
		
		# 如果需要对玩家造成伤害，取消下面的注释
		# body.take_damage(damage)
		
		# 销毁子弹
		queue_free()

func calculate_damage():
	# 检查是否暴击
	if randf() < critical_chance:
		# 暴击伤害
		return damage * critical_multiplier
	return damage

func create_hit_effect(_enemy, _damage_amount):
	# 这里可以添加击中特效
	# 例如：粒子效果、伤害数字、声音等
	pass
