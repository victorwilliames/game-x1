# game-x1 — Regras Operacionais do Agente (Branch: port/game-x0-1to1)

Esta branch é dedicada à **migração 1:1 e reprodução fiel do jogo `game-x0-moba` (Three.js + TypeScript) para Godot 4 (GDScript + 3D)**.
A fonte da verdade visual, de controles, enquadramento, combate e sensação de jogo é o `game-x0-moba`.

## Princípios da Migração
- **Fidelidade 1:1 Absoluta:** O objetivo é paridade direta com o `game-x0-moba`. Não desenvolvemos um jogo diferente nem uma interpretação genérica de League of Legends. Reproduzimos a versão já aprovada pelo proprietário.
- **Revogação da política de bonecos-palito:** Na branch de migração, a regra anterior de "apenas bonecos-palito" está revogada. Utilizamos o modelo original da Caitlyn (`CaitlynComplete.glb`), dummies vermelhos, anéis de tolerância, projéteis Hextech e interface do `game-x0`.
- **Preservação de timings e gameplay:** Respeitar a velocidade de movimento (16.0), ataque (1.85), windup (0.04s), anim (0.12s), bônus de cliques rápidos (kiting mecânico), projéteis homing (25.0) e coronhada melee ($\le 3.2\text{ m}$).
- **Câmera fiel ao game-x0:** FOV 38°, offset (0, 56, 48), folga do cursor no modo travado (6.0 unidades, lerp 0.08), edge pan (18px, vel 40), arrasto com MMB e limites clamped em $\pm 38$.
- **Sem overengineering:** Código modular, legível e direto em GDScript nativo, sem camadas desnecessárias de plugins ou frameworks complexos.
- **Desenvolvimento em incrementos verificáveis:** Cada fase da migração deve ser testável, mantendo o projeto executável via CLI e no navegador.

## Engine e Workflow
- Godot 4 estável, **GDScript**, 3D, câmera perspectiva com ângulo original do `game-x0`.
- **CLI-first:** Criar/editar arquivos de texto (cenas `.tscn`, scripts `.gd`), testar via `scripts/test.ps1` e exportar via `scripts/export_web.ps1`.
- **Web em Modo Janela como prioridade:** O jogo deve funcionar perfeitamente em abas comuns do Chrome sem exigir fullscreen ou pointer lock obrigatórios, com meta de 120 FPS em hardware de referência de 120 Hz.
- Renderizador `Compatibility` (WebGL 2.0).

## Validação e Qualidade
- Executar `scripts/test.ps1` após alterações estruturais.
- Validar a exportação Web e testar no navegador em [http://localhost:8080/](http://localhost:8080/).
- Comparar lado a lado com a versão de referência em [http://localhost:3005/](http://localhost:3005/) ou no GitHub Pages.
- Nunca marcar testes como passados sem execução real.
- Commits organizados publicados exclusivamente na branch `port/game-x0-1to1`. Proibido merge para `main` sem autorização do proprietário.

## Continuidade da Sessão
- **Sempre ler `HANDOFF.md` antes de retomar uma sessão**.
- **Atualizar `HANDOFF.md` a cada marco significativo**, indicando branch, arquivos alterados, estado de verificação, testes executados e próximo passo.
