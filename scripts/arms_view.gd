extends Node3D
## Setor dos Braços: uma sala dentro do corpo, cheia de alavancas.
## Daqui não dá para ver o mundo lá fora; siga as ordens da Cabeça.

const SPEED := 4.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.0025
const LEVER_NAMES := ["Polegar", "Indicador", "Médio", "Anelar", "Mínimo", "BRAÇO"]
const LEVER_X := [-2.5, -1.5, -0.5, 0.5, 1.5, 2.9]
const LEVER_OFF := -35.0
const LEVER_ON := 35.0

var _player: CharacterBody3D
var _camera: Camera3D
var _ray: RayCast3D
var _handles: Array[Node3D] = []
var _knob_mats: Array[StandardMaterial3D] = []
var _command_label: Label3D
var _lamp_mat: StandardMaterial3D
var _fire: StaticBody3D
var _fire_light: OmniLight3D
var _fire_label: Label3D
var _hint: Label
var _info: Label
var _log: Label
var _last_command := ""
var _blink := 0.0
var _time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_build_room()
	_build_levers()
	_build_fire()
	_build_player()
	_build_hud()
	Game.state_changed.connect(_refresh)
	Game.notice.connect(func(text: String) -> void: _log.text = text)
	_refresh()


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
	var t := clampf(delta * 10.0, 0.0, 1.0)
	for i in _handles.size():
		var on: bool = Game.arm_extended if i == Game.ARM_LEVER else Game.fingers[i]
		var target := LEVER_ON if on else LEVER_OFF
		_handles[i].rotation_degrees.x = lerpf(_handles[i].rotation_degrees.x, target, t)
		_knob_mats[i].albedo_color = Color(0.2, 0.85, 0.3) if on else Color(0.85, 0.2, 0.2)

	# Lâmpada pisca quando chega ordem nova.
	_blink = maxf(_blink - delta, 0.0)
	var lit := _blink > 0.0 and fmod(_time, 0.4) < 0.2
	_lamp_mat.emission_energy_multiplier = 4.0 if lit else 0.2

	if Game.fire:
		var flicker := 0.85 + 0.25 * sin(_time * 23.0) * sin(_time * 7.0)
		_fire.scale = Vector3(1, flicker, 1)
		_fire_light.light_energy = 2.0 * flicker
		_fire_label.text = "FOGO! Aperte E (%d/%d)" % [Game.fire_hits, Game.FIRE_HITS_NEEDED]

	_update_aim()
	_info.text = "VOCÊ CONTROLA OS BRAÇOS\nVida do corpo: %d" % Game.health


func _update_aim() -> void:
	var target := _ray.get_collider() if _ray.is_colliding() else null
	if target and target.has_meta("lever"):
		var i: int = target.get_meta("lever")
		_hint.text = "E: puxar alavanca %s" % LEVER_NAMES[i]
		if Game.fire:
			_hint.text = "Alavancas travadas pelo fogo!"
		if Input.is_action_just_pressed("interact"):
			Game.pull_lever(i)
	elif target and target.has_meta("fire"):
		_hint.text = "E: apagar o fogo"
		if Input.is_action_just_pressed("interact"):
			Game.hit_fire()
	else:
		_hint.text = ""


func _refresh() -> void:
	var cmd := Game.command if Game.command != "" else "(nenhuma)"
	_command_label.text = "ORDEM DA CABEÇA:\n%s" % cmd
	if Game.command != _last_command:
		_last_command = Game.command
		if Game.command != "":
			_blink = 3.0
	_fire.visible = Game.fire
	_fire.collision_layer = 1 if Game.fire else 0
	_fire_light.visible = Game.fire


# --- Sala --------------------------------------------------------------------

