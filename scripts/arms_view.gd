extends "res://scripts/sector_view.gd"
## Setor dos Braços: duas salas (braço esquerdo e direito) com as alavancas
## dos 5 dedos e do braço. Às vezes surge fogo ("dor") em uma delas.

var _fires: Array[StaticBody3D] = []
var _fire_lights: Array[OmniLight3D] = []
var _fire_labels: Array[Label3D] = []


func _setup() -> void:
	part = "arms"
	title = "VOCÊ CONTROLA OS BRAÇOS"
	help = "Você não vê lá fora. Ouça a Cabeça e puxe as alavancas.\nEstique o braço ANTES de fechar a mão. O portal atrás leva ao outro braço."
	room_names = ["BRAÇO ESQUERDO", "BRAÇO DIREITO"]
	lever_names = Game.ARM_LEVERS


func _is_on(s: int, index: int) -> bool:
	var arm: Dictionary = Game.arms[s]
	return arm.extended if index == Game.ARM_EXTEND else arm.fingers[index]


func _locked(s: int) -> bool:
	return Game.fire_arm == s


func _command() -> String:
	return Game.command_arms


func _status() -> String:
	if Game.fire_arm >= 0 and Game.fire_arm != side:
		return "!! Fogo no %s !!" % room_names[Game.fire_arm].to_lower()
	return ""


func _build_extra(s: int) -> void:
	var fire := StaticBody3D.new()
	fire.position = room_origin(s) + Vector3(0, 0, -2.4)
	fire.set_meta("fire", true)
	add_child(fire)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.2, 0.6)
	shape.shape = box
	shape.position.y = 0.6
	fire.add_child(shape)
	var outer := _mesh(Vector3(1.0, 1.0, 0.5), Vector3(0, 0.5, 0), Color(1, 0.35, 0), fire)
	var inner := _mesh(Vector3(0.5, 1.3, 0.3), Vector3(0, 0.65, 0), Color(1, 0.85, 0.1), fire)
	for m in [outer.mesh.material, inner.mesh.material]:
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 2.0
	_fires.append(fire)

	var light := OmniLight3D.new()
	light.position = room_origin(s) + Vector3(0, 1.0, -2.0)
	light.light_color = Color(1, 0.5, 0.1)
	light.omni_range = 5.0
	add_child(light)
	_fire_lights.append(light)

	var label := _label3d("", 56, Color(1, 0.6, 0.2))
	label.position = Vector3(0, 1.25, 0.35)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fire.add_child(label)
	_fire_labels.append(label)


func _process_extra(_delta: float) -> void:
	if Game.fire_arm < 0:
		return
	var s := Game.fire_arm
	var flicker := 0.85 + 0.25 * sin(_time * 23.0) * sin(_time * 7.0)
	_fires[s].scale = Vector3(1, flicker, 1)
	_fire_lights[s].light_energy = 2.0 * flicker
	_fire_labels[s].text = "FOGO! Aperte E (%d/%d)" % [Game.fire_hits, Game.FIRE_HITS_NEEDED]


func _refresh_extra() -> void:
	for s in 2:
		var on := Game.fire_arm == s
		_fires[s].visible = on
		_fires[s].collision_layer = 1 if on else 0
		_fire_lights[s].visible = on


func _aim_extra(target: Object) -> bool:
	if target and target.has_meta("fire"):
		_hint.text = "E: apagar o fogo"
		if Input.is_action_just_pressed("interact"):
			Game.hit_fire()
		return true
	return false
