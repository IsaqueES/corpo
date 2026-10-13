extends Node3D
## O que a Cabeça vê: o corpo inteiro no mundo lá fora e o painel de ordens.
## Só a Cabeça enxerga o mundo; Braços e Pernas dependem das ordens dela.

const ARM_COMMANDS := [
	"Estique o braço esquerdo", "Estique o braço direito",
	"Feche a mão esquerda", "Feche a mão direita",
	"Abra as mãos", "Recolha os braços",
	"Apague o fogo!", "Troque de braço",
]
const LEG_COMMANDS := [
	"Levante a perna esquerda", "Levante a perna direita",
	"Perna pra frente", "Abaixe a perna",
	"Pare!", "Troque de perna",
]
const ARM_DOWN := -75.0
const ARM_FORWARD := -26.6
const FINGER_CLOSED := -100.0
const LEG_LIFTED := 20.0
const LEG_FORWARD := 50.0
const SIDE_X := [-1.0, 1.0]  # esquerda = -x (o corpo olha para -z)
const TABLE_Z := -3.25
const APPLE_Z := -3.0

var _body: Node3D
var _shoulders: Array[Node3D] = []
var _hands: Array[Node3D] = []
var _fingers := [[], []]
var _hips: Array[Node3D] = []
var _apple: MeshInstance3D
var _cam: Camera3D
var _alert: Label
var _info: Label
var _orders: Label
var _log: Label
var _custom: LineEdit
var _time := 0.0


func _ready() -> void:
	_build_world()
	_build_hud()
	Game.state_changed.connect(_refresh)
	Game.notice.connect(func(text: String) -> void: _log.text = text)
	_body.position.z = Game.body_z
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	var t := clampf(delta * 6.0, 0.0, 1.0)
	_body.position.z = lerpf(_body.position.z, Game.body_z, t)
	for s in 2:
		var arm: Dictionary = Game.arms[s]
		var shoulder := _shoulders[s]
		shoulder.rotation_degrees.x = lerpf(shoulder.rotation_degrees.x, ARM_FORWARD if arm.extended else ARM_DOWN, t)
		for i in 5:
			var finger: Node3D = _fingers[s][i]
			finger.rotation_degrees.x = lerpf(finger.rotation_degrees.x, FINGER_CLOSED if arm.fingers[i] else 0.0, t)
		var leg: Dictionary = Game.legs[s]
		var target := LEG_FORWARD if leg.forward else (LEG_LIFTED if leg.lifted else 0.0)
		_hips[s].rotation_degrees.x = lerpf(_hips[s].rotation_degrees.x, target, t)

	var apple_x: float = SIDE_X[Game.apple_side] * 0.33
	if Game.grabbed:
		_apple.global_position = _hands[Game.apple_side].to_global(Vector3(0, -0.06, -0.1))
	else:
		_apple.global_position = Vector3(apple_x, 0.945, APPLE_Z)

	var cam_target := _body.global_position + Vector3(1.5, 2.3, 2.3)
	_cam.global_position = _cam.global_position.lerp(cam_target, t)
	_cam.look_at(_body.global_position + Vector3(0, 0.9, -1.3))

	_alert.visible = Game.fire_arm >= 0
	if _alert.visible:
		_alert.text = "!! DOR NO BRAÇO %s !!\nAvise os Braços: tem fogo lá dentro!" % Game.SIDE_NAMES[Game.fire_arm].to_upper()
	_alert.modulate.a = 0.5 + 0.5 * absf(sin(_time * 6.0))
	var steps_left := roundi((Game.body_z - Game.REACH_Z) / Game.STEP)
	_info.text = "Vida: %d   Maçãs: %d\nPassos até a mesa: %d\nBraços: %s\nPernas: %s" % [
		Game.health, Game.apples, steps_left,
		"conectados" if Game.arms_online else "esperando...",
		"conectadas" if Game.legs_online else "ninguém (corpo já na mesa)",
	]


func _refresh() -> void:
	_orders.text = "Braços: %s\nPernas: %s" % [
		Game.command_arms if Game.command_arms != "" else "-",
		Game.command_legs if Game.command_legs != "" else "-",
	]


func _send(target: String, text: String) -> void:
	if text.strip_edges() != "":
		Game.send_command(target, text.strip_edges())


# --- Mundo -------------------------------------------------------------------

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.78, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	_box(Vector3(12, 0.1, 12), Vector3(0, -0.05, -2), Color(0.45, 0.4, 0.35), self)  # chão
	_box(Vector3(1.4, 0.875, 0.6), Vector3(0, 0.4375, TABLE_Z), Color(0.55, 0.35, 0.2), self)  # mesa
	_box(Vector3(1.4, 0.02, 0.08), Vector3(0, 0.01, Game.START_Z - 0.3), Color(1, 1, 1), self)  # linha de saída

	_apple = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.14
	sphere.material = _mat(Color(0.85, 0.1, 0.1))
	_apple.mesh = sphere
	add_child(_apple)

	_build_body()

	_cam = Camera3D.new()
	_cam.fov = 65
	add_child(_cam)
	_cam.position = Vector3(1.5, 2.3, Game.body_z + 2.3)


