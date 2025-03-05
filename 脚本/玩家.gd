extends CharacterBody2D

signal player_hit(current_health, max_health)
signal experience_gained(current_exp, max_exp, level)
signal level_up(new_level)

var speed = 300
var health = 100
var max_health = 100
var experience = 0
var level = 1
var weapon_scenes = {
	"子弹": preload("res://场景/武器/子弹武器.tscn")
}

@onready var weapons_container = $weapons_container

func _ready():
	# 将玩家添加到"player"组
	add_to_group("player")
	
	# 如果武器容器不存在，创建一个
	if not has_node("weapons_container"):
		weapons_container = Node2D.new()
		weapons_container.name = "weapons_container"
		add_child(weapons_container)
	
	# 默认添加一个子弹武器
	add_weapon("子弹")
	
	# 打印调试信息
	print("玩家初始化完成，位置:", global_position)

func _physics_process(delta):
	# 获取输入方向
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 打印调试信息
	if direction.length() > 0:
		print("检测到移动输入:", direction)
	
	# 设置速度
	velocity = direction * speed
	
	# 移动玩家
	var collision = move_and_slide()
	
	# 如果有碰撞，打印调试信息
	if get_slide_collision_count() > 0:
		print("玩家碰撞")

func take_damage(amount):
	health -= amount
	
	if health <= 0:
		health = 0
		die()
	
	# 发出信号
	player_hit.emit(health, max_health)

func gain_experience(amount):
	experience += amount
	
	# 计算升级所需经验
	var max_exp = level * 10
	
	# 检查是否升级
	if experience >= max_exp:
		experience -= max_exp
		level += 1
		level_up.emit(level)
	
	# 发出信号
	experience_gained.emit(experience, max_exp, level)

func add_weapon(weapon_name):
	if weapon_name in weapon_scenes:
		var weapon_scene = weapon_scenes[weapon_name]
		var weapon_instance = weapon_scene.instantiate()
		weapon_instance.name = weapon_name
		weapons_container.add_child(weapon_instance)
		return weapon_instance
	else:
		print("武器不存在: " + weapon_name)
		return null

func die():
	# 游戏结束逻辑
	print("玩家死亡")
	# 可以在这里添加游戏结束画面或重新开始游戏的逻辑 