extends Node
## Menu inicial: hospedar (Cabeça) ou entrar (Braços).

const HeadView := preload("res://scripts/head_view.gd")
const ArmsView := preload("res://scripts/arms_view.gd")

var _menu: Control
var _status: Label
var _ip: LineEdit


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)
	_build_menu()

	# Atalhos para testes: godot -- --host  /  godot -- --join
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args:
		add_child(preload("res://scripts/autotest.gd").new())
	if "--host" in args:
		_on_host()
	elif "--join" in args:
		_on_join()


func _build_menu() -> void:
	_menu = CenterContainer.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_menu)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 12)
	_menu.add_child(box)

	var title := Label.new()
	title.text = "CORPO (protótipo)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)

	var host_btn := Button.new()
	host_btn.text = "Hospedar e ser a CABEÇA"
	host_btn.pressed.connect(_on_host)
	box.add_child(host_btn)

	_ip = LineEdit.new()
	_ip.text = "127.0.0.1"
	_ip.placeholder_text = "IP de quem hospeda"
	box.add_child(_ip)

	var join_btn := Button.new()
	join_btn.text = "Entrar e ser os BRAÇOS"
	join_btn.pressed.connect(_on_join)
	box.add_child(join_btn)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_status)


func _on_host() -> void:
	var err := Game.host_game()
	if err != OK:
		_status.text = "Não deu para hospedar (erro %d). A porta %d já está em uso?" % [err, Game.PORT]
		return
	_start(HeadView)


func _on_join() -> void:
	var err := Game.join_game(_ip.text.strip_edges())
	if err != OK:
		_status.text = "Erro ao conectar (%d)." % err
		return
	_status.text = "Conectando..."


func _on_connected() -> void:
	_start(ArmsView)


func _on_failed() -> void:
	Game.leave()
	_status.text = "Não conectou. Confira o IP e se a Cabeça já hospedou."


func _on_server_gone() -> void:
	Game.leave()
	get_tree().reload_current_scene()


func _start(view: GDScript) -> void:
	_menu.queue_free()
	add_child(view.new())