func _build_body() -> void:
	var skin := Color(0.95, 0.78, 0.62)
	var shirt := Color(0.2, 0.35, 0.6)
	var pants := Color(0.25, 0.25, 0.3)
	_body = Node3D.new()
	add_child(_body)

	_box(Vector3(0.5, 0.6, 0.25), Vector3(0, 1.15, 0), shirt, _body)  # tronco
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.15
	head_mesh.height = 0.3
	head_mesh.material = _mat(skin)
	head.mesh = head_mesh
	head.position = Vector3(0, 1.65, 0)
	_body.add_child(head)
	for x in [-0.06, 0.06]:
		_box(Vector3(0.04, 0.04, 0.02), Vector3(x, 1.68, -0.14), Color(0.1, 0.1, 0.1), _body)  # olhos

	for s in 2:
		# Braço: ombro -> braço -> mão -> 5 dedos
		var shoulder := Node3D.new()
		shoulder.position = Vector3(SIDE_X[s] * 0.33, 1.4, -0.05)
		shoulder.rotation_degrees.x = ARM_DOWN
		_body.add_child(shoulder)
		_box(Vector3(0.1, 0.1, 0.8), Vector3(0, 0, -0.4), skin, shoulder)
		var hand := Node3D.new()
		hand.position = Vector3(0, 0, -0.85)
		shoulder.add_child(hand)
		_box(Vector3(0.14, 0.04, 0.12), Vector3.ZERO, skin, hand)
		for i in 5:
			var pivot := Node3D.new()
			pivot.position = Vector3(-0.056 + i * 0.028, 0, -0.06)
			hand.add_child(pivot)
			_box(Vector3(0.022, 0.022, 0.09), Vector3(0, 0, -0.045), skin, pivot)
			_fingers[s].append(pivot)
		_shoulders.append(shoulder)
		_hands.append(hand)

		# Perna: quadril -> perna -> pé
		var hip := Node3D.new()
		hip.position = Vector3(SIDE_X[s] * 0.12, 0.85, 0)
		_body.add_child(hip)
		_box(Vector3(0.14, 0.85, 0.14), Vector3(0, -0.425, 0), pants, hip)
		_box(Vector3(0.14, 0.06, 0.24), Vector3(0, -0.82, -0.05), Color(0.15, 0.1, 0.08), hip)
		_hips.append(hip)


func _box(size: Vector3, pos: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	parent.add_child(inst)
	return inst


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


# --- Painel (HUD) ------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	panel.add_child(box)

	var title := Label.new()
	title.text = "VOCÊ É A CABEÇA"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var help := Label.new()
	help.text = "Só você vê o mundo. Leve o corpo até a mesa\ne pegue a maçã com a mão do lado certo."
	box.add_child(help)

	_add_group(box, "Ordens para os BRAÇOS", "arms", ARM_COMMANDS)
	_add_group(box, "Ordens para as PERNAS", "legs", LEG_COMMANDS)

	var row := HBoxContainer.new()
	box.add_child(row)
	_custom = LineEdit.new()
	_custom.placeholder_text = "Outra ordem..."
	_custom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_custom)
	for target in ["arms", "legs"]:
		var send := Button.new()
		send.text = "Braços" if target == "arms" else "Pernas"
		send.pressed.connect(func() -> void: _send(target, _custom.text); _custom.clear())
		row.add_child(send)

	_orders = Label.new()
	box.add_child(_orders)

	_info = Label.new()
	_info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_info.offset_left = -360
	_info.offset_right = -16
	_info.offset_top = 16
	_info.add_theme_font_size_override("font_size", 20)
	layer.add_child(_info)

	_alert = Label.new()
	_alert.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_alert.add_theme_font_size_override("font_size", 34)
	_alert.add_theme_color_override("font_color", Color(1, 0.15, 0.1))
	_alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert.offset_left = 400
	_alert.offset_bottom = -260
	layer.add_child(_alert)

	_log = Label.new()
	_log.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_log.add_theme_font_size_override("font_size", 22)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.offset_left = 400
	_log.offset_bottom = -24
	layer.add_child(_log)


func _add_group(parent: Control, label_text: String, target: String, commands: Array) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	parent.add_child(label)
	var grid := GridContainer.new()
	grid.columns = 2
	parent.add_child(grid)
	for text in commands:
		var btn := Button.new()
		btn.text = text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_send.bind(target, text))
		grid.add_child(btn)
