extends Area2D

var experience_value = 10
var magnet_range = 150
var magnet_speed = 400
var base_speed = 50
var target = null

func _ready():
	# 寻找玩家作为目标
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if target:
		var distance = global_position.distance_to(target.global_position)
		
		# 如果玩家在磁铁范围内，宝石会被吸引
		if distance < magnet_range:
			var direction = global_position.direction_to(target.global_position)
			var current_speed = lerp(base_speed, magnet_speed, 1.0 - distance / magnet_range)
			global_position += direction * current_speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		# 玩家获得经验
		body.gain_experience(experience_value)
		
		# 销毁宝石
		queue_free() 