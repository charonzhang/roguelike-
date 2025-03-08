extends CharacterBody2D

var max_health = 30
var health = max_health
var damage = 10
var speed = 100
var experience_value = 10
var target = null
var knockback_resistance = 0.5

@onready var health_bar = $生命值
@onready var hurt_animation = $受伤动画

func _ready():
	# 寻找玩家作为目标
	target = get_tree().get_first_node_in_group("player")
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	if target:
		# 向玩家移动
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
		move_and_slide()

func take_damage(amount, knockback_vector = Vector2.ZERO, knockback_strength = 0):
	health -= amount
	health = max(0, health)
	
	# 更新生命值条
	health_bar.value = health
	
	# 应用击退效果
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector * knockback_strength * (1 - knockback_resistance)
	
	# 播放受伤动画
	# hurt_animation.play("hurt")
	
	# 检查是否死亡
	if health <= 0:
		die()

func die():
	# 使用call_deferred延迟生成经验宝石，避免物理查询错误
	call_deferred("spawn_experience_gem")
	
	# 销毁敌人
	queue_free()

func spawn_experience_gem():
	print("尝试生成经验宝石")
	var gem_scene = load("res://场景/经验宝石.tscn")
	if gem_scene:
		var gem_instance = gem_scene.instantiate()
		gem_instance.global_position = global_position
		gem_instance.experience_value = experience_value
		
		# 正确添加宝石到主游戏场景
		var main_scene = get_tree().current_scene
		if main_scene:
			print("添加经验宝石到场景")
			# 使用call_deferred安全地添加子节点
			main_scene.call_deferred("add_child", gem_instance)
		else:
			print("无法找到主场景，尝试添加到当前父节点")
			if is_instance_valid(get_parent()):
				get_parent().call_deferred("add_child", gem_instance)
	else:
		push_error("无法加载经验宝石场景")

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage) 
