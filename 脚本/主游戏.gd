extends Node2D

var enemy_scenes = {
	"普通敌人": preload("res://场景/敌人.tscn")
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

func _ready():
	# 连接信号
	player.player_hit.connect(_on_player_hit)
	player.experience_gained.connect(_on_experience_gained)
	player.level_up.connect(_on_level_up)
	game_timer.timeout.connect(_on_game_timer_timeout)
	
	# 初始化UI
	exp_bar.value = 0
	level_label.text = "1"
	health_bar.value = 1
	timer_label.text = "00:00"

func _process(delta):
	# 更新游戏时间显示
	var minutes = int(game_time / 60)
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
			
		var enemy_type = "普通敌人"  # 可以根据游戏时间选择不同类型的敌人
		var enemy_scene = enemy_scenes[enemy_type]
		
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

func _on_experience_gained(current_exp, max_exp, level):
	exp_bar.value = float(current_exp) / max_exp

func _on_level_up(new_level):
	level_label.text = str(new_level)
	
	# 显示升级选择界面
	var upgrade_scene = load("res://场景/升级选择.tscn")
	if upgrade_scene:
		var upgrade_instance = upgrade_scene.instantiate()
		upgrade_instance.upgrade_selected.connect(_on_upgrade_selected)
		add_child(upgrade_instance)

func _on_upgrade_selected(upgrade_type, upgrade_name):
	if upgrade_type == 0:
		# 武器升级
		var existing_weapon = false
		
		# 检查玩家是否已有该武器
		for weapon in player.weapons_container.get_children():
			if weapon.name.begins_with(upgrade_name):
				# 升级现有武器
				weapon.upgrade()
				existing_weapon = true
				break
		
		if not existing_weapon:
			# 添加新武器
			player.add_weapon(upgrade_name)
	else:
		# 属性升级
		match upgrade_name:
			"攻击力":
				# 提升所有武器的攻击力
				for weapon in player.weapons_container.get_children():
					weapon.damage += 5
			"攻击速度":
				# 提升所有武器的攻击速度
				for weapon in player.weapons_container.get_children():
					weapon.attack_speed += 0.2
					weapon.attack_timer.wait_time = 1.0 / weapon.attack_speed
			"生命值":
				# 提升玩家生命值
				player.max_health += 20
				player.health = player.max_health
				player.player_hit.emit(player.health, player.max_health)
			"移动速度":
				# 提升玩家移动速度
				player.speed += 30 