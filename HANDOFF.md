# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Etapa 0 concluída e revisada (ajustes da Issue #1 aplicados); aguardando validação visual humana da versão Web.  
**Último commit publicado:** `5ab2781` (ajustes da Issue #1 prontos para novo commit/push).

## 1. Estado da entrega (Etapa 0 + Issue #1)

- **verified:** Godot 4.7.2 oficial instalado via WinGet (`4.7.2.stable.official.ed1daf0bf`).
- **verified:** Templates de exportação Web instalados e configurados.
- **verified:** Cena 3D mínima (`scenes/main.tscn`, `scenes/main.gd`) com chão, iluminação com sombras, marcador central e câmera inclinada em perspectiva MOBA.
- **verified:** Verificação dupla em `scripts/test.ps1`: (1) import & parse headless do editor Godot e (2) smoke check de runtime por 60 frames. Ambos passam com código 0.
- **verified:** Exportação Web (`scripts/export_web.ps1`) gera `build/web/` sem erros.
- **verified (Issue #1):** `scripts/serve_web.ps1` protegido com validação canônica de caminho contra path traversal (`..`, `%2e%2e`) e remoção de `Access-Control-Allow-Origin: *`.
- **verified (Issue #1):** `README.md` atualizado para refletir que o projeto Godot 4 da Etapa 0 foi criado e está em validação.
- **pending (validação humana):** Playtest e inspeção visual da cena aberta no navegador em `http://localhost:8080/`.

## 2. Arquivos alterados

- `scripts/serve_web.ps1`: correção de segurança (path traversal containment check e remoção de CORS permissivo).
- `scripts/test.ps1`: inclusão da etapa `--headless --editor --quit` antes do smoke check.
- `README.md`: status atualizado de "planejamento" para "Etapa 0 implementada e em validação".
- `HANDOFF.md`: referência corrigida para o commit `5ab2781` e registro dos ajustes da Issue #1.

## 3. Comandos executados e evidências

1. `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - *Resultado:* Exit code 0 nas duas fases (Editor parse/import e Runtime smoke check de 60 frames).
2. `powershell -ExecutionPolicy Bypass -File .\scripts\serve_web.ps1 -Port 8080`
   - *Resultado:* Servidor ativo na porta 8080 com COOP/COEP.
3. Testes de segurança de rota:
   - `curl -s -I "http://localhost:8080/index.html"` -> `200 OK` (sem Access-Control-Allow-Origin: *).
   - `curl -s -i "http://localhost:8080/../project.godot"` -> `404/403` bloqueado.
   - `curl -s -i "http://localhost:8080/%2e%2e/project.godot"` -> `404/403` bloqueado.

## 4. Como abrir e validar

- **Acessar versão Web no navegador:**
  Deixar o servidor rodando ou executar:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\serve_web.ps1 -OpenBrowser
  ```
  Acesse `http://localhost:8080/`.
- **Execução nativa no Windows:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
  ```
- **Testes automáticos:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1
  ```

## 5. Próxima ação recomendada

Após o usuário validar visualmente no navegador que a cena 3D carregou (chão, cubo em rotação e FPS visíveis), avançar para a **Etapa 1** (boneco-palito 3D articulado de desenvolvimento, Idle/Run e controle de movimentação por clique).
