# Corpo

Jogo co-op em Godot 4: quatro amigos são a tripulação de um corpo humano.
Veja o design em [docs/GDD.md](docs/GDD.md) e o roteiro em [docs/ROADMAP.md](docs/ROADMAP.md).

## Protótipo atual (Cabeça, Braços e Pernas)
- **Cabeça** (quem hospeda): vê o corpo inteiro lá fora e manda ordens separadas para Braços e Pernas.
- **Braços**: duas salas, braço esquerdo e direito, com as alavancas dos 5 dedos e do braço. O portal roxo atrás de você leva ao outro braço.
- **Pernas**: duas salas, perna esquerda e direita. Um passo é LEVANTAR, PRA FRENTE e abaixar de novo. Levantar as duas pernas juntas derruba o corpo. O portal leva à outra perna.
- Objetivo: andar 4 passos até a mesa e pegar a maçã com a mão do lado certo (muda a cada rodada). Estique o braço **antes** de fechar a mão.
- Sem ninguém nas Pernas, o corpo já começa na mesa, então dá para jogar só com Cabeça e Braços.
- Falha: de vez em quando surge fogo em um dos braços ("dor"). Ele trava as alavancas daquele braço e tira vida. Aperte E 5 vezes nele para apagar.

## Como testar sozinho
1. Abra o projeto no Godot 4.7.
2. Menu **Depuração > Personalizar Instâncias de Execução** (*Customize Run Instances*), marque **Ativar Múltiplas Instâncias** e coloque **3**.
3. Aperte F5. Na primeira janela clique **Hospedar**; nas outras, **Entrar como BRAÇOS** e **Entrar como PERNAS** (IP `127.0.0.1`).

## Como jogar com um amigo
Por enquanto a conexão é por IP (porta UDP 7777). Na mesma rede, use o IP local de quem hospeda.
Pela internet, use uma VPN de jogos como Radmin VPN até a integração com a Steam (roteiro, fase 4).

## Teste automático (sem tela)
Em três terminais, nesta ordem:
```
godot --headless -- --host --autotest
godot --headless -- --join --as=legs --autotest
godot --headless -- --join --as=arms --autotest
```
O host imprime `AUTOTEST OK` quando as Pernas andam até a mesa e os Braços pegam a maçã e apagam o fogo.
