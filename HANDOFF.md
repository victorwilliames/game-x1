# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Etapa 0 concluída tecnicamente; aguardando confirmação visual humana da versão Web.  
**Branch:** `main` (sincronizada com `origin/main` em `dd9aa61`).

## 1. Estado da entrega (Etapa 0)

- **verified:** Godot 4.7.2 oficial instalado via WinGet (`Godot_v4.7.2-stable_win64_console.exe`, versão `4.7.2.stable.official.ed1daf0bf`).
- **verified:** Templates oficiais de exportação Web instalados em `$env:APPDATA\Godot\export_templates\4.7.2.stable\`.
- **verified:** Configuração do projeto `project.godot` com renderizador `gl_compatibility` (compatível com Web).
- **verified:** Cena 3D mínima (`scenes/main.tscn`, `scenes/main.gd`) com chão (`StaticBody3D`), iluminação direcional com sombras, marcador central 3D e câmera inclinada em perspectiva MOBA com HUD de status e FPS.
- **verified:** Smoke test headless via CLI (`powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`) executou com sucesso (código 0).
- **verified:** Exportação Web via CLI (`powershell -ExecutionPolicy Bypass -File .\scripts\export_web.ps1`) gerou com sucesso em `build/web/` (`index.html`, `index.js`, `index.wasm`, `index.pck`).
- **verified:** Servidor local HTTP (`powershell -ExecutionPolicy Bypass -File .\scripts\serve_web.ps1`) serve os arquivos com headers `Cross-Origin-Opener-Policy: same-origin` e `Cross-Origin-Embedder-Policy: require-corp` e MIME types corretos (`200 OK`).
- **pending (validação humana):** Playtest e inspeção visual da cena aberta no navegador (`http://localhost:8080/`). Disparado localmente via `Start-Process`.

## 2. Arquivos alterados / criados

- `project.godot`: configurações do projeto e renderizador Compatibility.
- `export_presets.cfg`: preset de exportação Web (sem threads para compatibilidade universal) e Windows.
- `scenes/main.tscn`: cena 3D mínima.
- `scenes/main.gd`: script da cena com cálculo de FPS e rotação do marcador de teste.
- `scripts/godot_path.ps1`: localizador automático do binário do Godot 4 no Windows.
- `scripts/run.ps1`: execução do projeto localmente.
- `scripts/test.ps1`: smoke check headless (saída 0).
- `scripts/export_web.ps1`: exportação headless para Web em `build/web/`.
- `scripts/serve_web.ps1`: servidor HTTP local com suporte a headers de segurança e MIME types.
- `PROGRESS.md`: progresso atualizado com fatos comprovados.
- `HANDOFF.md`: este documento de continuidade.

## 3. Comandos executados e resultados

1. `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - *Resultado:* Exit code 0 (`[game-x1] Main scene ready. Platform: Windows, Headless: true`).
2. `powershell -ExecutionPolicy Bypass -File .\scripts\export_web.ps1`
   - *Resultado:* Exit code 0 (arquivos `index.html`, `index.wasm` ~39.5MB, `index.pck`, `index.js` gerados).
3. `C:\Windows\System32\curl.exe -i "http://localhost:8085/"`
   - *Resultado:* HTTP/1.1 200 OK com headers COOP/COEP ativos.

## 4. Como abrir e testar

- **No navegador (Web):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\serve_web.ps1 -OpenBrowser
  ```
  Acesse `http://localhost:8080/`.
- **Nativo (Windows):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
  ```
- **Smoke test headless:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
  ```

## 5. Próxima ação recomendada

Após confirmação visual do tech lead/usuário, iniciar a **Etapa 1** (boneco-palito 3D articulado, estados Idle/Run e movimentação com clique no chão).
