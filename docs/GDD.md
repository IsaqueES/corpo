# GDD: Documento de Design do Jogo (1 página)

**Nome provisório:** *Corpo* · **Engine:** Godot 4 (GDScript) · **Plataforma:** PC (Steam), compatível com Steam Deck
**Gênero:** co-op online caótico (*friendslop*), referências: PEAK, R.E.P.O., Keep Talking and Nobody Explodes, Lovers in a Dangerous Spacetime.
**Preço sugerido:** US$ 4,99 a 7,99.

## A ideia
Quatro amigos são a tripulação de **um corpo humano**. Cada um anda por dentro do corpo, como se fosse uma nave cheia de veias, alavancas e painéis, e controla uma parte dele. Só juntos conseguem fazer o personagem andar, pegar coisas, comer e sobreviver.

## Os 4 papéis
| Jogador | Parte | Faz o quê |
|---|---|---|
| 1 | **Cabeça** (cérebro, olhos, boca, ouvidos) | É o único que **vê o mundo lá fora**. Manda comandos para os outros ("fechar a mão", "passo para frente") e avisa sobre falhas (dor, infecção, fome). Fala pela boca do personagem. |
| 2 | **Tronco** (coração, pulmões, fígado, estômago) | Mantém o corpo funcionando: ritmo do coração, respiração, digestão, distribuir energia e sangue para os outros setores. |
| 3 | **Braços** (articulações, punhos, dedos) | Executa movimentos dos braços e mãos com alavancas e painéis por articulação e dedo. |
| 4 | **Pernas** (articulações, joelhos, pés) | Faz o corpo andar, correr, pular e manter o equilíbrio. |

## Regras centrais
- **Acordado:** os jogadores **não podem se encontrar**. Cada um fica no seu setor e só se comunica por voz (o "sistema nervoso"). A Cabeça vê tudo; os outros só veem o próprio setor, então dependem das ordens dela.
- **Falhas no corpo:** dor, infecção, fome, cansaço e sustos aparecem como problemas físicos dentro dos setores (fogo, vazamento, bactérias, válvula travada) que precisam ser consertados.
- **Dormindo:** os quatro vão para o **sonho** do personagem. Lá podem se ver, conversar com calma e gastar o dinheiro ganho com tarefas numa **loja de buffs**.
- **Objetivo atual:** manter o personagem vivo.

## Ideias de objetivo e loop (escolher 1)
1. **⭐ Sobreviver à semana (recomendado).** Cada partida é **um dia** da vida do personagem, com uma agenda (acordar, atravessar a rua, ir ao trabalho, almoçar, voltar para casa). Cumprir a agenda dá dinheiro; à noite vem o sonho e a loja. Os dias ficam mais difíceis até o domingo. Encaixa no sono que já existe e dá partidas curtas de 10 a 20 min.
2. **Missão de vida.** Uma meta grande (passar na entrevista de emprego, ganhar a corrida, conquistar o crush) dividida em fases.
3. **Doença chefe.** Um vírus cresce dentro do corpo; é preciso sobreviver N dias e chegar ao hospital antes que ele domine os setores.
4. **Da infância à velhice.** Cada fase é uma idade; o corpo muda (bebê desajeitado, idoso com articulações fracas).
5. **Modo caos infinito.** Sobreviver o máximo de tempo num mundo cada vez mais perigoso, com placar.

## Riscos de design
- **Exigir 4 pessoas:** muitos grupos têm 2 ou 3. Solução: com menos jogadores, um jogador assume 2 setores ou um setor fica no "piloto automático" com falhas mais frequentes.
- **Cabeça como gargalo:** se só a Cabeça decide, os outros ficam esperando ordens. Cada setor precisa de tarefas próprias e constantes (Tronco é sempre ocupado; Braços e Pernas também consertam falhas).
- **Cabeça muito estressante ou chata:** pode ser o papel mais legal ou o mais cansativo. Testar cedo.
- **Aprender 4 jogos diferentes:** cada setor é quase um minijogo. Precisa de tutorial curto por papel e controles muito claros.
- **Escopo:** 4 interiores, falhas, mundo externo e sonho é muito conteúdo. Começar com o mínimo de cada.
- **Depende da voz:** sem conversa o jogo não funciona. No protótipo usar Discord; depois voz no jogo.

## Arte e assets
- Low-poly com cores fortes; dentro do corpo, visual "orgânico-industrial" (veias como canos, alavancas de osso).
- Modelos 3D (personagem principal, NPCs, objetos) em **.glb ou .gltf** em `assets/characters/`, `assets/props/`, `assets/organs/`.
- Assets grátis com licença comercial: Kenney.nl, Quaternius, Poly Pizza.

## Tecnologia
Multiplayer de alto nível do Godot com o host como servidor; **GodotSteam** para lobby, convites, rede P2P e conquistas. O mundo externo e o corpo são simulados no host; cada setor é uma cena separada.

## Fora do escopo (v1)
Mais de 4 jogadores, partidas com estranhos, mundo aberto, campanha longa.
