extends Node

## InventoryManager (Autoload Singleton)
## Manages player inventory, equipment, bag storage, item stacking, and item actions.

signal inventory_updated()
signal item_added(item_data: Dictionary)
signal equipment_changed(slot_type: String, item_data: Dictionary)
signal item_used(item_data: Dictionary)
signal toast_notification(item_data: Dictionary)

const MAX_BAG_SLOTS: int = 36

# Inventory bag: array of item dictionaries
var bag_items: Array[Dictionary] = []

# Equipped gear: keys: "weapon", "shield", "boots"
var equipped: Dictionary = {
	"weapon": {},
	"shield": {},
	"boots": {}
}

# Preloaded icon textures
var icons: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preload_icons()
	_init_starter_loadout()

func _preload_icons() -> void:
	icons["sword_wood"] = _load_tex("res://assets/textures/icons/sword_wood.png")
	icons["sword_steel"] = _load_tex("res://assets/textures/icons/sword_steel.png")
	icons["sword_epic"] = _load_tex("res://assets/textures/icons/sword_epic.png")
	icons["sword_legend"] = _load_tex("res://assets/textures/icons/sword_legend.png")
	
	icons["shield_common"] = _load_tex("res://assets/textures/icons/shield_anime.png")
	icons["shield_rare"] = _load_tex("res://assets/textures/icons/shield_steel.png")
	icons["shield_epic"] = _load_tex("res://assets/textures/icons/shield_epic.png")
	icons["shield_legend"] = _load_tex("res://assets/textures/icons/shield_legend.png")
	
	icons["boots_common"] = _load_tex("res://assets/textures/icons/boots_anime.png")
	icons["boots_rare"] = _load_tex("res://assets/textures/icons/boots_anime.png")
	icons["boots_epic"] = _load_tex("res://assets/textures/icons/boots_epic.png")
	icons["boots_legend"] = _load_tex("res://assets/textures/icons/boots_legend.png")
	
	icons["potion_hp"] = _load_tex("res://assets/textures/icons/potion_hp.png")
	icons["crystal_exp"] = _load_tex("res://assets/textures/icons/crystal_exp.png")

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	return null

func _init_starter_loadout() -> void:
	# Default equipped gear
	equipped["weapon"] = create_item("sword_wood")
	equipped["shield"] = create_item("shield_common")
	equipped["boots"] = create_item("boots_common")

	# Starter bag contents
	add_item(create_item("potion_hp", 5), false)
	add_item(create_item("crystal_exp", 3), false)
	add_item(create_item("sword_steel"), false)
	add_item(create_item("shield_rare"), false)
	add_item(create_item("boots_rare"), false)

# ==================== ITEM FACTORY ====================

