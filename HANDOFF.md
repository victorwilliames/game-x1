# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Etapa 1A Refinada concluída e validada (laboratório transformado em combat testing lane isométrica, muretas e pilastras com acentos de time ciano/vermelho, estruturas de base com cristais giratórios, anel de seleção do herói, 4 dummies inimigos, Issue #2 resolvida com raycast físico, contenção de limites, eliminação de overshoot e teste determinístico headless adicionado).  
**Branch:** `main` (pronta para commit e push).

## 1. Estado da entrega (Etapa 1A Refinada)

- **verified:** Chão da arena (`scenes/arena_grid.gdshader`) refinado em tons grafite/azul-escuro (`#17202c`), com grid sutil de 2m, cruzes de vértice (+), linha pontilhada central e gradiente suave de time ao longo da rota.
- **verified:** Muretas modulares laterais e de cabeceira com pilastras e acentos de iluminação de time (`scenes/arena/arena_walls.gd`): ciano no lado aliado e vermelho no lado inimigo.
- **verified:** Colisores físicos completos nas bordas e extremidades da rota impedindo a saída da área jogável.
- **verified:** Estruturas de base aliada (`scenes/arena/spire_allied.tscn`) e inimiga (`scenes/arena/spire_enemy.tscn`) com pedestais escalonados escuros, anéis de circuito no chão e cristais flutuantes com rotação procedural (`scenes/arena/spire_structure.gd`).
- **verified:** Quatro dummies inimigos vermelhos (`scenes/arena/dummy_enemy.tscn`, `dummy_enemy.gd`) em postura de combate com barras de vida minimalistas para referência de escala e composição.
- **verified:** Anel de seleção circular no chão sob os pés do herói (`scenes/hero/hero.tscn`, `SelectionRing`) aumentando a legibilidade.
- **verified (Issue #2):** Raycast físico contra o colisor real do chão (`PhysicsRayQueryParameters3D`) com clamping obrigatório nos limites da arena (`scenes/main.gd`). Clicks no vazio/céu são ignorados com segurança.
- **verified (Issue #2):** Eliminação completa de overshoot/oscilação ao chegar no destino através de limitação de velocidade por passo (`step_speed = min(move_speed, distance / delta)`) em `scenes/hero/hero.gd`.
- **verified (Issue #2):** Teste determinístico automatizado headless de movimento e parada (`scripts/test_movement.gd`) integrado como etapa 3/3 de `scripts/test.ps1`.
- **verified:** Câmera isométrica elevada aproximada e configurável (yaw 45°, pitch 38°, zoom com scroll do mouse), valorizando o herói e a arena.
- **verified:** Teste de triplo passo automatizado (`scripts/test.ps1`) executou e passou com código 0.
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerou com sucesso o pacote atualizado em `build/web/`.
- **verified:** Servidor local HTTP (`scripts/serve_web.ps1`) ativo em segundo plano na porta 8080 com headers COOP/COEP.
- **pending (validação humana):** Playtest do visual refinado e movimentação no navegador em `http://localhost:8080/`.

## 2. Arquivos alterados / criados

- `scenes/arena_grid.gdshader`: shader da grade de laboratório refinado (grid fino, cruzes, linha pontilhada, gradiente).
- `scenes/arena/arena_walls.gd`: gerador modular de muretas, pilastras com acentos de time e colisores físicos.
- `scenes/arena/spire_structure.gd`: controlador de rotação e flutuação dos cristais de base.
- `scenes/arena/spire_allied.tscn`: estrutura de base aliada com cristal ciano.
- `scenes/arena/spire_enemy.tscn`: estrutura de base inimiga com cristal vermelho.
- `scenes/arena/dummy_enemy.gd`: postura de combate e respiração suave dos dummies.
- `scenes/arena/dummy_enemy.tscn`: boneco-palito vermelho com barra de vida minimalista.
- `scenes/hero/hero.gd`: correção de overshoot de física e clamping de chegada.
- `scenes/hero/hero.tscn`: anel de seleção ciano sob os pés do herói.
- `scenes/main.gd`: raycast físico com clamping de limites e câmera isométrica com zoom por scroll.
- `scenes/main.tscn`: composição da arena de testes com chão, muretas, spires, dummies e herói.
- `scripts/test_movement.gd`: teste determinístico headless de navegação e parada.
- `scripts/test.ps1`: inclusão do teste determinístico (3 passos).
- `PROGRESS.md`: histórico de marcos atualizado.
- `HANDOFF.md`: memória operacional atualizada.

## 3. Comandos executados e evidências

1. `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - *Resultado:* Exit code 0 (1/3 Editor parse, 2/3 Runtime smoke check 60 frames, 3/3 Headless deterministic movement check com chegada exata e retorno a IDLE).
2. `powershell -ExecutionPolicy Bypass -File .\scripts\export_web.ps1`
   - *Resultado:* Exit code 0 (`index.wasm`, `index.pck` e assets empacotados com sucesso).
3. `C:\Windows\System32\curl.exe -s -I "http://localhost:8080/"`
   - *Resultado:* HTTP/1.1 200 OK com isolamento de headers e servidor ativo.

## 4. Como abrir e validar

- **No navegador (Web):**
  Servidor ativo na porta 8080:
  Acesse **`http://localhost:8080/`** (tecle `Ctrl+Shift+R` ou `F5`).
  - *Interação:*
    - Clique com o botão direito para mover o herói na lane.
    - Use a roda do mouse (Scroll Wheel) para aproximar ou afastar a câmera.
    - Teste cliques na lane, nas bordas e fora da tela para verificar a restrição de limites.
- **Nativo (Windows Desktop):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
  ```

## 5. Próxima ação recomendada

Após validação visual do novo visual de combat testing lane pelo usuário e tech lead, avançar para a **Etapa 1B** (esquiva mecânica no Shift com cooldown, deslocamento rápido e feedback visual).
