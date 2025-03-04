# 玩家脚本 (player.gd)
extends CharacterBody2D

signal player_hit(current_health, max_health)
signal experience_gained(current_exp, max_exp, level)
signal level_up(new_level)

var speed = 300
var max_health = 100
var health = max_health
var experience = 0
var level = 1
var exp_to_next_level = 100
var is_invulnerable = false

@onready var weapons_container = $武器容器
@onready var hurt_timer = $受伤冷却
@onready var hurt_animation = $受伤动画

func _ready():
	# 添加初始武器
	add_weapon("基础武器")

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()

func take_damage(amount):
	if is_invulnerable:
		return
		
	health -= amount
	health = max(0, health)
	
	# 发出受伤信号
	player_hit.emit(health, max_health)
	
	# 设置无敌时间
	is_invulnerable = true
	hurt_timer.start()
	
	# 播放受伤动画
	# hurt_animation.play("hurt")
	
	# 检查是否死亡
	if health <= 0:
		die()

func gain_experience(amount):
	experience += amount
	
	# 检查是否升级
	if experience >= exp_to_next_level:
		level_up()
	
	# 发出经验获得信号
	experience_gained.emit(experience, exp_to_next_level, level)

func level_up():
	level += 1
	experience -= exp_to_next_level
	exp_to_next_level = int(exp_to_next_level * 1.2)
	
	# 恢复生命值
	health = max_health
	player_hit.emit(health, max_health)
	
	# 发出升级信号
	level_up.emit(level)

func add_weapon(weapon_name):
	var weapon_scene = load("res://场景/武器/" + weapon_name + ".tscn")
	if weapon_scene:
		var weapon_instance = weapon_scene.instantiate()
		weapons_container.add_child(weapon_instance)

func upgrade_weapon(weapon_name):
	for weapon in weapons_container.get_children():
		if weapon.name.begins_with(weapon_name):
			weapon.upgrade()
			return

func die():
	# 游戏结束逻辑
	get_tree().paused = true
	# 显示游戏结束界面
	# get_tree().change_scene_to_file("res://场景/游戏结束.tscn")

func _on_hurt_timer_timeout():
	is_invulnerable = false
