# Corpo

Jogo co-op em Godot 4: quatro amigos são a tripulação de um corpo humano.
Veja o design em [docs/GDD.md](docs/GDD.md) e o roteiro em [docs/ROADMAP.md](docs/ROADMAP.md).

## Protótipo atual (Cabeça + Braços)
- **Cabeça** (quem hospeda): vê o mundo lá fora e manda ordens.
- **Braços** (quem entra): anda numa sala dentro do corpo e puxa as alavancas dos 5 dedos e do braço.
- Objetivo: pegar a maçã. Estique o braço **antes** de fechar a mão.
- Falha: de vez em quando surge fogo na sala dos Braços ("dor na mão"). Ele trava as alavancas e tira vida do corpo. Aperte E 5 vezes nele para apagar.

## Como testar sozinho
1. Abra o projeto no Godot 4.7.
2. Menu **Depuração > Personalizar Instâncias de Execução** (*Customize Run Instances*), marque **Ativar Múltiplas Instâncias** e coloque **2**.
3. Aperte F5. Numa janela clique **Hospedar**; na outra, **Entrar** (IP `127.0.0.1`).

## Como jogar com um amigo
Por enquanto a conexão é por IP (porta UDP 7777). Na mesma rede, use o IP local de quem hospeda.
Pela internet, use uma VPN de jogos como Radmin VPN até a integração com a Steam (roteiro, fase 4).

## Teste automático (sem tela)
```
godot --headless -- --host --autotest
godot --headless -- --join --autotest
```
O host imprime `AUTOTEST OK` quando os Braços pegam a maçã e apagam o fogo.
