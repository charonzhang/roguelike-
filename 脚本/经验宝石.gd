extends Area2D

var experience_value = 10
var magnet_range = 150
var magnet_speed = 400
var base_speed = 50
var target = null
var being_collected = false

func _ready():
	# 寻找玩家作为目标
	target = get_tree().get_first_node_in_group("player")
	print("经验宝石已生成，玩家目标：", target)
	
	# 重要：使用set_deferred设置碰撞检测属性，避免物理查询错误
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	# 显示碰撞层信息
	print("经验宝石碰撞层:", collision_layer, " 碰撞遮罩:", collision_mask)
	
	# 主动连接碰撞信号
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)
		print("手动连接了body_entered信号")

func _physics_process(delta):
	if target and !being_collected:
		var distance = global_position.distance_to(target.global_position)
		
		# 如果玩家在磁铁范围内，宝石会被吸引
		if distance < magnet_range:
			var direction = global_position.direction_to(target.global_position)
			var current_speed = lerp(base_speed, magnet_speed, 1.0 - distance / magnet_range)
			global_position += direction * current_speed * delta

func _process(_delta):
	if not being_collected:
		# 检查是否非常接近玩家
		if target and global_position.distance_to(target.global_position) < 15:
			print("宝石非常接近玩家，直接触发收集")
			collect(target)
			set_process(false) # 触发后停止处理

func _on_body_entered(body):
	print("经验宝石检测到碰撞：", body.name, " 是玩家组：", body.is_in_group("player"))
	
	if body.is_in_group("player") and !being_collected:
		collect(body)

# 收集经验宝石的函数
func collect(body):
	print("玩家收集经验宝石，经验值：", experience_value)
	
	# 标记为正在被收集，防止重复触发
	being_collected = true
	
	# 直接调用玩家的经验获取函数
	if body.has_method("gain_experience"):
		body.gain_experience(experience_value)
		print("已调用玩家的gain_experience函数")
	else:
		push_error("玩家没有gain_experience方法！")
	
	# 播放收集动画
	var sprite = $Sprite2D
	if sprite:
		# 创建完全独立的两个Tween动画
		var fade_tween = create_tween()
		fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.3)  # 淡出动画
		
		var scale_tween = create_tween()
		scale_tween.tween_property(sprite, "scale", Vector2(0.05, 0.05), 0.3)  # 缩小动画
		
		# 使用定时器代替tween回调
		var timer = get_tree().create_timer(0.3)
		timer.timeout.connect(func(): queue_free())
	else:
		# 如果没有精灵节点，直接销毁
		queue_free()
