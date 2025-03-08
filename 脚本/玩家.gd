extends CharacterBody2D

signal player_hit(current_health, max_health)
signal experience_gained(current_exp, max_exp, level)
signal level_up(level)

var speed = 300
var health = 100
var max_health = 100
var experience = 0
var level = 1
var weapon_scenes = {
	"子弹": preload("res://场景/武器/子弹武器.tscn")
}

# 新增：为了避免开始游戏就升级的问题，记录已经初始化
var initialized = false

@onready var weapons_container = $武器容器

func _ready():
	# 将玩家添加到"player"组
	add_to_group("player")
	
	# 确保碰撞形状存在并正确配置
	var collision_shape = $CollisionShape2D
	if collision_shape and !collision_shape.shape:
		print("玩家碰撞形状未设置，正在创建...")
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 10.0  # 设置适当的半径
		collision_shape.shape = circle_shape
		print("已为玩家创建碰撞形状")
	
	# 确保武器容器存在
	if !has_node("武器容器"):
		# 创建武器容器节点
		var container = Node2D.new()
		container.name = "武器容器"
		add_child(container)
		weapons_container = container
		
		# 创建子弹武器节点
		var bullet_weapon = preload("res://场景/武器/子弹武器.tscn").instantiate()
		bullet_weapon.name = "子弹武器"
		container.add_child(bullet_weapon)
	else:
		weapons_container = $武器容器
	
	# 发出初始的经验值信号，初始化UI
	emit_signal("experience_gained", experience, level * 10, level)
	emit_signal("player_hit", health, max_health)
	
	# 设置已初始化标记
	initialized = true
	
	# 打印调试信息
	print("玩家初始化完成，位置:", global_position)

func _physics_process(delta):
	# 获取输入方向
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# 归一化向量以防止对角线移动更快
	if direction.length() > 0:
		direction = direction.normalized()
	
	# 直接修改位置
	global_position += direction * speed * delta

func take_damage(amount):
	health -= amount
	health = max(0, health)  # 确保生命值不会低于0
	emit_signal("player_hit", health, max_health)
	
	if health <= 0:
		die()

func gain_experience(amount):
	print("【玩家】获得经验：", amount, "，当前经验：", experience, "，等级：", level)
	
	# 检查参数是否有效
	if amount <= 0:
		push_error("尝试添加无效的经验值：", amount)
		return
		
	# 增加经验值
	experience += amount
	
	# 计算升级所需经验
	var max_exp = level * 10
	
	print("【玩家】经验更新后：", experience, "/", max_exp)
	
	# 检查是否升级
	if experience >= max_exp:
		experience -= max_exp
		level += 1
		print("【玩家】升级！新等级：", level)
		# 只有在已经初始化后才发送升级信号
		if initialized:
			emit_signal("level_up", level)
	
	# 发出信号
	emit_signal("experience_gained", experience, max_exp, level)
	print("【玩家】已发送经验更新信号：", experience, "/", max_exp, "，等级：", level)

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