func create_item(key: String, count: int = 1) -> Dictionary:
	var item: Dictionary = {
		"id": key + "_" + str(randi() % 999999),
		"key": key,
		"name": "Предмет",
		"type": "weapon",
		"rarity": 0,
		"bonus": 5,
		"stat_name": "Сила атаки",
		"desc": "",
		"texture": null,
		"count": count,
		"stackable": false
	}

	match key:
		"sword_wood":
			item["name"] = "Деревянный учебный меч"
			item["type"] = "weapon"
			item["rarity"] = 0
			item["bonus"] = 5
			item["stat_name"] = "Сила атаки"
			item["desc"] = "Простой тренировочный меч из дуба. Идеален для оттачивания базовых рубящих атак."
			item["texture"] = icons.get("sword_wood")

		"sword_steel":
			item["name"] = "Стальной клинок стража"
			item["type"] = "weapon"
			item["rarity"] = 1
			item["bonus"] = 10
			item["stat_name"] = "Сила атаки"
			item["desc"] = "Надежный закаленный меч, выкованный столичными мастерами для защитников городов."
			item["texture"] = icons.get("sword_steel")

		"sword_epic":
			item["name"] = "Лезвие бури (Анемо)"
			item["type"] = "weapon"
			item["rarity"] = 2
			item["bonus"] = 18
			item["stat_name"] = "Сила атаки"
			item["desc"] = "Древний ритуальный меч, в лезвии которого запечатано дыхание штормовых ветров."
			item["texture"] = icons.get("sword_epic")

		"sword_legend":
			item["name"] = "Божественный меч света"
			item["type"] = "weapon"
			item["rarity"] = 3
			item["bonus"] = 32
			item["stat_name"] = "Сила атаки"
			item["desc"] = "Легендарный сияющий клинок богов, рассекающий тьму священным солнечным пламенем."
			item["texture"] = icons.get("sword_legend")

		"shield_common":
			item["name"] = "Кожаный круглый щит"
			item["type"] = "shield"
			item["rarity"] = 0
			item["bonus"] = 5
			item["stat_name"] = "Защита"
			item["desc"] = "Легкий щит из дубленой воловьей кожи, усиленный железными клепками."
			item["texture"] = icons.get("shield_common")

		"shield_rare":
			item["name"] = "Щит сияющей розы"
			item["type"] = "shield"
			item["rarity"] = 1
			item["bonus"] = 12
			item["stat_name"] = "Защита"
			item["desc"] = "Стальной щит с гербом алой розы, отражающий коварные выпады врагов."
			item["texture"] = icons.get("shield_rare")

		"shield_epic":
			item["name"] = "Бастион Титана"
			item["type"] = "shield"
			item["rarity"] = 2
			item["bonus"] = 22
			item["stat_name"] = "Защита"
			item["desc"] = "Тяжелый щит из обломков титанических руин. Способен выдержать колоссальный напор."
			item["texture"] = icons.get("shield_epic")

		"shield_legend":
			item["name"] = "Эгида Анемо Архонта"
			item["type"] = "shield"
			item["rarity"] = 3
			item["bonus"] = 38
			item["stat_name"] = "Защита"
			item["desc"] = "Священная эгида, благословленная ветрами. Поглощает удары подобно вечному вихрю."
			item["texture"] = icons.get("shield_legend")

		"boots_common":
			item["name"] = "Сапоги странника"
			item["type"] = "boots"
			item["rarity"] = 0
			item["bonus"] = 1
			item["stat_name"] = "Скорость"
			item["desc"] = "Мягкие сапоги из плотной ткани, удобные для долгих путешествий по долинам."
			item["texture"] = icons.get("boots_common")

		"boots_rare":
			item["name"] = "Скороходы ветра"
			item["type"] = "boots"
			item["rarity"] = 1
			item["bonus"] = 3
			item["stat_name"] = "Скорость"
			item["desc"] = "Сапоги с зачарованными подошвами, позволяющие двигаться бесшумно и стремительно."
			item["texture"] = icons.get("boots_rare")

		"boots_epic":
			item["name"] = "Сапоги семи лиг"
			item["type"] = "boots"
			item["rarity"] = 2
			item["bonus"] = 5
			item["stat_name"] = "Скорость"
			item["desc"] = "Магическая обувь из мистического шелка. Каждый шаг кажется легким прыжком."
			item["texture"] = icons.get("boots_epic")

		"boots_legend":
			item["name"] = "Крылатые сандалии Гермеса"
			item["type"] = "boots"
			item["rarity"] = 3
			item["bonus"] = 8
			item["stat_name"] = "Скорость"
			item["desc"] = "Легендарные сандалии с золотыми крыльями. Дарят скорость молнии и грацию парения."
			item["texture"] = icons.get("boots_legend")

		"potion_hp":
			item["name"] = "Большое зелье исцеления"
			item["type"] = "potion"
			item["rarity"] = 1
			item["bonus"] = 45
			item["stat_name"] = "Исцеление"
			item["desc"] = "Искрящийся рубиновый эликсир из целебных трав и росы лотоса. Восстанавливает 45 HP."
			item["texture"] = icons.get("potion_hp")
			item["stackable"] = true

		"crystal_exp":
			item["name"] = "Светящийся кристалл стихий"
			item["type"] = "material"
			item["rarity"] = 2
			item["bonus"] = 60
			item["stat_name"] = "Опыт стихий"
			item["desc"] = "Концентрированный кристалл стихийной энергии. При использовании дарует 60 очков опыта."
			item["texture"] = icons.get("crystal_exp")
			item["stackable"] = true

	return item

# ==================== INVENTORY OPERATIONS ====================

func add_item(item_data: Dictionary, show_toast: bool = true) -> bool:
	if item_data.is_empty():
		return false

	var is_stackable = item_data.get("stackable", false)
	var item_name = item_data.get("name", "")

	if is_stackable:
		# Search existing stack in bag
		for i in range(bag_items.size()):
			if bag_items[i].get("name", "") == item_name:
				var current_cnt = bag_items[i].get("count", 1)
				var add_cnt = item_data.get("count", 1)
				bag_items[i]["count"] = current_cnt + add_cnt
				if show_toast:
					toast_notification.emit(item_data)
				inventory_updated.emit()
				return true

	# Check capacity
	if bag_items.size() >= MAX_BAG_SLOTS:
		_speak("Рюкзак полон!")
		return false

	var copy_item = item_data.duplicate(true)
	if not copy_item.has("count"):
		copy_item["count"] = 1
	bag_items.append(copy_item)

	if show_toast:
		toast_notification.emit(copy_item)

	inventory_updated.emit()
	return true

