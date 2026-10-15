# GDD — game-x1 (protótipo 1v1)

**Status:** rascunho de pré-produção. Decisões e números ainda podem mudar após playtests.

## 1. Visão

MOBA competitivo 3D visto por uma câmera elevada e inclinada, com controles claros, habilidades legíveis e um combate responsivo. Referências de experiência: jogos de arena/lane do gênero MOBA; identidade, personagens e assets serão originais.

**Objetivo imediato:** produzir uma partida completa 1v1 de uma única rota que seja agradável de jogar mesmo com arte simples.

**Plataformas:** Web para playtest, Windows e Android como alvos desde cedo. No PC, mouse/teclado; controles touch vêm em etapa específica.

## 2. Loop jogável

1. Entrar na arena com um herói e uma base por lado.
2. Avançar pela única lane, acompanhando ondas de minions aliados.
3. Acertar ataques básicos, habilidades e esquivas; preservar HP.
4. Enfrentar um bot inimigo funcional no primeiro slice.
5. Destruir a torre adversária e, depois, o núcleo inimigo para vencer.
6. Permitir reiniciar a partida imediatamente.

**1v1 online** substitui o bot numa fase posterior, mantendo as mesmas regras de combate e vitória.

## 3. Arena

- Uma lane central claramente navegável; terreno, vegetação e props laterais originais.
- Duas bases opostas, **uma torre defensiva por lado** e um núcleo por base.
- Minions surgem em ondas regulares e avançam em direção à estrutura inimiga.
- Navegação/colisão impedem atravessar obstáculos; alcance e áreas de ataque devem ser visíveis.
- Sem jungle, três lanes, loja extensa, dezenas de heróis ou matchmaking neste primeiro slice.

## 4. Herói inicial

**Arquétipo provisório:** mago 3D estilizado e geométrico, com silhueta própria e cajado.

**Movimentos/animações:** Idle, Run, Attack, Cast, Dodge, Hit, Death e respawn. Precisam ser legíveis da câmera de gameplay, ainda que simples.

**Comandos desktop propostos:**
- Clique direito no chão: mover.
- Clique direito no inimigo: perseguir até o alcance e atacar automaticamente.
- Q/W/E/R: ativar habilidades, com indicação adequada de direção/alcance/alvo.
- Shift: esquiva curta e responsiva com recarga.
- Mouse: mirar; câmera acompanha o herói (com espaço para ajustes de UX).

**Habilidades protótipo (sujeitas a playtest):**
| Entrada | Ação | Teste essencial |
| --- | --- | --- |
| Ataque básico | Projétil/ataque direcionado, cooldown próprio | Alvo no alcance sofre um único evento de dano |
| Q | Projétil mágico direcional | Trajetória, colisão, impacto e recarga claros |
| W | Explosão em área telegrafada | Área e momento do dano correspondem ao indicador |
| E | Impulso mágico curto com feedback visual | Reposiciona respeitando colisões/limites |
| R | Explosão de alto impacto com preparação | Antecipação clara, dano e recarga longa |
| Shift | Esquiva evasiva | Deslocamento, recuperação e recarga consistentes |

**Observação:** diferenciar E (habilidade especial) de Shift (esquiva mecânica); avaliar redundância no playtest.

## 5. Combate e sistemas mínimos

- HP, morte, respawn, ataque, dano, cooldowns, alvos e indicadores.
- Mana/custo de habilidades apenas se melhorar a decisão do jogador no protótipo.
- Minions: seguir lane, adquirir alvo, atacar e morrer.
- Torre: selecionar alvo válido, telegrafar/disparar e causar dano.
- Bot: caminhar, combater, usar ao menos Q, recuar quando em risco e respeitar regras compartilhadas.
- HUD: barras de vida, habilidades Q/W/E/R, recargas, placar/objetivo e tela de vitória/derrota.
- Ouro, XP, itens e loja são **extensões opcionais**, posteriores ao combate satisfatório, não bloqueadores do primeiro ciclo jogável.

## 6. Critérios de aceite do primeiro protótipo jogável

- Uma partida local vs bot começa, termina e reinicia sem edição manual.
- Hero move, gira, ataca e esquiva com transições animadas coerentes.
- Q/W/E/R ativam, respeitam cooldowns e mostram feedback de acerto/erro.
- Minions e torres interagem com heróis, geram dano e podem ser destruídos.
- A base inimiga pode ser destruída e a condição de vitória dispara corretamente.
- Existe exportação Web jogável, com entrada e HUD utilizáveis no navegador.
- O Antigravity registra testes reais, problemas pendentes e passos de reprodução.

## 7. Não escopo agora

5v5, três rotas, ranking, matchmaking, contas, monetização, fog of war completo, cosméticos, arte AAA, modelos humanos complexos, asset marketplace, servidores públicos e Android pronto para loja.

## 8. Critério de evolução

Testar **game feel antes de fidelidade visual**. Quando o protótipo for divertido: melhorar arte original, validação multiplayer autoritativa, mais heróis e modo online, na ordem que os testes justificarem.
