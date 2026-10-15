# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Etapa 1A concluída e validada (boneco-palito 3D articulado, Idle/Run, movimentação por clique no chão, câmera suave e grade de laboratório); pronta para validação visual humana no navegador.  
**Branch:** `main` (pronta para commit e push da Etapa 1A).

## 1. Estado da entrega (Etapa 1A)

- **verified:** Boneco-palito 3D articulado (`scenes/hero/stick_figure.tscn`) com juntas esféricas ciano e membros cilíndricos brancos de alto contraste de debug (conforme ART_DIRECTION.md).
- **verified:** Animações nativas sem assets externos: `Idle` com respiração suave do torso/braços e `Run` com passadas e braços alternados e inclinação de torso sincronizados com a velocidade horizontal.
- **verified:** `CharacterBody3D` (`scenes/hero/hero.tscn`, `hero.gd`) com colisão de cápsula (`radius: 0.35, height: 1.8`), gravidade e `move_and_slide()`.
- **verified:** Clique com botão direito no chão (e botão esquerdo como fallback de teste Web) traça raio da câmera, define destino, rotaciona o herói suavemente na direção da marcha e para com precisão ao chegar.
- **verified:** Câmera 3D elevada em perspectiva MOBA acompanha o herói suavemente via `lerp`.
- **verified:** Chão da arena com shader de grade de laboratório (`scenes/arena_grid.gdshader`) para percepção nítida de distância e escala.
- **verified:** Marcador visual de clique (`TargetMarker`) no chão com pulso suave indicando o destino da ordem de movimento.
- **verified:** Testes automatizados duplos (`scripts/test.ps1`: Editor parse/import e Runtime smoke check de 60 frames) passaram com código 0.
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerou com sucesso o pacote atualizado em `build/web/`.
- **pending (validação humana):** Teste de clique e movimentação do boneco-palito no navegador em `http://localhost:8080/`.

## 2. Arquivos alterados / criados

- `scenes/hero/stick_figure.gd`: controlador das articulações e animações de Idle/Run.
- `scenes/hero/stick_figure.tscn`: cena 3D do boneco-palito com juntas esféricas e membros cilíndricos.
- `scenes/hero/hero.gd`: lógica de navegação, velocidade, rotação suave e chegada.
- `scenes/hero/hero.tscn`: CharacterBody3D com cápsula de colisão e StickFigure.
- `scenes/arena_grid.gdshader`: shader da grade de laboratório para o chão.
- `scenes/main.gd`: captura de cliques de tela, câmera suave e telemetria no HUD.
- `scenes/main.tscn`: substituição do cubo central pelo Hero, arena com grade e target marker.
- `PROGRESS.md`: progresso registrado com fatos comprovados da Etapa 1A.
- `HANDOFF.md`: esta memória operacional.

## 3. Comandos executados e evidências

1. `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - *Resultado:* Exit code 0 (Editor scan/parse com classes `Hero` e `StickFigureVisual` registradas; Runtime smoke check de 60 frames passou).
2. `powershell -ExecutionPolicy Bypass -File .\scripts\export_web.ps1`
   - *Resultado:* Exit code 0 (arquivos `hero.scn`, `stick_figure.scn`, `arena_grid.gdshader`, `main.scn` empacotados em `index.pck`).
3. `C:\Windows\System32\curl.exe -s -I "http://localhost:8080/"`
   - *Resultado:* HTTP/1.1 200 OK com isolamento de headers e servidor ativo.

## 4. Como abrir e validar

- **No navegador (Web):**
  O servidor local já está ativo na porta 8080:
  Acesse `http://localhost:8080/` (ou tecle `F5` / Recarregar).
  - *Interação:* Clique com o **botão direito** (ou esquerdo) no chão com a grade para mover o boneco.
  - *Verificações:*
    1. Boneco-palito visível sobre o chão quadriculado.
    2. Ao parar, executa Idle (respiração suave).
    3. Ao clicar no chão, aparece o anel verde de destino, o boneco gira para o alvo e corre (Run com pernas e braços alternados).
    4. Câmera segue o boneco suavemente.
    5. HUD no canto superior mostra FPS, posição `(X, Z)` e velocidade atual.
- **Nativo (Windows Desktop):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
  ```

## 5. Próxima ação recomendada

Após validação visual do movimento pelo usuário e tech lead, implementar a **Etapa 1B** (esquiva mecânica no Shift com cooldown, deslocamento rápido e feedback visual simples).
