extends CanvasLayer

signal upgrade_selected(upgrade_type, upgrade_name)

var available_weapons = ["基础武器", "激光武器", "火焰武器"]
var available_upgrades = ["攻击力", "攻击速度", "生命值", "移动速度"]
var selected_upgrades = []

@onready var option1_button = $选项容器/选项1
@onready var option2_button = $选项容器/选项2
@onready var option3_button = $选项容器/选项3

func _ready():
	# 暂停游戏
	get_tree().paused = true
	
	# 生成随机升级选项
	generate_upgrade_options()

func generate_upgrade_options():
	selected_upgrades.clear()
	
	# 随机选择3个不同的升级选项
	while selected_upgrades.size() < 3:
		var upgrade_type = randi() % 2  # 0 = 武器, 1 = 属性
		var upgrade_name = ""
		
		if upgrade_type == 0:
			# 武器升级
			upgrade_name = available_weapons[randi() % available_weapons.size()]
		else:
			# 属性升级
			upgrade_name = available_upgrades[randi() % available_upgrades.size()]
		
		var upgrade = {"type": upgrade_type, "name": upgrade_name}
		
		# 确保不重复
		if not selected_upgrades.has(upgrade):
			selected_upgrades.append(upgrade)
	
	# 更新按钮文本
	update_button_text()

func update_button_text():
	for i in range(3):
		var button = get_node("选项容器/选项" + str(i + 1))
		var upgrade = selected_upgrades[i]
		
		var type_text = "新武器" if upgrade.type == 0 else "升级"
		button.text = type_text + ": " + upgrade.name

func _on_选项1_pressed():
	select_upgrade(0)

func _on_选项2_pressed():
	select_upgrade(1)

func _on_选项3_pressed():
	select_upgrade(2)

func select_upgrade(index):
	var upgrade = selected_upgrades[index]
	
	# 发出升级选择信号
	upgrade_selected.emit(upgrade.type, upgrade.name)
	
	# 恢复游戏
	get_tree().paused = false
	
	# 隐藏升级选择界面
	queue_free() 