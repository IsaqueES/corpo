extends "res://scripts/sector_view.gd"
## Setor das Pernas: duas salas (perna esquerda e direita).
## Um passo = LEVANTAR, PRA FRENTE e abaixar de novo.
## Se as duas pernas ficarem levantadas ao mesmo tempo, o corpo cai.


func _setup() -> void:
	part = "legs"
	title = "VOCÊ CONTROLA AS PERNAS"
	help = "Um passo: LEVANTAR, PRA FRENTE e depois abaixar a perna.\nNunca levante as duas pernas juntas! O portal atrás leva à outra perna."
	room_names = ["PERNA ESQUERDA", "PERNA DIREITA"]
	lever_names = Game.LEG_LEVERS
	flesh = Color(0.45, 0.22, 0.32)


func _is_on(s: int, index: int) -> bool:
	var leg: Dictionary = Game.legs[s]
	return leg.lifted if index == Game.LEG_LIFT else leg.forward


func _command() -> String:
	return Game.command_legs
