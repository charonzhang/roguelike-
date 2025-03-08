extends Node2D

# 使用字典存储敌人类型和对应的路径
var enemy_paths = {
	"普通敌人": "res://场景/敌人/敌人.tscn",  # 更新路径
	"备用路径": "res://场景/敌人.tscn"  # 添加备用路径
}

var game_time = 0
var spawn_rate = 1.0 
var max_enemies = 100
var difficulty_increase_rate = 0.1
var game_paused = false

@onready var player = $玩家
@onready var enemy_container = $敌人容器
@onready var game_timer = $游戏计时器
@onready var exp_bar = $UI/经验条
@onready var level_label = $UI/等级
@onready var health_bar = $UI/生命值
@onready var timer_label = $UI/计时器
var upgrade_ui

# 游戏初始化
func _ready():
	print("初始化游戏...")
	# 不使用延迟初始化，直接使用@onready
	print("UI引用状态: 经验条=", exp_bar != null, ", 生命值=", health_bar != null, 
		", 等级=", level_label != null, ", 计时器=", timer_label != null)
	
	# 检查并创建游戏计时器
	if !game_timer:
		print("游戏计时器不存在，正在创建...")
		game_timer = Timer.new()
		game_timer.name = "游戏计时器"
		game_timer.wait_time = 1.0
		game_timer.one_shot = false
		game_timer.autostart = true
		add_child(game_timer)
		
		# 连接计时器信号
		if not game_timer.timeout.is_connected(_on_game_timer_timeout):
			game_timer.timeout.connect(_on_game_timer_timeout)
	
	# 检查敌人容器
	if !enemy_container:
		print("敌人容器不存在，正在获取...")
		enemy_container = $敌人容器
	
	# 确保玩家存在
	if !player:
		print("玩家不存在，正在获取...")
		player = $玩家
	
	# 初始化升级选择界面
	if !upgrade_ui:
		print("初始化升级选择界面...")
		var upgrade_scene = preload("res://场景/升级选择.tscn")
		if upgrade_scene:
			upgrade_ui = upgrade_scene.instantiate()
			upgrade_ui.name = "升级选择界面"
			add_child(upgrade_ui)
			# 连接升级选择信号
			if upgrade_ui.has_signal("upgrade_selected") and not upgrade_ui.upgrade_selected.is_connected(_on_upgrade_selected):
				upgrade_ui.upgrade_selected.connect(_on_upgrade_selected)
			# 初始化时隐藏升级界面
			upgrade_ui.visible = false
			print("升级选择界面初始化成功")
		else:
			push_error("无法加载升级选择场景!")
		
	if !player or !enemy_container:
		push_error("必要节点未找到!")
		return
		
	# 确保游戏开始时没有暂停
	game_paused = false
	get_tree().paused = false  # 确保整个场景树不是暂停状态
	print("游戏已取消暂停状态")
	
	# 初始时隐藏升级界面
	upgrade_ui = get_node_or_null("UI/升级界面")
	if upgrade_ui:
		upgrade_ui.visible = false
		upgrade_ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		
		# 连接信号
		if upgrade_ui.has_signal("upgrade_selected") and not upgrade_ui.upgrade_selected.is_connected(_on_upgrade_selected):
			upgrade_ui.upgrade_selected.connect(_on_upgrade_selected)
	
	# 连接玩家信号
	if player:
		if player.has_signal("experience_gained") and not player.is_connected("experience_gained", _on_experience_gained):
			player.experience_gained.connect(_on_experience_gained)
		if player.has_signal("player_hit") and not player.is_connected("player_hit", _on_player_hit):
			player.player_hit.connect(_on_player_hit)
		if player.has_signal("level_up") and not player.is_connected("level_up", _on_level_up_player):
			player.level_up.connect(_on_level_up_player)
	
	# 打印玩家信息，确认玩家存在
	if player:
		print("玩家已找到，位置:", player.global_position)
	else:
		push_error("玩家节点未找到!")
	
	# 启动游戏计时器
	if game_timer:
		print("游戏计时器已启动")
		game_timer.start()
	else:
		push_error("游戏计时器未找到!")

