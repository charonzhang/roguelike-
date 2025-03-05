extends Node2D

var damage = 10
var attack_speed = 1.0
var level = 1

@onready var attack_timer = $attack_timer

func _ready():
	# 如果计时器不存在，创建一个
	if not has_node("attack_timer"):
		attack_timer = Timer.new()
		attack_timer.name = "attack_timer"
		attack_timer.wait_time = 1.0 / attack_speed
		attack_timer.autostart = true
		add_child(attack_timer)
	
	# 连接计时器信号
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _on_attack_timer_timeout():
	attack()

func attack():
	# 在子类中实现具体的攻击逻辑
	pass

func upgrade():
	level += 1
	damage += 5
	attack_speed += 0.2
	attack_timer.wait_time = 1.0 / attack_speed 