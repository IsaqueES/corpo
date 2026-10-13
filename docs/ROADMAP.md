# Roteiro: do zero até a Steam (Godot 4, *Corpo*)

Cada passo é pequeno e **testável**. Marque `[x]` ao terminar.
Dica: no Godot, *Depuração > Personalizar Instâncias de Execução* com 2 instâncias abre 2 janelas para testar o multiplayer sozinho.

## Fase 0: Preparação
- [ ] 1. Instalar o Godot 4 (estável, "Standard") e o Git; criar um repositório no GitHub. **Teste:** primeiro commit enviado.
- [ ] 2. Criar o projeto (Forward+) com as pastas `scenes/`, `scripts/`, `assets/`. **Teste:** abre sem erros.

## Fase 1: Protótipo mínimo, "isso é divertido?" (2 jogadores, cubos e caixas)
O objetivo é testar a ideia com o mínimo de trabalho. Sem arte, sem Steam; a voz é pelo Discord.
- [ ] 3. Menu "Hospedar" e "Entrar" com ENet; o host é a Cabeça, o outro é Braços. **Teste:** 2 janelas conectam.
- [ ] 4. **Cabeça:** tela que mostra o mundo de fora (um boneco simples numa sala com um objeto na mesa). **Teste:** a Cabeça vê o objeto.
- [ ] 5. **Braços:** sala em 1ª pessoa com 5 alavancas (uma por dedo) e 1 alavanca de "esticar braço". **Teste:** andar e puxar alavancas.
- [ ] 6. Alavancas mexem a mão do boneco lá fora, sincronizado pela rede. **Teste:** a Cabeça vê a mão fechar quando Braços puxa as 5 alavancas.
- [ ] 7. Painel da Cabeça com 1 comando ("fechar a mão") que acende uma luz na sala de Braços. **Teste:** pegar o objeto juntos.
- [ ] 8. Uma falha: "dor na mão" vira um fogo na sala de Braços que trava as alavancas até ser apagado. A Cabeça recebe o alerta de dor. **Teste:** apagar o fogo e terminar a tarefa.
- [ ] 9. **Teste com um amigo de verdade.** Perguntar: foi divertido? A Cabeça se entediou? Braços ficou perdido? Anotar e ajustar antes de seguir.

## Fase 2: Os 4 setores (versão simples)
- [ ] 10. **Pernas:** sala com alavancas de passo (esquerda, direita) e equilíbrio. **Teste:** o boneco anda até uma porta.
- [ ] 11. **Tronco:** coração (ritmo) e pulmão (respiração) que geram energia; sem energia os outros setores ficam lentos. **Teste:** parar de bombear enfraquece o corpo.
- [ ] 12. Vida do personagem e tela de morte. **Teste:** ignorar as falhas mata o personagem.
- [ ] 13. 3 tipos de falha (dor, infecção, fome) espalhados pelos setores. **Teste:** todo mundo tem o que consertar.
- [ ] 14. Lobby com 4 vagas e escolha de papel; com menos jogadores, setores no piloto automático. **Teste:** jogar com 2, 3 e 4 pessoas.

## Fase 3: Um dia completo e o sonho
- [ ] 15. Mundo externo pequeno (casa, rua, trabalho) e uma agenda de tarefas do dia. **Teste:** cumprir a agenda inteira.
- [ ] 16. Dinheiro por tarefa cumprida. **Teste:** o valor aparece no fim do dia.
- [ ] 17. Dormir leva todos ao sonho: cena em que os 4 se encontram. **Teste:** os 4 se veem.
- [ ] 18. Loja de buffs no sonho (ex.: coração mais forte, dedos mais rápidos). **Teste:** comprar um buff e sentir a diferença no dia seguinte.
- [ ] 19. Salvar o progresso da semana. **Teste:** fechar e abrir o jogo continua no mesmo dia.

## Fase 4: Steam e voz
- [ ] 20. Conta Steamworks e taxa Steam Direct (US$ 100); usar o App ID 480 para testes até ter o seu. **Teste:** overlay da Steam abre.
- [ ] 21. GodotSteam: lobby, convite de amigos e rede P2P no lugar do ENet. **Teste:** jogar com amigo de outra casa.
- [ ] 22. Voz no jogo ("sistema nervoso"), com chiado quando um setor está danificado. **Teste:** dá para jogar sem o Discord.

## Fase 5: Arte e conteúdo
- [ ] 23. Personagem principal em .glb (`assets/characters/`) com animações ligadas aos controles. **Teste:** os movimentos ficam engraçados.
- [ ] 24. Interiores com cara de órgãos (veias, ossos, músculos). **Teste:** cada setor é reconhecível.
- [ ] 25. 7 dias com dificuldade crescente e eventos (cachorro, chuva, chefe bravo). **Teste:** dá vontade de jogar "só mais um dia".
- [ ] 26. Tutorial curto por papel. **Teste:** alguém novo entende seu setor em menos de 2 minutos.

## Fase 6: Polimento e lançamento
- [ ] 27. Menus, opções, gamepad, sons e música. **Teste:** jogar do início ao fim sem teclado.
- [ ] 28. Página "Em breve" na Steam e clipes curtos (TikTok, Shorts, Reddit) toda semana. **Teste:** recebendo wishlists.
- [ ] 29. Demo gratuita (1 dia) e Steam Next Fest. **Teste:** demo publicada.
- [ ] 30. Conquistas, build Windows e Linux via SteamPipe, data e preço definidos, e lançar. 🎉

## Como trabalhar comigo gastando poucos tokens
- **Um passo do roteiro por pedido.** Ex.: "faça o passo 5".
- **Coloque o jogo num repositório GitHub** e conecte ao projeto, assim eu altero os arquivos direto.
- **Mande só o erro relevante** (a mensagem vermelha do Godot e o nome do arquivo).
- **Modelos 3D:** coloque o .glb em `assets/` e me diga o nome e para que serve.
- **Não pule a Fase 1.** Se o protótipo não for divertido, é muito mais barato mudar a ideia agora.
