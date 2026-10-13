extends Node3D
## Base dos setores dentro do corpo (Braços, Pernas).
## Cada setor tem duas salas, esquerda e direita, ligadas por um portal.
## As subclasses dizem quais alavancas existem e o que cada uma mostra.

const SPEED := 4.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.0025
const ROOM_GAP := 30.0  # distância entre as duas salas
const LEVER_OFF := -35.0
const LEVER_ON := 35.0

# Preenchidos pela subclasse em _setup().
var part := ""
var title := ""
var help := ""
var room_names := ["", ""]
var lever_names: Array = []
var flesh := Color(0.55, 0.22, 0.22)

var side := 0  # sala onde o jogador está agora
var _player: CharacterBody3D
var _camera: Camera3D
var _ray: RayCast3D
var _handles := [[], []]
var _knob_mats := [[], []]
var _command_labels: Array[Label3D] = []
var _lamp_mats: Array[StandardMaterial3D] = []
var _hint: Label
var _info: Label
var _log: Label
var _last_command := ""
var _blink := 0.0
var _portal_cooldown := 0.0
var _time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


# --- Para as subclasses ------------------------------------------------------

func _setup() -> void:
	pass


func _is_on(_side: int, _index: int) -> bool:
	return false


func _locked(_side: int) -> bool:
	return false


func _command() -> String:
	return ""


func _status() -> String:
	return ""


func _build_extra(_side: int) -> void:
	pass


func _process_extra(_delta: float) -> void:
	pass


func _refresh_extra() -> void:
	pass


## Retorna true se tratou o objeto que o jogador está mirando.
func _aim_extra(_target: Object) -> bool:
	return false


# --- Montagem ----------------------------------------------------------------

func _ready() -> void:
	_setup()
	_build_env()
	for s in 2:
		_build_room(s)
		_build_levers(s)
		_build_portal(s)
		_build_extra(s)
	_build_player()
	_build_hud()
	Game.state_changed.connect(_refresh)
	Game.notice.connect(func(text: String) -> void: _log.text = text)
	_refresh()


func room_origin(s: int) -> Vector3:
	return Vector3((s * 2 - 1) * ROOM_GAP * 0.5, 0, 0)


func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.3, 0.3)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func _build_room(s: int) -> void:
	var o := room_origin(s)
	var light := OmniLight3D.new()
	light.position = o + Vector3(0, 2.7, 0)
	light.omni_range = 12.0
	light.light_color = Color(1, 0.85, 0.75)
	add_child(light)

	_solid(Vector3(8, 0.2, 8), o + Vector3(0, -0.1, 0), flesh)  # chão
	_solid(Vector3(8, 0.2, 8), o + Vector3(0, 3.1, 0), flesh.darkened(0.3))  # teto
	_solid(Vector3(8, 3, 0.2), o + Vector3(0, 1.5, -4), flesh.darkened(0.15))
	_solid(Vector3(8, 3, 0.2), o + Vector3(0, 1.5, 4), flesh.darkened(0.15))
	_solid(Vector3(0.2, 3, 8), o + Vector3(-4, 1.5, 0), flesh.darkened(0.15))
	_solid(Vector3(0.2, 3, 8), o + Vector3(4, 1.5, 0), flesh.darkened(0.15))
	# "Veias" decorativas
	for y in [0.6, 2.4]:
		_mesh(Vector3(0.12, 0.12, 7.8), o + Vector3(-3.85, y, 0), Color(0.35, 0.05, 0.1), self)
		_mesh(Vector3(0.12, 0.12, 7.8), o + Vector3(3.85, y, 0), Color(0.15, 0.1, 0.45), self)

	var name_label := _label3d(room_names[s], 80, Color(1, 1, 1))
	name_label.position = o + Vector3(0, 2.75, -3.85)
	add_child(name_label)

	var cmd := _label3d("", 60, Color(1, 0.95, 0.6))
	cmd.position = o + Vector3(0, 2.2, -3.85)
	add_child(cmd)
	_command_labels.append(cmd)

	var lamp := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1, 0.85, 0.2)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1, 0.85, 0.2)
	sphere.material = lamp_mat
	lamp.mesh = sphere
	lamp.position = o + Vector3(-3.2, 2.4, -3.8)
	add_child(lamp)
	_lamp_mats.append(lamp_mat)


func _build_levers(s: int) -> void:
	var n := lever_names.size()
	var spacing := minf(2.0, 5.4 / maxf(n - 1, 1))
	for i in n:
		var lever := StaticBody3D.new()
		lever.position = room_origin(s) + Vector3((i - (n - 1) / 2.0) * spacing, 0, -3.3)
		lever.set_meta("lever", Vector2i(s, i))
		add_child(lever)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 1.6, 0.6)
		shape.shape = box
		shape.position.y = 0.8
		lever.add_child(shape)

		_mesh(Vector3(0.4, 0.8, 0.3), Vector3(0, 0.4, 0), Color(0.85, 0.82, 0.75), lever)
		var handle := Node3D.new()
		handle.position.y = 0.8
		handle.rotation_degrees.x = LEVER_OFF
		lever.add_child(handle)
		_mesh(Vector3(0.08, 0.6, 0.08), Vector3(0, 0.3, 0), Color(0.9, 0.88, 0.8), handle)
		var knob := _mesh(Vector3(0.18, 0.18, 0.18), Vector3(0, 0.62, 0), Color(0.85, 0.2, 0.2), handle)
		_handles[s].append(handle)
		_knob_mats[s].append(knob.mesh.material)

		var label := _label3d(lever_names[i], 44, Color(1, 1, 1))
		label.position = Vector3(0, 1.75, 0)
		lever.add_child(label)


