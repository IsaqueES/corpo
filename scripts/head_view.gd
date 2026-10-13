extends Node3D
## O que a Cabeça vê: o mundo lá fora e o painel de ordens.
## Só a Cabeça enxerga a mão e a maçã; os Braços dependem das ordens dela.

const COMMANDS := [
	"Estique o braço",
	"Recolha o braço",
	"Feche a mão",
	"Abra a mão",
	"Apague o fogo!",
]
const ARM_DOWN := -75.0
const ARM_FORWARD := -26.6
const FINGER_CLOSED := -100.0
const APPLE_HOME := Vector3(0.3, 0.945, -0.98)

var _shoulder: Node3D
var _hand: Node3D
var _fingers: Array[Node3D] = []
var _apple: MeshInstance3D
var _alert: Label
var _info: Label
var _order: Label
var _log: Label
var _custom: LineEdit
var _time := 0.0


func _ready() -> void:
	_build_world()
	_build_hud()
	Game.state_changed.connect(_refresh)
	Game.notice.connect(_on_notice)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	var t := clampf(delta * 6.0, 0.0, 1.0)
	var arm_target := ARM_FORWARD if Game.arm_extended else ARM_DOWN
	_shoulder.rotation_degrees.x = lerpf(_shoulder.rotation_degrees.x, arm_target, t)
	for i in _fingers.size():
		var target := FINGER_CLOSED if Game.fingers[i] else 0.0
		_fingers[i].rotation_degrees.x = lerpf(_fingers[i].rotation_degrees.x, target, t)

	if Game.grabbed:
		_apple.global_position = _hand.to_global(Vector3(0, -0.06, -0.1))
	else:
		_apple.global_position = APPLE_HOME

	_alert.visible = Game.fire
	_alert.modulate.a = 0.5 + 0.5 * absf(sin(_time * 6.0))
	var arms_online := "conectados" if multiplayer.get_peers().size() > 0 else "esperando..."
	_info.text = "Vida: %d   Maçãs: %d\nBraços: %s" % [Game.health, Game.apples, arms_online]


func _refresh() -> void:
	_order.text = "Ordem atual: %s" % (Game.command if Game.command != "" else "(nenhuma)")


func _on_notice(text: String) -> void:
	_log.text = text


func _send(text: String) -> void:
	if text.strip_edges() != "":
		Game.send_command(text.strip_edges())


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

	_box(Vector3(10, 0.1, 10), Vector3(0, -0.05, 0), Color(0.45, 0.4, 0.35))  # chão
	_box(Vector3(0.8, 0.875, 0.6), Vector3(0.3, 0.4375, -1.15), Color(0.55, 0.35, 0.2))  # mesa

	_apple = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.07
	sphere.height = 0.14
	sphere.material = _mat(Color(0.85, 0.1, 0.1))
	_apple.mesh = sphere
	add_child(_apple)
	_apple.global_position = APPLE_HOME

	# Braço: ombro -> braço -> mão -> 5 dedos
	_shoulder = Node3D.new()
	_shoulder.position = Vector3(0.3, 1.4, -0.05)
	_shoulder.rotation_degrees.x = ARM_DOWN
	add_child(_shoulder)
	var skin := Color(0.95, 0.78, 0.62)
	_box(Vector3(0.1, 0.1, 0.8), Vector3(0, 0, -0.4), skin, _shoulder)

	_hand = Node3D.new()
	_hand.position = Vector3(0, 0, -0.85)
	_shoulder.add_child(_hand)
	_box(Vector3(0.14, 0.04, 0.12), Vector3.ZERO, skin, _hand)
	for i in 5:
		var pivot := Node3D.new()
		pivot.position = Vector3(-0.056 + i * 0.028, 0, -0.06)
		_hand.add_child(pivot)
		_box(Vector3(0.022, 0.022, 0.09), Vector3(0, 0, -0.045), skin, pivot)
		_fingers.append(pivot)

	var cam := Camera3D.new()
	cam.fov = 70
	add_child(cam)
	cam.position = Vector3(-0.6, 1.9, 0.5)
	cam.look_at(Vector3(0.3, 1.0, -0.8))


func _box(size: Vector3, pos: Vector3, color: Color, parent: Node = self) -> MeshInstance3D:
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
	box.custom_minimum_size = Vector2(300, 0)
	panel.add_child(box)

	var title := Label.new()
	title.text = "VOCÊ É A CABEÇA"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var help := Label.new()
	help.text = "Só você vê o mundo. Pegue a maçã\nmandando ordens para os Braços.\nDica: estique o braço ANTES de fechar a mão."
	box.add_child(help)

	for text in COMMANDS:
		var btn := Button.new()
		btn.text = text
		btn.pressed.connect(_send.bind(text))
		box.add_child(btn)

	var row := HBoxContainer.new()
	box.add_child(row)
	_custom = LineEdit.new()
	_custom.placeholder_text = "Outra ordem..."
	_custom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_custom.text_submitted.connect(func(t: String) -> void: _send(t); _custom.clear())
	row.add_child(_custom)
	var send := Button.new()
	send.text = "Enviar"
	send.pressed.connect(func() -> void: _send(_custom.text); _custom.clear())
	row.add_child(send)

	_order = Label.new()
	box.add_child(_order)

	_info = Label.new()
	_info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_info.offset_left = -260
	_info.offset_top = 16
	_info.add_theme_font_size_override("font_size", 20)
	layer.add_child(_info)

	_alert = Label.new()
	_alert.text = "!! DOR NA MÃO !!\nAvise os Braços: tem fogo lá dentro!"
	_alert.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_alert.add_theme_font_size_override("font_size", 36)
	_alert.add_theme_color_override("font_color", Color(1, 0.15, 0.1))
	_alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert.offset_top = 60
	layer.add_child(_alert)

	_log = Label.new()
	_log.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_log.add_theme_font_size_override("font_size", 22)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.offset_bottom = -24
	layer.add_child(_log)
