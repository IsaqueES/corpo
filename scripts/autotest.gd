extends Node
## Teste automático do protótipo, sem tela. Rode em dois terminais:
##   godot --headless -- --host --autotest
##   godot --headless -- --join --autotest
## O host imprime "AUTOTEST OK" se Braços pegar a maçã e apagar o fogo.

var _time := 0.0
var _pulled := false
var _fired := false
var _saw_fire := false
var _hits := 0


func _ready() -> void:
	Game.state_changed.connect(_on_state)
	var tree := get_tree()  # o menu recarrega a cena quando o host sai
	multiplayer.server_disconnected.connect(func() -> void: tree.quit(0))


func _process(delta: float) -> void:
	_time += delta
	if _time > 20.0:
		print("AUTOTEST FALHOU: tempo esgotado")
		get_tree().quit(1)
		return
	var peer := multiplayer.multiplayer_peer
	var connected := peer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	if connected and not Game.is_head() and not _pulled and _time > 1.0:
		_pulled = true
		Game.pull_lever(Game.ARM_LEVER)  # estica o braço primeiro
		for i in 5:
			Game.pull_lever(i)  # depois fecha os dedos
	if not Game.is_head() and Game.fire and _hits < Game.FIRE_HITS_NEEDED:
		_hits += 1
		Game.hit_fire()


func _on_state() -> void:
	if not Game.is_head():
		return
	if Game.grabbed and not _fired:
		_fired = true
		print("host: pegou a maçã")
		Game.start_fire()
	if Game.fire:
		_saw_fire = true
	elif _saw_fire:
		print("AUTOTEST OK")
		get_tree().quit(0)