func _build_portal(s: int) -> void:
	var o := room_origin(s) + Vector3(0, 0, 3.55)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.75
	torus.outer_radius = 0.95
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.3, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.3, 1)
	mat.emission_energy_multiplier = 2.0
	torus.material = mat
	ring.mesh = torus
	ring.position = o + Vector3(0, 1.1, 0)
	ring.rotation_degrees.x = 90
	add_child(ring)

	var glow := OmniLight3D.new()
	glow.position = o + Vector3(0, 1.1, -0.5)
	glow.light_color = Color(0.6, 0.3, 1)
	glow.omni_range = 3.0
	add_child(glow)

	var label := _label3d("PORTAL para o %s" % room_names[1 - s].to_lower(), 28, Color(0.8, 0.7, 1))
	label.position = o + Vector3(0, 2.3, -0.1)
	label.rotation_degrees.y = 180  # virado para dentro da sala
	add_child(label)

	var area := Area3D.new()
	area.position = o + Vector3(0, 1.1, 0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.0, 0.5)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_portal.bind(s))
	add_child(area)


func _on_portal(body: Node3D, from_side: int) -> void:
	if body != _player or _portal_cooldown > 0.0:
		return
	_portal_cooldown = 0.5
	side = 1 - from_side
	_teleport.call_deferred()


func _teleport() -> void:
	_player.global_position = room_origin(side) + Vector3(0, 0.1, 2.3)
	_player.rotation.y = 0.0
	_player.velocity = Vector3.ZERO


func _build_player() -> void:
	_player = CharacterBody3D.new()
	add_child(_player)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	_player.add_child(shape)

	_camera = Camera3D.new()
	_camera.position.y = 1.6
	_camera.fov = 75
	_player.add_child(_camera)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -2.5)
	_ray.add_exception(_player)
	_camera.add_child(_ray)
	_teleport()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var cross := _full_label(layer, 28)
	cross.text = "+"
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_hint = _full_label(layer, 24)
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_hint.offset_bottom = -90

	_log = _full_label(layer, 22)
	_log.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_log.offset_bottom = -24

	_info = Label.new()
	_info.position = Vector2(16, 16)
	_info.add_theme_font_size_override("font_size", 20)
	layer.add_child(_info)

	var help_label := Label.new()
	help_label.text = help + "\nClique: controlar a câmera · WASD: andar · E: usar · Esc: soltar o mouse"
	help_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help_label.offset_left = -640
	help_label.offset_right = -16
	help_label.offset_top = 16
	layer.add_child(help_label)


# --- Jogo --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_player.rotate_y(-event.relative.x * MOUSE_SENS)
		_camera.rotation.x = clampf(_camera.rotation.x - event.relative.y * MOUSE_SENS, -1.4, 1.4)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if not _player.is_on_floor():
		_player.velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		_player.velocity.y = JUMP_VELOCITY
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (_player.transform.basis * Vector3(input.x, 0, input.y)).normalized()
	_player.velocity.x = dir.x * SPEED
	_player.velocity.z = dir.z * SPEED
	_player.move_and_slide()


func _process(delta: float) -> void:
	_time += delta
	_portal_cooldown = maxf(_portal_cooldown - delta, 0.0)
	var t := clampf(delta * 10.0, 0.0, 1.0)
	for s in 2:
		for i in _handles[s].size():
			var on := _is_on(s, i)
			var handle: Node3D = _handles[s][i]
			handle.rotation_degrees.x = lerpf(handle.rotation_degrees.x, LEVER_ON if on else LEVER_OFF, t)
			_knob_mats[s][i].albedo_color = Color(0.2, 0.85, 0.3) if on else Color(0.85, 0.2, 0.2)

	# Lâmpada pisca quando chega ordem nova.
	_blink = maxf(_blink - delta, 0.0)
	var lit := _blink > 0.0 and fmod(_time, 0.4) < 0.2
	for m in _lamp_mats:
		m.emission_energy_multiplier = 4.0 if lit else 0.2

	_process_extra(delta)
	_update_aim()
	var extra := _status()
	_info.text = "%s\nVocê está no: %s\nVida do corpo: %d%s" % [
		title, room_names[side], Game.health, ("\n" + extra) if extra != "" else ""]


func _update_aim() -> void:
	var target := _ray.get_collider() if _ray.is_colliding() else null
	if target and target.has_meta("lever"):
		var id: Vector2i = target.get_meta("lever")
		if _locked(id.x):
			_hint.text = "Alavancas travadas pelo fogo!"
			return
		_hint.text = "E: puxar alavanca %s" % lever_names[id.y]
		if Input.is_action_just_pressed("interact"):
			Game.pull_lever(part, id.x, id.y)
	elif not _aim_extra(target):
		_hint.text = ""


func _refresh() -> void:
	var cmd := _command()
	for label in _command_labels:
		label.text = "ORDEM DA CABEÇA: %s" % (cmd if cmd != "" else "(nenhuma)")
	if cmd != _last_command:
		_last_command = cmd
		if cmd != "":
			_blink = 3.0
	_refresh_extra()


# --- Ajudantes ---------------------------------------------------------------

func _solid(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	_mesh(size, Vector3.ZERO, color, body)


func _mesh(size: Vector3, pos: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	parent.add_child(inst)
	return inst


func _label3d(text: String, size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.004
	label.modulate = color
	return label


func _full_label(parent: Node, size: int) -> Label:
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label
