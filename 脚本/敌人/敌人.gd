extends CharacterBody2D

var health = 100
var max_health = 100
var speed = 150
var damage = 10
var knockback_resistance = 0.5
var experience_value = 10
var separation_radius = 150  # 增加分离检测半径
var separation_force = 1.0   # 增加分离力度
var wander_strength = 0.3    # 随机游走强度
var wander_interval = 0.5    # 随机方向更新间隔
var chase_weight = 0.6       # 追逐权重

var target = null
var wander_direction = Vector2.ZERO
var wander_timer = 0.0
var knockback_remaining = Vector2.ZERO

func _ready():
	# 将敌人添加到"enemy"组
	add_to_group("enemy")
	
	# 寻找玩家作为目标
	target = get_tree().get_first_node_in_group("player")
	
	# 更新生命值条
	update_health_bar()
	
	# 初始化随机游走方向
	update_wander_direction()

func _physics_process(delta):
	if target:
		# 更新随机游走方向
		wander_timer += delta
		if wander_timer >= wander_interval:
			update_wander_direction()
			wander_timer = 0.0
		
		# 计算与玩家的距离
		var distance_to_player = global_position.distance_to(target.global_position)
		var min_distance = 20.0  # 最小距离，低于此距离敌人将不再接近玩家
		
		# 计算追逐方向
		var chase_direction = global_position.direction_to(target.global_position)
		
		# 计算分离向量
		var separation = calculate_separation()
		
		# 如果敌人已经足够接近玩家，则不要再接近
		var adjusted_chase_weight = chase_weight
		if distance_to_player < min_distance:
			adjusted_chase_weight = -0.5  # 反向力，轻微远离玩家
		
		# 合并所有行为：追逐/避开、分离和随机游走
		var final_direction = (
			chase_direction * adjusted_chase_weight + 
			separation * separation_force +
			wander_direction * wander_strength
		).normalized()
		
		# 应用最终移动 - 不再使用velocity和move_and_slide，直接修改position
		var move_speed = speed
		
		# 如果非常接近玩家，降低速度以减少推动效果
		if distance_to_player < min_distance * 0.7:
			move_speed *= 0.1
			
		# 使用position直接移动敌人，避免物理推动效果
		global_position += final_direction * move_speed * delta

func update_wander_direction():
	# 生成新的随机游走方向
	var random_angle = randf_range(-PI, PI)
	wander_direction = Vector2(cos(random_angle), sin(random_angle))

func calculate_separation() -> Vector2:
	var separation_vector = Vector2.ZERO
	var nearby_enemies = 0
	
	# 获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if enemy != self:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < separation_radius:
				# 计算远离该敌人的向量
				var away_vector = global_position - enemy.global_position
				# 使用二次方增强近距离分离效果
				var force = pow((separation_radius - distance) / separation_radius, 2)
				separation_vector += away_vector.normalized() * force
				nearby_enemies += 1
	
	# 如果有附近的敌人，计算平均分离向量
	if nearby_enemies > 0:
		separation_vector = separation_vector / nearby_enemies
		
		# 根据附近敌人数量动态调整分离力度
		var crowd_factor = min(nearby_enemies / 5.0, 2.0)  # 最多增加2倍
		separation_vector *= crowd_factor
	
	return separation_vector

func take_damage(amount, direction, knockback_strength):
	health -= amount
	
	# 击退效果 - 不再使用velocity，而是直接修改位置
	# 在几帧内应用击退效果
	var knockback_vector = direction * knockback_strength * (1 - knockback_resistance)
	$击退定时器.wait_time = 0.1  # 短暂的击退时间
	$击退定时器.one_shot = true
	knockback_remaining = knockback_vector
	if !$击退定时器.is_connected("timeout", Callable(self, "_on_knockback_timer_timeout")):
		$击退定时器.connect("timeout", Callable(self, "_on_knockback_timer_timeout"))
	$击退定时器.start()
	
	# 更新生命值条
	update_health_bar()
	
	if health <= 0:
		die()

func _process(delta):
	if knockback_remaining != Vector2.ZERO:
		global_position += knockback_remaining * delta * 10  # 乘以10使击退更明显

func _on_knockback_timer_timeout():
	knockback_remaining = Vector2.ZERO

func update_health_bar():
	# 更新生命值条显示
	if has_node("HealthBar"):
		var health_bar = get_node("HealthBar")
		health_bar.value = float(health) / max_health

func die():
	# 延迟掉落经验宝石，避免物理查询错误
	call_deferred("spawn_experience_gem")
	
	# 销毁敌人，同样延迟执行
	call_deferred("queue_free")

func spawn_experience_gem():
	var gem_scene = preload("res://场景/经验宝石.tscn")
	if gem_scene:
		var gem_instance = gem_scene.instantiate()
		gem_instance.global_position = global_position
		gem_instance.experience_value = experience_value
		# 将宝石添加到游戏场景中，使用call_deferred
		get_parent().get_parent().call_deferred("add_child", gem_instance)
		print("敌人已生成经验宝石")
