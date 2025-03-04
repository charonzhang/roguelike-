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
	# 生成经验宝石
	spawn_experience_gem()
	
	# 销毁敌人
	queue_free()

func spawn_experience_gem():
	var gem_scene = load("res://场景/经验宝石.tscn")
	if gem_scene:
		var gem_instance = gem_scene.instantiate()
		gem_instance.position = global_position
		gem_instance.experience_value = experience_value
		get_parent().add_child(gem_instance)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage) 