func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.3, 0.3)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.7, 0)
	light.omni_range = 12.0
	light.light_color = Color(1, 0.85, 0.75)
	add_child(light)

	var flesh := Color(0.55, 0.22, 0.22)
	_solid(Vector3(8, 0.2, 8), Vector3(0, -0.1, 0), flesh)  # chão
	_solid(Vector3(8, 0.2, 8), Vector3(0, 3.1, 0), flesh.darkened(0.3))  # teto
	_solid(Vector3(8, 3, 0.2), Vector3(0, 1.5, -4), flesh.darkened(0.15))
	_solid(Vector3(8, 3, 0.2), Vector3(0, 1.5, 4), flesh.darkened(0.15))
	_solid(Vector3(0.2, 3, 8), Vector3(-4, 1.5, 0), flesh.darkened(0.15))
	_solid(Vector3(0.2, 3, 8), Vector3(4, 1.5, 0), flesh.darkened(0.15))
	# "Veias" decorativas
	for y in [0.6, 2.4]:
		_mesh(Vector3(7.8, 0.12, 0.12), Vector3(0, y, 3.85), Color(0.35, 0.05, 0.1), self)
		_mesh(Vector3(0.12, 0.12, 7.8), Vector3(-3.85, y, 0), Color(0.15, 0.1, 0.45), self)

	_command_label = Label3D.new()
	_command_label.position = Vector3(0, 2.4, -3.85)
	_command_label.font_size = 72
	_command_label.pixel_size = 0.004
	_command_label.modulate = Color(1, 0.95, 0.6)
	add_child(_command_label)

	var lamp := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	_lamp_mat = StandardMaterial3D.new()
	_lamp_mat.albedo_color = Color(1, 0.85, 0.2)
	_lamp_mat.emission_enabled = true
	_lamp_mat.emission = Color(1, 0.85, 0.2)
	sphere.material = _lamp_mat
	lamp.mesh = sphere
	lamp.position = Vector3(-3.2, 2.4, -3.8)
	add_child(lamp)


func _build_levers() -> void:
	for i in LEVER_NAMES.size():
		var lever := StaticBody3D.new()
		lever.position = Vector3(LEVER_X[i], 0, -3.3)
		lever.set_meta("lever", i)
		add_child(lever)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 1.6, 0.6)
		shape.shape = box
		shape.position.y = 0.8
		lever.add_child(shape)

		var big := i == Game.ARM_LEVER
		_mesh(Vector3(0.5 if big else 0.4, 0.8, 0.3), Vector3(0, 0.4, 0), Color(0.85, 0.82, 0.75), lever)
		var handle := Node3D.new()
		handle.position.y = 0.8
		handle.rotation_degrees.x = LEVER_OFF
		lever.add_child(handle)
		_mesh(Vector3(0.08, 0.6, 0.08), Vector3(0, 0.3, 0), Color(0.9, 0.88, 0.8), handle)
		var knob := _mesh(Vector3(0.18, 0.18, 0.18), Vector3(0, 0.62, 0), Color(0.85, 0.2, 0.2), handle)
		_handles.append(handle)
		_knob_mats.append(knob.mesh.material)

		var label := Label3D.new()
		label.text = LEVER_NAMES[i]
		label.position = Vector3(0, 1.75, 0)
		label.font_size = 48
		label.pixel_size = 0.004
		lever.add_child(label)


func _build_fire() -> void:
	_fire = StaticBody3D.new()
	_fire.position = Vector3(0, 0, -2.4)
	_fire.set_meta("fire", true)
	add_child(_fire)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.2, 0.6)
	shape.shape = box
	shape.position.y = 0.6
	_fire.add_child(shape)
	var outer := _mesh(Vector3(1.0, 1.0, 0.5), Vector3(0, 0.5, 0), Color(1, 0.35, 0), _fire)
	var inner := _mesh(Vector3(0.5, 1.3, 0.3), Vector3(0, 0.65, 0), Color(1, 0.85, 0.1), _fire)
	for m in [outer.mesh.material, inner.mesh.material]:
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 2.0

	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(0, 1.0, -2.0)
	_fire_light.light_color = Color(1, 0.5, 0.1)
	_fire_light.omni_range = 5.0
	add_child(_fire_light)

	_fire_label = Label3D.new()
	_fire_label.position = Vector3(0, 1.25, 0.35)
	_fire_label.font_size = 56
	_fire_label.pixel_size = 0.004
	_fire_label.modulate = Color(1, 0.6, 0.2)
	_fire_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_fire.add_child(_fire_label)


func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.position = Vector3(0, 0.1, 2.5)
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


# --- HUD ---------------------------------------------------------------------

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

	var help := Label.new()
	help.text = "Você não vê lá fora. Ouça a Cabeça e puxe as alavancas.\nClique: controlar a câmera · WASD: andar · E: usar · Esc: soltar o mouse"
	help.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help.offset_left = -560
	help.offset_top = 16
	layer.add_child(help)


func _full_label(parent: Node, size: int) -> Label:
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label