func equip_item_at(bag_index: int) -> bool:
	if bag_index < 0 or bag_index >= bag_items.size():
		return false

	var item = bag_items[bag_index]
	var slot_type = item.get("type", "")
	if not slot_type in ["weapon", "shield", "boots"]:
		return false

	var prev_equipped = equipped.get(slot_type, {})
	equipped[slot_type] = item

	if prev_equipped.is_empty():
		bag_items.remove_at(bag_index)
	else:
		bag_items[bag_index] = prev_equipped

	_apply_equipment_to_player()
	equipment_changed.emit(slot_type, equipped[slot_type])
	inventory_updated.emit()
	_speak("Надето: " + item.get("name", ""))
	return true

func unequip_slot(slot_type: String) -> bool:
	if not slot_type in equipped or equipped[slot_type].is_empty():
		return false

	if bag_items.size() >= MAX_BAG_SLOTS:
		_speak("Рюкзак полон, невозможно снять предмет!")
		return false

	var item = equipped[slot_type]
	equipped[slot_type] = {}
	bag_items.append(item)

	_apply_equipment_to_player()
	equipment_changed.emit(slot_type, {})
	inventory_updated.emit()
	_speak("Снято: " + item.get("name", ""))
	return true

func use_item_at(bag_index: int) -> bool:
	if bag_index < 0 or bag_index >= bag_items.size():
		return false

	var item = bag_items[bag_index]
	var item_type = item.get("type", "")

	if item_type in ["weapon", "shield", "boots"]:
		return equip_item_at(bag_index)

	var player = get_tree().get_first_node_in_group("player") if get_tree() else null

	if item_type == "potion":
		var heal_val = item.get("bonus", 45)
		if player:
			player.current_hp = min(player.max_hp, player.current_hp + heal_val)
			player.emit_stats()
			_spawn_heal_number(player, player.global_position, heal_val)
			_play_chime(player, 1)

		# Decrement count
		item["count"] -= 1
		if item["count"] <= 0:
			bag_items.remove_at(bag_index)

		item_used.emit(item)
		inventory_updated.emit()
		_speak("Зелье восстановило " + str(heal_val) + " здоровья")
		return true

	elif item_type == "material":
		var exp_val = item.get("bonus", 60)
		if player and player.has_method("add_exp"):
			player.add_exp(exp_val)
			_play_chime(player, 2)

		item["count"] -= 1
		if item["count"] <= 0:
			bag_items.remove_at(bag_index)

		item_used.emit(item)
		inventory_updated.emit()
		_speak("Получено " + str(exp_val) + " опыта")
		return true

	return false

func use_quick_potion() -> bool:
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if player and player.current_hp >= player.max_hp:
		_speak("Здоровье уже полно")
		return false

	for i in range(bag_items.size()):
		if bag_items[i].get("type", "") == "potion":
			return use_item_at(i)

	_speak("В рюкзаке нет зелий исцеления!")
	return false

func _speak(text: String) -> void:
	var tree = get_tree()
	if tree and tree.root.has_node("AccessibilityManager"):
		tree.root.get_node("AccessibilityManager").speak(text)

func _play_chime(node: Node, rarity: int) -> void:
	var tree = get_tree()
	if tree and tree.root.has_node("SoundSynth"):
		tree.root.get_node("SoundSynth").play_chime_rarity(node, rarity)

func _spawn_heal_number(node: Node, pos: Vector3, amount: int) -> void:
	var tree = get_tree()
	if tree and tree.root.has_node("DamageNumbers"):
		tree.root.get_node("DamageNumbers").spawn_heal(node, pos, amount)

func get_potion_count() -> int:
	var total = 0
	for item in bag_items:
		if item.get("type", "") == "potion":
			total += item.get("count", 1)
	return total

func get_attack_bonus() -> int:
	var wp = equipped.get("weapon", {})
	return wp.get("bonus", 0) if not wp.is_empty() else 0

func get_defense_bonus() -> int:
	var sh = equipped.get("shield", {})
	return sh.get("bonus", 0) if not sh.is_empty() else 0

func get_speed_bonus() -> float:
	var bt = equipped.get("boots", {})
	return float(bt.get("bonus", 0)) if not bt.is_empty() else 0.0

func _apply_equipment_to_player() -> void:
	var tree = get_tree()
	if not tree:
		return
	var player = tree.get_first_node_in_group("player")
	if not player:
		return

	# Base player stats
	var base_atk = 15
	var base_speed = 7.0

	var wp = equipped.get("weapon", {})
	var bt = equipped.get("boots", {})

	player.attack_power = base_atk + (wp.get("bonus", 0) if not wp.is_empty() else 0)
	player.speed = base_speed + (float(bt.get("bonus", 0)) if not bt.is_empty() else 0.0)

	player.emit_stats()
