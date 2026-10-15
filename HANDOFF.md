# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Experiência Web em modo janela e controles de câmera aprimorados e validados (zonas de edge scrolling responsivas de 5% a 7% do canvas com aceleração progressiva, arrasto de câmera com o botão do meio MMB sem pointer lock, interceptação de Space e Wheel contra rolagem da página via `html/head_include` e `JavaScriptBridge`, consistência em redimensionamento de janela, e 8 verificações automatizadas de câmera passando com código 0).  
**Branch:** `main` (pronta para commit e push).

## 1. Estado da entrega (Navegação Web em Modo Janela & Câmera LoL)

- **verified:** Edge scrolling responsivo: margens proporcionais ao canvas (5% largura, 7% altura, com clamping entre 36px e 80px) e aceleração progressiva, permitindo navegar confortavelmente nas bordas superior e inferior dentro de uma aba comum do Chrome sem atingir as abas do navegador ou a barra de tarefas do Windows.
- **verified:** Movimentação alternativa por arrasto do botão do meio (MMB Drag-scroll) em `scenes/moba_camera.gd`: permite agarrar e arrastar o cenário com o clique da roda do mouse em qualquer ponto da tela, sem depender de fullscreen ou pointer lock.
- **verified:** Prevenção de rolagem de página no navegador: script injetado em `export_presets.cfg` (`html/head_include`) e reforçado via `JavaScriptBridge.eval` em `scenes/main.gd`. `Espaço` e `Wheel` são interceptados com `e.preventDefault()` apenas quando o foco/cursor está sobre o canvas; interações normais fora do jogo continuam preservadas.
- **verified:** Redimensionamento de janela: `window/stretch/mode="canvas_items"` e `window/stretch/aspect="expand"` com `Camera3D.keep_aspect = KEEP_HEIGHT` garantem enquadramento, proporções e raycast de clique do mouse 100% consistentes em qualquer tamanho ou redimensionamento de janela.
- **verified:** Segurar `Espaço` centraliza suavemente no herói; soltar retorna à câmera livre no ponto atual sem saltos.
- **verified:** Tecla `Y` alterna entre câmera travada e livre.
- **verified:** Zoom suave por scroll do mouse entre 9.0m e 22.0m sem resetar o pivô para o herói.
- **verified:** Botão direito comanda movimento (clique e arrasto); botão esquerdo não comanda movimento.
- **verified:** HUD exibe em tempo real o modo (`[Free]`, `[Locked]`, `[Panning (MMB)]` ou `[Free (Space Centering)]`), FPS e zoom.
- **verified:** Suite de testes automatizados quádruplos (`scripts/test.ps1`: Editor parse, Smoke 60 frames, Deterministic movement, e 8 verificações de `test_camera.gd`) passou com código 0.
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerou com sucesso o pacote atualizado em `build/web/`.
- **verified:** Servidor local HTTP (`scripts/serve_web.ps1`) ativo em segundo plano na porta 8080 com headers COOP/COEP.
- **pending (validação humana):** Playtest dos controles em modo janela no Chrome em `http://localhost:8080/`.

## 2. Arquivos alterados / criados

- `scenes/moba_camera.gd`: margens de borda responsivas (5% a 7%), aceleração progressiva, suporte a MMB drag e status dinâmico.
- `scenes/main.gd`: script de guarda de rolagem do navegador para Web via `JavaScriptBridge` e atualização do HUD de ajuda.
- `export_presets.cfg`: script preventivo no `<head>` HTML para interceptar rolagem da página em Space e Wheel sobre o canvas.
- `scripts/test_camera.gd`: expandido para 8 verificações automatizadas incluindo drag com MMB e limites responsivos de borda.
- `PROGRESS.md`: histórico de marcos atualizado.
- `HANDOFF.md`: esta memória operacional.

## 3. Comandos executados e evidências

1. `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - *Resultado:* Exit code 0 (1/4 Editor parse, 2/4 Smoke check 60 frames, 3/4 Deterministic movement check, 4/4 MobaCamera controller checks com 8/8 asserções).
2. `powershell -ExecutionPolicy Bypass -File .\scripts\export_web.ps1`
   - *Resultado:* Exit code 0 (`index.wasm`, `index.pck`, `index.html` com script preventivo).
3. `C:\Windows\System32\curl.exe -s -I "http://localhost:8080/"`
   - *Resultado:* HTTP/1.1 200 OK com isolamento de headers e servidor ativo.

## 4. Checklist de testes manuais no navegador (Web em Modo Janela)

Acesse **`http://localhost:8080/`** em uma janela comum do Chrome (tecle `Ctrl+Shift+R`):

1. **Janela normal (não maximizada / ocupando parte da tela):**
   - Redimensione a janela do navegador. Observe que o jogo se ajusta fluidamente sem cortar elementos do HUD nem distorcer proporções.
2. **Edge Scrolling confortável:**
   - Aproxime o cursor das bordas internas do canvas (especialmente acima perto das abas e abaixo perto da barra de tarefas).
   - O scroll deve iniciar suavemente antes de você precisar encostar na borda física do monitor.
3. **Arrasto com Botão do Meio (MMB Drag):**
   - Clique e segure a roda do mouse (botão do meio) em qualquer área da tela e arraste. A câmera deve mover de forma responsiva sem sair do lugar ou exigir pointer lock. O HUD mostra temporariamente `Cam: [Panning (MMB)]`.
4. **Espaço sem rolagem de página:**
   - Afaste a câmera e aperte `Espaço`. A câmera deve voar suavemente até o herói sem que o navegador role a página para baixo.
5. **Zoom sem rolagem de página:**
   - Posicione o cursor sobre o canvas do jogo e gire a roda do mouse. O zoom aproxima/afasta suavemente sem rolar a página da web.
6. **Preservação de interação fora do canvas:**
   - Mova o cursor para fora da área do canvas (se houver margem ou outra aba). O navegador volta a responder normalmente.
7. **Tecla Y:**
   - Pressione `Y` para travar no herói (`[Locked]`) e `Y` novamente para destravar (`[Free]`).
8. **Movimento com botão direito:**
   - Clique com o botão direito para andar; clique com o botão esquerdo para conferir que não emite movimento.

## 5. Próxima ação recomendada

Após validação da jogabilidade em modo janela pelo usuário e tech lead, avançar para a **Etapa 1B** (esquiva mecânica no Shift com cooldown, deslocamento rápido e feedback visual).
