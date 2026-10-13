extends Node
## Teste automático do protótipo, sem tela. Rode em três terminais, nesta ordem:
##   godot --headless -- --host --autotest
##   godot --headless -- --join --as=legs --autotest
##   godot --headless -- --join --as=arms --autotest
## As Pernas caem uma vez de propósito e depois andam 4 passos até a mesa;
## os Braços pegam a maçã com a mão certa e apagam o fogo.
## O host imprime "AUTOTEST OK" se tudo isso acontecer.

var _time := 0.0
var _walked := false
var _grabbing := false
var _fired := false
var _saw_fire := false
var _hits := 0


func _ready() -> void:
	Game.state_changed.connect(_on_state)
	var tree := get_tree()  # o menu recarrega a cena quando o host sai
	multiplayer.server_disconnected.connect(func() -> void: tree.quit(0))


func _process(delta: float) -> void:
	_time += delta
	if _time > 30.0:
		print("AUTOTEST FALHOU: tempo esgotado (passos=%d vida=%d maçãs=%d)" % [Game.steps, Game.health, Game.apples])
		get_tree().quit(1)
		return
	var peer := multiplayer.multiplayer_peer
	if Game.is_head() or not peer or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	var as_legs := "--as=legs" in OS.get_cmdline_user_args()
	if as_legs and not _walked and Game.legs_online and _time > 1.0:
		_walked = true
		Game.pull_lever("legs", 0, Game.LEG_LIFT)
		Game.pull_lever("legs", 1, Game.LEG_LIFT)  # duas pernas levantadas: cai
		for k in 4:
			var s := k % 2
			Game.pull_lever("legs", s, Game.LEG_LIFT)
			Game.pull_lever("legs", s, Game.LEG_FORWARD)
			Game.pull_lever("legs", s, Game.LEG_LIFT)  # abaixa: dá o passo
	if not as_legs and not _grabbing and Game.arms_online and Game.body_z <= Game.REACH_Z + 0.01:
		_grabbing = true
		var s := Game.apple_side
		Game.pull_lever("arms", s, Game.ARM_EXTEND)  # estica o braço primeiro
		for i in 5:
			Game.pull_lever("arms", s, i)  # depois fecha os dedos
	if not as_legs and Game.fire_arm >= 0 and _hits < Game.FIRE_HITS_NEEDED:
		_hits += 1
		Game.hit_fire()


func _on_state() -> void:
	if not Game.is_head():
		return
	if Game.grabbed and not _fired:
		_fired = true
		print("host: pegou a maçã depois de %d passos (vida %d)" % [Game.steps, Game.health])
		Game.start_fire()
	if Game.fire_arm >= 0:
		_saw_fire = true
	elif _saw_fire:
		var ok := Game.steps >= 4 and Game.health < Game.MAX_HEALTH and Game.apples >= 1
		print("AUTOTEST OK" if ok else "AUTOTEST FALHOU: passos=%d vida=%d" % [Game.steps, Game.health])
		get_tree().quit(0 if ok else 1)
