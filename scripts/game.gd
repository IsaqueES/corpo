extends Node
## Estado compartilhado do corpo (autoload "Game").
## O host é a Cabeça e manda em tudo: os outros jogadores pedem mudanças
## e o host envia o estado atualizado para todos.

signal state_changed
signal notice(text: String)

const PORT := 7777
const FINGER_NAMES := ["Polegar", "Indicador", "Médio", "Anelar", "Mínimo"]
const ARM_LEVER := 5
const FIRE_HITS_NEEDED := 5
const MAX_HEALTH := 100.0
const FIRE_DAMAGE_PER_SEC := 4.0
const GRAB_RESET_TIME := 4.0

var fingers := [false, false, false, false, false]
var arm_extended := false
var command := ""
var fire := false
var fire_hits := 0
var health := MAX_HEALTH
var apples := 0
var grabbed := false

var _fire_timer := 0.0
var _reset_timer := 0.0
var _sync_timer := 0.0


func _ready() -> void:
	_setup_input()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	set_process(false)


# --- Conexão ---------------------------------------------------------------

func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	reset_round(true)
	set_process(true)
	return OK


func join_game(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func leave() -> void:
	set_process(false)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func is_head() -> bool:
	return multiplayer.is_server()


func _on_peer_connected(_id: int) -> void:
	if is_head():
		notice.emit("Os Braços entraram no corpo.")
		_broadcast()


func _on_peer_disconnected(_id: int) -> void:
	if is_head():
		notice.emit("Os Braços saíram do jogo.")


# --- Ações (qualquer jogador chama; o host decide) -------------------------

func send_command(text: String) -> void:
	if not is_head():
		return
	command = text
	_broadcast()


func pull_lever(index: int) -> void:
	if is_head():
		_apply_lever(index)
	else:
		_request_lever.rpc_id(1, index)


func hit_fire() -> void:
	if is_head():
		_apply_fire_hit()
	else:
		_request_fire_hit.rpc_id(1)


func start_fire() -> void:
	if not is_head() or fire:
		return
	fire = true
	fire_hits = 0
	_notice.rpc("DOR NA MÃO! Tem fogo no setor dos Braços.")
	_broadcast()


@rpc("any_peer", "reliable")
func _request_lever(index: int) -> void:
	if is_head():
		_apply_lever(index)


@rpc("any_peer", "reliable")
func _request_fire_hit() -> void:
	if is_head():
		_apply_fire_hit()


func _apply_lever(index: int) -> void:
	if fire or grabbed:
		return
	if index == ARM_LEVER:
		arm_extended = not arm_extended
	elif index >= 0 and index < FINGER_NAMES.size():
		fingers[index] = not fingers[index]
		# Só pega a maçã se a mão fechar com o braço já esticado.
		if arm_extended and _all_fingers_closed():
			grabbed = true
			apples += 1
			_reset_timer = GRAB_RESET_TIME
			_notice.rpc("Pegou a maçã! Total: %d" % apples)
	else:
		return
	_broadcast()


func _apply_fire_hit() -> void:
	if not fire:
		return
	fire_hits += 1
	if fire_hits >= FIRE_HITS_NEEDED:
		fire = false
		fire_hits = 0
		_fire_timer = randf_range(20.0, 35.0)
		_notice.rpc("Fogo apagado. A dor passou.")
	_broadcast()


func _all_fingers_closed() -> bool:
	for closed in fingers:
		if not closed:
			return false
	return true


# --- Simulação (só no host) ------------------------------------------------

func reset_round(full: bool) -> void:
	fingers = [false, false, false, false, false]
	arm_extended = false
	grabbed = false
	command = ""
	if full:
		health = MAX_HEALTH
		apples = 0
		fire = false
		fire_hits = 0
	_fire_timer = randf_range(15.0, 25.0)
	_broadcast()


func _process(delta: float) -> void:
	if grabbed:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			reset_round(false)
	if fire:
		health = maxf(health - FIRE_DAMAGE_PER_SEC * delta, 0.0)
		if health <= 0.0:
			_notice.rpc("O personagem desmaiou de dor! Recomeçando.")
			reset_round(true)
			return
		_sync_timer -= delta
		if _sync_timer <= 0.0:
			_sync_timer = 0.5
			_broadcast()
	elif not grabbed:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			start_fire()


# --- Rede --------------------------------------------------------------------

func _broadcast() -> void:
	_sync.rpc(_pack())
	state_changed.emit()


func _pack() -> Dictionary:
	return {
		"fingers": fingers, "arm": arm_extended, "command": command,
		"fire": fire, "fire_hits": fire_hits, "health": health,
		"apples": apples, "grabbed": grabbed,
	}


@rpc("authority", "call_remote", "reliable")
func _sync(s: Dictionary) -> void:
	fingers = s.fingers
	arm_extended = s.arm
	command = s.command
	fire = s.fire
	fire_hits = s.fire_hits
	health = s.health
	apples = s.apples
	grabbed = s.grabbed
	state_changed.emit()


@rpc("authority", "call_local", "reliable")
func _notice(text: String) -> void:
	notice.emit(text)


# --- Controles ---------------------------------------------------------------

func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"interact": [KEY_E],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
