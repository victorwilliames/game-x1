# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Câmera estilo League of Legends e UX de navegação implementadas e validadas (modo livre padrão, edge scrolling nas bordas, segurar Espaço para centralizar suavemente, tecla Y para travar/destravar, zoom com interpolação contínua e limites sem saltos, botão direito exclusivo para andar, botão esquerdo desabilitado para movimento, e suite de 4 testes automatizados com código 0).  
**Branch:** `main` (pronta para commit e push).

## 1. Estado da entrega (Câmera estilo LoL & UX de Navegação)

- **verified:** Controlador isolado `scenes/moba_camera.gd` (`MobaCamera`) acoplado ao `CameraPivot`.
- **verified:** Câmera livre como modo padrão (`Mode.FREE`), com enquadramento inicial centrado na posição do herói.
- **verified:** Edge scrolling: aproximar o cursor das bordas da tela desloca a câmera suavemente no plano do chão, sem alterar yaw/pitch e com checagem de contenção dentro do canvas da janela/viewport.
- **verified:** Segurar `Espaço` centraliza e acompanha o herói suavemente; soltar retorna à câmera livre exatamente de onde parou, sem saltos.
- **verified:** Pressionar `Y` alterna o modo entre câmera travada (`Locked`) e câmera livre (`Free`).
- **verified:** Scroll do mouse ajusta `target_distance` (entre 9.0m e 22.0m) e interpola suavemente com `lerp`, sem reposicionar o pivô nem causar saltos na posição do herói.
- **verified:** Yaw (45°) e pitch (38°) permanecem fixos; movimento do pivô é delimitado aos limites da arena (`X: [-14, 14]`, `Z: [-34, 34]`).
- **verified:** Botão direito comanda a movimentação do herói (clique único ou arrasto contínuo); botão esquerdo foi desabilitado para movimentação.
- **verified:** HUD no topo e texto de ajuda exibem os controles e o status em tempo real da câmera (`[Free]`, `[Locked]` ou `[Free (Space Centering)]`).
- **verified:** Teste automatizado quádruplo (`scripts/test.ps1`: Editor parse, Smoke 60 frames, Deterministic movement, e MobaCamera controller checks) passou com código 0.
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerou com sucesso o pacote atualizado em `build/web/`.
- **verified:** Servidor local HTTP (`scripts/serve_web.ps1`) ativo em segundo plano na porta 8080 com headers COOP/COEP.
- **pending (validação humana):** Playtest dos controles de câmera no navegador em `http://localhost:8080/`.

## 2. Arquivos alterados / criados

- `scenes/moba_camera.gd`: controlador isolado e reutilizável da câmera MOBA (livre, travada, edge pan, espaço, zoom e limites).
- `scenes/main.gd`: delegação de atalhos da câmera, restrição exclusiva de clique direito para mover e atualização do HUD.
- `scenes/main.tscn`: associação do script `MobaCamera` ao nó `CameraPivot` e ajuste de labels de ajuda.
- `scripts/test_camera.gd`: teste automatizado headless cobrindo estados da câmera, atalhos, zoom, clamping e foco do Espaço.
- `scripts/test.ps1`: inclusão do 4º passo de teste automatizado para a câmera.
- `PROGRESS.md`: histórico de marcos atualizado.
- `HANDOFF.md`: esta memória operacional.

## 3. Comandos executados e evidências

1. `powershell -ExecutionPolicy Bypass -File .\scripts\test.ps1`
   - *Resultado:* Exit code 0 (1/4 Editor parse, 2/4 Smoke check 60 frames, 3/4 Deterministic movement check, 4/4 MobaCamera controller checks: Free default, Y toggle, Space centering, Zoom limits, Arena clamping, Event handling).
2. `powershell -ExecutionPolicy Bypass -File .\scripts\export_web.ps1`
   - *Resultado:* Exit code 0 (`index.wasm`, `index.pck` e assets empacotados com sucesso).
3. `C:\Windows\System32\curl.exe -s -I "http://localhost:8080/"`
   - *Resultado:* HTTP/1.1 200 OK com isolamento de headers e servidor ativo.

## 4. Checklist de testes manuais no navegador (Web)

Acesse **`http://localhost:8080/`** (tecle `Ctrl+Shift+R` para limpar cache antigo):

1. **Câmera livre padrão:** Ao carregar, a câmera inicia centrada no herói, mas em modo `[Free]`. Mover o herói para longe não arrasta a câmera automaticamente.
2. **Edge Pan:** Mova o cursor até as bordas (superior, inferior, esquerda, direita). A câmera deve deslizar suavemente pelo cenário sem girar a perspectiva.
3. **Segurar Espaço:** Com a câmera afastada do herói, aperte e segure a barra de `Espaço`. A câmera deve voar suavemente até o herói e acompanhá-lo enquanto a tecla estiver pressionada (`Cam: [Free (Space Centering)]`). Ao soltar o Espaço, a câmera deve parar suavemente onde está, sem saltos.
4. **Tecla Y:** Pressione `Y`. O HUD deve alternar para `Cam: [Locked]`, e a câmera passará a seguir o herói continuamente. Pressione `Y` novamente para retornar a `Cam: [Free]`.
5. **Scroll do mouse (Zoom):** Use a roda do mouse para aproximar e afastar. O zoom deve ser contínuo e suave, sem reposicionar o centro da câmera no herói.
6. **Cliques do mouse:**
   - **Botão direito:** Clicar ou arrastar com o botão direito pressionado move o herói pela rota.
   - **Botão esquerdo:** Clicar com o botão esquerdo não deve emitir ordens de movimento.

## 5. Próxima ação recomendada

Após validação da experiência de câmera pelo usuário e tech lead, avançar para a **Etapa 1B** (esquiva mecânica no Shift com cooldown, deslocamento rápido e feedback visual).