# 初始化所有UI引用，避免空引用问题
func initialize_ui_references():
	# UI引用已在_ready中初始化，无需再次初始化
	pass

# 更新游戏界面的方法，统一处理UI更新，避免空引用
func update_ui():
	# 更新经验条
	if exp_bar and player:
		var max_exp = player.level * 10
		exp_bar.max_value = max_exp
		exp_bar.value = player.experience
		# 显示经验值文本
		exp_bar.get_node_or_null("Label").text = str(player.experience) + " / " + str(max_exp)
	
	# 更新生命值条
	if health_bar and player:
		health_bar.max_value = player.max_health
		health_bar.value = player.health
	
	# 更新等级显示
	if level_label and player:
		level_label.text = "等级: " + str(player.level)
	
	# 更新计时器显示
	if timer_label:
		var minutes = int(float(game_time) / 60)
		var seconds = game_time % 60
		timer_label.text = "%02d:%02d" % [minutes, seconds]

func show_upgrade_screen():
	# 使用已存在的升级界面节点
	if upgrade_ui:
		upgrade_ui.visible = true
		get_tree().paused = true
		game_paused = true
	else:
		push_error("升级界面节点未找到!")

func _on_game_timer_timeout():
	print("计时器触发，游戏时间:", game_time)
	game_time += 1
	if game_time % 10 == 0:
		increase_difficulty()
	
	# 更新UI
	update_ui()
	
	# 生成敌人
	spawn_enemies()

func spawn_enemies():
	# 检查玩家是否存在
	if !player:
		push_error("生成敌人时玩家不存在!")
		return
		
	# 如果游戏暂停，不生成敌人
	if game_paused or get_tree().paused:
		return
	
	# 尝试加载敌人场景
	var enemy_scene = null
	var enemy_type = "普通敌人"
	var loaded_path = ""
	
	# 先尝试主路径
	loaded_path = enemy_paths[enemy_type]
	print("尝试加载敌人场景：", loaded_path)
	
	if ResourceLoader.exists(loaded_path):
		enemy_scene = load(loaded_path)
		print("已成功加载敌人场景：", loaded_path)
	else:
		print("主路径敌人场景不存在，尝试备用路径")
		loaded_path = enemy_paths["备用路径"]
		
		if ResourceLoader.exists(loaded_path):
			enemy_scene = load(loaded_path)
			print("已成功加载备用敌人场景：", loaded_path)
		else:
			if not has_meta("printed_enemy_error"):
				push_error("所有敌人场景路径都无效！请创建敌人场景文件")
				set_meta("printed_enemy_error", true)
			return
	
	# 如果无法加载敌人场景，退出
	if not enemy_scene:
		push_error("无法加载敌人场景")
		return
	
	# 计算要生成的敌人数量
	var spawn_count = int(spawn_rate)
	
	# 额外概率生成一个敌人
	if randf() < (spawn_rate - spawn_count):
		spawn_count += 1
	
	# 检查当前敌人数量
	var current_enemies = enemy_container.get_child_count()
	if current_enemies >= max_enemies:
		return
	
	print("将生成", spawn_count, "个敌人，当前敌人数量：", current_enemies)
	
	# 生成敌人
	var max_attempts = 10  # 每个敌人最大尝试次数
	var min_distance = 200  # 敌人生成离玩家的最小距离
	var screen_size = get_viewport_rect().size
	
	for i in range(spawn_count):
		if current_enemies + i >= max_enemies:
			break
		
		var valid_position = false
		var spawn_position = Vector2.ZERO
		var attempts = 0
		
		# 尝试找到有效位置
		while !valid_position and attempts < max_attempts:
			# 生成随机位置
			var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var distance = randf_range(min_distance, min_distance * 1.5)
			spawn_position = player.global_position + direction * distance
			
			# 确保在屏幕范围内
			spawn_position.x = clamp(spawn_position.x, 0, screen_size.x)
			spawn_position.y = clamp(spawn_position.y, 0, screen_size.y)
			
			valid_position = true
			attempts += 1
		
		# 实例化敌人
		if valid_position:
			var enemy_instance = enemy_scene.instantiate()
			enemy_instance.global_position = spawn_position
			print("在位置", spawn_position, "生成敌人")
			enemy_container.add_child(enemy_instance)

