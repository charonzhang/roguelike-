extends Node2D

# 使用字典存储敌人类型和对应的路径
var enemy_paths = {
	"普通敌人": "res://场景/敌人/敌人.tscn"
}

var game_time = 0
var spawn_rate = 1.0
var max_enemies = 100
var difficulty_increase_rate = 0.1

@onready var player = $玩家
@onready var enemy_spawner = $敌人生成器
@onready var enemy_container = $敌人容器
@onready var game_timer = $游戏计时器
@onready var exp_bar = $UI/经验条
@onready var level_label = $UI/等级
@onready var health_bar = $UI/生命值
@onready var timer_label = $UI/计时器

signal level_up(level: int)

var current_level = 1
var experience = 0
var experience_required = 100
var game_paused = false

func _ready():
	# 连接信号
	if player:
		if player.has_signal("player_hit"):
			player.player_hit.connect(_on_player_hit)
		if player.has_signal("experience_gained"):
			player.experience_gained.connect(_on_experience_gained)
		if player.has_signal("level_up"):
			player.level_up.connect(_on_level_up)
	if game_timer:
		game_timer.timeout.connect(_on_game_timer_timeout)
	
	# 初始化UI
	exp_bar.value = 0
	level_label.text = "1"
	health_bar.value = 1
	timer_label.text = "00:00"

func _process(_delta):
	# 更新游戏时间显示
	var minutes = int(game_time / 60.0)
	var seconds = int(game_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_game_timer_timeout():
	game_time += 1
	
	# 每10秒增加一次难度
	if int(game_time) % 10 == 0:
		increase_difficulty()
	
	# 生成敌人
	spawn_enemies()

func spawn_enemies():
	# 如果敌人场景不存在，只打印一次错误消息
	var enemy_type = "普通敌人"
	var enemy_path = enemy_paths[enemy_type]
	if not ResourceLoader.exists(enemy_path):
		# 使用静态变量记录是否已经打印过错误消息
		if not has_meta("printed_enemy_error"):
			print("敌人场景文件不存在: " + enemy_path + "，请创建此场景文件或修改路径")
			set_meta("printed_enemy_error", true)
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
	
	# 生成敌人
	for i in range(spawn_count):
		if current_enemies + i >= max_enemies:
			break
			
		var enemy_scene = load(enemy_path)
		var enemy_instance = enemy_scene.instantiate()
		
		# 在玩家周围随机位置生成敌人（屏幕外）
		var spawn_distance = 800  # 生成距离
		var spawn_angle = randf() * 2 * PI
		var spawn_position = player.global_position + Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_distance
		
		enemy_instance.global_position = spawn_position
		enemy_container.add_child(enemy_instance)

func increase_difficulty():
	spawn_rate += difficulty_increase_rate
	
	# 可以根据游戏时间增加其他难度参数
	# 例如：敌人生命值、敌人速度等

func _on_player_hit(current_health, max_health):
	health_bar.value = float(current_health) / max_health

func _on_experience_gained(current_exp, max_exp, _level):
	exp_bar.value = float(current_exp) / max_exp

func _on_level_up(level: int):
	show_upgrade_screen()

func gain_experience(amount):
	experience += amount
	$UI/经验条.value = float(experience) / experience_required
	
	if experience >= experience_required:
		current_level += 1
		experience -= experience_required
		experience_required = calculate_next_level_experience()
		$UI/等级.text = str(current_level)
		$UI/经验条.max_value = experience_required
		$UI/经验条.value = float(experience) / experience_required
		show_upgrade_screen()

func calculate_next_level_experience():
	# 每级所需经验值增加20%
	return int(experience_required * 1.2)

func show_upgrade_screen():
	# 暂停游戏
	get_tree().paused = true
	game_paused = true
	
	# 显示升级界面
	var upgrade_screen = $UI/升级界面
	upgrade_screen.visible = true
	
	# 清除旧的升级选项
	var options_container = $UI/升级界面/选项容器
	for child in options_container.get_children():
		child.queue_free()
	
	# 生成新的升级选项
	generate_upgrade_options()

func generate_upgrade_options():
	var options = get_random_upgrades()
	var container = $UI/升级界面/选项容器
	
	for option in options:
		var button = Button.new()
		button.text = option.name + "\n" + option.description
		button.custom_minimum_size = Vector2(300, 80)
		button.pressed.connect(func(): select_upgrade(option))
		container.add_child(button)

func get_random_upgrades():
	# 这里返回可用的升级选项
	return [
		{"name": "增加伤害", "description": "武器伤害增加20%", "type": "damage"},
		{"name": "提升攻速", "description": "攻击速度提升15%", "type": "attack_speed"},
		{"name": "生命提升", "description": "最大生命值增加20%", "type": "health"}
	]

func select_upgrade(upgrade):
	# 应用升级效果
	match upgrade.type:
		"damage":
			# 增加武器伤害
			pass
		"attack_speed":
			# 提升攻击速度
			pass
		"health":
			# 提升最大生命值
			pass
	
	# 关闭升级界面并恢复游戏
	$UI/升级界面.visible = false
	get_tree().paused = false
	game_paused = false
