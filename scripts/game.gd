extends Node
## Estado compartilhado do corpo (autoload "Game").
## O host é a Cabeça e manda em tudo: os outros jogadores pedem mudanças
## e o host envia o estado atualizado para todos.

signal state_changed
signal notice(text: String)
signal role_denied

const PORT := 7777
const MAX_CLIENTS := 3
const ROLES := ["arms", "legs"]
const SIDE_NAMES := ["esquerdo", "direito"]

const ARM_LEVERS := ["Polegar", "Indicador", "Médio", "Anelar", "Mínimo", "BRAÇO"]
const ARM_EXTEND := 5
const LEG_LEVERS := ["LEVANTAR / ABAIXAR", "PRA FRENTE"]
const LEG_LIFT := 0
const LEG_FORWARD := 1

const STEP := 0.5  # quanto o corpo anda por passo
const START_Z := 0.0  # onde o corpo começa
const REACH_Z := -2.0  # posição em que a mão alcança a maçã (4 passos)

const FIRE_HITS_NEEDED := 5
const MAX_HEALTH := 100.0
const FIRE_DAMAGE_PER_SEC := 4.0
const FALL_DAMAGE := 15.0
const GRAB_RESET_TIME := 4.0

var arms := [_new_arm(), _new_arm()]  # 0 = esquerdo, 1 = direito
var legs := [_new_leg(), _new_leg()]
var body_z := START_Z
var apple_side := 1
var fire_arm := -1  # braço com fogo (-1 = nenhum)
var fire_hits := 0
var health := MAX_HEALTH
var apples := 0
var grabbed := false
var command_arms := ""
var command_legs := ""
var arms_online := false
var legs_online := false
var steps := 0  # passos dados desde o início (só no host)
var last_error := ""  # mostrado no menu depois de voltar a ele

var _roles := {}  # id do jogador -> "arms" ou "legs" (só no host)
var _fire_timer := 0.0
var _reset_timer := 0.0
var _sync_timer := 0.0


func _ready() -> void:
	_setup_input()
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	set_process(false)


static func _new_arm() -> Dictionary:
	return {"fingers": [false, false, false, false, false], "extended": false}


static func _new_leg() -> Dictionary:
	return {"lifted": false, "forward": false}


# --- Conexão ---------------------------------------------------------------

func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_roles.clear()
	_update_online()
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


func request_role(role: String) -> void:
	_request_role.rpc_id(1, role)


@rpc("any_peer", "reliable")
func _request_role(role: String) -> void:
	if not is_head():
		return
	var id := multiplayer.get_remote_sender_id()
	if role not in ROLES or role in _roles.values():
		_role_denied.rpc_id(id)
		return
	_roles[id] = role
	_update_online()
	if role == "legs" and not grabbed:
		# Com as Pernas no jogo, o corpo precisa andar até a mesa.
		body_z = START_Z
		legs = [_new_leg(), _new_leg()]
	_notice.rpc("%s entraram no corpo." % _role_label(role))
	_broadcast()


@rpc("authority", "reliable")
func _role_denied() -> void:
	role_denied.emit()


func _on_peer_disconnected(id: int) -> void:
	if not is_head() or not _roles.has(id):
		return
	var role: String = _roles[id]
	_roles.erase(id)
	_update_online()
	_notice.rpc("%s saíram do jogo." % _role_label(role))
	_broadcast()


func _update_online() -> void:
	arms_online = "arms" in _roles.values()
	legs_online = "legs" in _roles.values()


func _role_label(role: String) -> String:
	return "Os Braços" if role == "arms" else "As Pernas"


# --- Ações (qualquer jogador chama; o host decide) -------------------------

func send_command(target: String, text: String) -> void:
	if not is_head():
		return
	if target == "arms":
		command_arms = text
	else:
		command_legs = text
	_broadcast()


func pull_lever(part: String, side: int, index: int) -> void:
	if is_head():
		_apply_lever(part, side, index)
	else:
		_request_lever.rpc_id(1, part, side, index)


func hit_fire() -> void:
	if is_head():
		_apply_fire_hit()
	else:
		_request_fire_hit.rpc_id(1)


func start_fire(side := -1) -> void:
	if not is_head() or fire_arm >= 0:
		return
	fire_arm = side if side >= 0 else randi() % 2
	fire_hits = 0
	_notice.rpc("DOR NO BRAÇO %s! Tem fogo lá dentro." % SIDE_NAMES[fire_arm].to_upper())
	_broadcast()


@rpc("any_peer", "reliable")
func _request_lever(part: String, side: int, index: int) -> void:
	if is_head() and _roles.get(multiplayer.get_remote_sender_id()) == part:
		_apply_lever(part, side, index)