func increase_difficulty():
	spawn_rate += difficulty_increase_rate
	
	# 可以根据游戏时间增加其他难度参数
	# 例如：敌人生命值、敌人速度等

func _on_player_hit(current_health, max_health):
	if health_bar:
		health_bar.value = float(current_health) / max_health

func _on_experience_gained(current_exp, max_exp, current_level):
	print("收到经验更新信号：当前经验=", current_exp, "，最大经验=", max_exp, "，当前等级=", current_level)
	
	# 确保经验条存在
	if !exp_bar:
		exp_bar = $UI/经验条
		if !exp_bar:
			push_error("经验条节点仍然不存在！")
			return
	
	# 使用绝对值更新经验条
	exp_bar.max_value = max_exp
	exp_bar.value = current_exp
	print("经验条已更新：", current_exp, "/", max_exp, " (", (float(current_exp) / max_exp) * 100, "%)")
	
	# 更新经验条文本
	var exp_label = exp_bar.get_node_or_null("Label")
	if exp_label:
		exp_label.text = str(current_exp) + " / " + str(max_exp)
		print("经验条文本已更新：", exp_label.text)
	else:
		print("经验条Label不存在，无法更新文本")
	
	# 同时更新等级显示
	if !level_label:
		level_label = $UI/等级
	
	if level_label:
		level_label.text = "等级: " + str(current_level)
		print("等级标签已更新：", level_label.text)

func _on_level_up_player(_level: int):
	show_upgrade_screen()

# 处理升级选择的函数
func _on_upgrade_selected(upgrade_type, upgrade_name):
	if player:
		if upgrade_type == 0:  # 武器升级
			print("选择了武器: ", upgrade_name)
			# 这里可以为玩家添加新武器或升级现有武器
			if upgrade_name == "基础武器":
				var weapon = player.weapons_container.get_node_or_null("子弹武器")
				if weapon:
					weapon.upgrade()
			elif upgrade_name == "激光武器":
				# 添加激光武器逻辑
				pass
			elif upgrade_name == "火焰武器":
				# 添加火焰武器逻辑
				pass
		else:  # 属性升级
			print("选择了属性升级: ", upgrade_name)
			# 这里可以升级玩家的属性
			if upgrade_name == "攻击力":
				# 为所有武器增加伤害
				for weapon in player.weapons_container.get_children():
					if "damage" in weapon:
						weapon.damage *= 1.2  # 增加20%伤害
			elif upgrade_name == "攻击速度":
				# 为所有武器增加攻击速度
				for weapon in player.weapons_container.get_children():
					if "attack_speed" in weapon:
						weapon.attack_speed *= 1.2  # 增加20%攻击速度
			elif upgrade_name == "生命值":
				# 增加生命值
				player.max_health *= 1.2
				player.health = player.max_health
				
				# 通知玩家生命值已更新，而不是直接设置UI
				player.emit_signal("player_hit", player.health, player.max_health)
			elif upgrade_name == "移动速度":
				# 增加移动速度
				player.speed *= 1.1  # 增加10%移动速度
	
	# 隐藏升级界面
	if upgrade_ui:
		upgrade_ui.visible = false
	
	# 恢复游戏
	get_tree().paused = false
	game_paused = false
	
	print("游戏已恢复，暂停状态:", get_tree().paused)
	
	# 更新所有UI
	update_ui()