@rpc("any_peer", "reliable")
func _request_fire_hit() -> void:
	if is_head() and _roles.get(multiplayer.get_remote_sender_id()) == "arms":
		_apply_fire_hit()


func _apply_lever(part: String, side: int, index: int) -> void:
	if side < 0 or side > 1 or grabbed:
		return
	if part == "arms":
		_apply_arm(side, index)
	elif part == "legs":
		_apply_leg(side, index)
	_broadcast()


func _apply_arm(side: int, index: int) -> void:
	if fire_arm == side:
		return
	var arm: Dictionary = arms[side]
	if index == ARM_EXTEND:
		arm.extended = not arm.extended
		return
	if index < 0 or index >= 5:
		return
	arm.fingers[index] = not arm.fingers[index]
	# Só pega a maçã se a mão fechar com o braço já esticado.
	if not (arm.extended and _all_closed(arm.fingers)):
		return
	if side != apple_side:
		_notice.rpc("A mão %s pegou o ar. A maçã está do outro lado!" % _hand_name(side))
	elif body_z > REACH_Z + 0.01:
		_notice.rpc("A mão fechou longe da maçã. Cheguem mais perto da mesa.")
	else:
		grabbed = true
		apples += 1
		_reset_timer = GRAB_RESET_TIME
		_notice.rpc("Pegou a maçã! Total: %d" % apples)


func _apply_leg(side: int, index: int) -> void:
	var leg: Dictionary = legs[side]
	if index == LEG_LIFT:
		if not leg.lifted:
			leg.lifted = true
			if legs[1 - side].lifted:
				_fall()
		else:
			leg.lifted = false
			if leg.forward:
				leg.forward = false
				_take_step()
	elif index == LEG_FORWARD and leg.lifted:
		leg.forward = not leg.forward


func _take_step() -> void:
	if body_z - STEP < REACH_Z - 0.01:
		_notice.rpc("O pé bateu na mesa! Já estão perto o bastante.")
		return
	body_z -= STEP
	steps += 1


func _fall() -> void:
	legs = [_new_leg(), _new_leg()]
	_notice.rpc("As duas pernas levantaram e o corpo caiu! (-%d de vida)" % FALL_DAMAGE)
	_damage(FALL_DAMAGE)


func _apply_fire_hit() -> void:
	if fire_arm < 0:
		return
	fire_hits += 1
	if fire_hits >= FIRE_HITS_NEEDED:
		fire_arm = -1
		fire_hits = 0
		_fire_timer = randf_range(20.0, 35.0)
		_notice.rpc("Fogo apagado. A dor passou.")
	_broadcast()


func _damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		_notice.rpc("O personagem desmaiou! Recomeçando.")
		reset_round(true)


func _all_closed(fingers: Array) -> bool:
	for closed in fingers:
		if not closed:
			return false
	return true


func _hand_name(side: int) -> String:
	return "esquerda" if side == 0 else "direita"


# --- Simulação (só no host) ------------------------------------------------

func reset_round(full: bool) -> void:
	arms = [_new_arm(), _new_arm()]
	legs = [_new_leg(), _new_leg()]
	grabbed = false
	command_arms = ""
	command_legs = ""
	apple_side = randi() % 2
	# Sem ninguém nas Pernas, o corpo já começa na mesa.
	body_z = START_Z if legs_online else REACH_Z
	if full:
		health = MAX_HEALTH
		apples = 0
		fire_arm = -1
		fire_hits = 0
	_fire_timer = randf_range(15.0, 25.0)
	_broadcast()


func _process(delta: float) -> void:
	if grabbed:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			reset_round(false)
	if fire_arm >= 0:
		_damage(FIRE_DAMAGE_PER_SEC * delta)
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
		"arms": arms, "legs": legs, "body_z": body_z, "apple_side": apple_side,
		"fire_arm": fire_arm, "fire_hits": fire_hits, "health": health,
		"apples": apples, "grabbed": grabbed, "command_arms": command_arms,
		"command_legs": command_legs, "arms_online": arms_online,
		"legs_online": legs_online,
	}


@rpc("authority", "call_remote", "reliable")
func _sync(s: Dictionary) -> void:
	arms = s.arms
	legs = s.legs
	body_z = s.body_z
	apple_side = s.apple_side
	fire_arm = s.fire_arm
	fire_hits = s.fire_hits
	health = s.health
	apples = s.apples
	grabbed = s.grabbed
	command_arms = s.command_arms
	command_legs = s.command_legs
	arms_online = s.arms_online
	legs_online = s.legs_online
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
