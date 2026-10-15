# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-15  
**Situação:** Diagnóstico e otimização profunda de desempenho para meta de 120 FPS concluídos. Causa raiz dos ~30 FPS identificada e resolvida com dados reais medidos no hardware de referência (Intel UHD Graphics 620). Redução de 96,3% na geometria de esferas, queda de draw calls de 707 para 351, telemetria em tempo real no HUD (FPS, tempo de quadro em ms, RAF do navegador em Hz, draw calls e primitivas) e tecla F1 para alternar sombras em tempo de execução.  
**Branch:** `main`

## 1. Diagnóstico Real de Desempenho (Hardware de Referência)

Medição realizada nativamente na GPU Intel UHD Graphics 620 via `scripts/bench.ps1` (`scripts/test_performance.gd`):

### Causa Raiz dos ~30 FPS no Navegador
1. **Sub-divisão excessiva de esferas nativas:** O Godot 4 instancia `SphereMesh` por padrão com 64 segmentos radiais e 32 anéis (4.224 triângulos por junta). Com 5 personagens (herói + 4 dummies) e 15 juntas cada, **316.800 triângulos** (96% da cena) vinham de minúsculos pontos de articulação.
2. **Cascata quádrupla de sombras:** A luz direcional utilizava 4 divisões (`parallel_4_splits`), re-renderizando a cena 4 vezes e gerando **707 draw calls** e **1.195.008 primitivas** por frame.
3. **Sub-harmônica de VSync do navegador:** No WebGL, 707 chamadas de desenho em thread única causavam picos acima de 16,6ms. Quando o frame excede o orçamento de 16,6ms (60Hz) ou 8,3ms (120Hz), o `requestAnimationFrame` descarta o ciclo e trava na sub-harmônica imediata de **30 FPS**.
4. **Economia de energia do navegador:** O Chrome limita o canvas a 30 FPS se a aceleração gráfica estiver desligada ou se a bateria/economia de energia estiver ativa.

### Otimizações Implementadas e Evidências Medidas
- **Geometria de juntas otimizada:** Juntas reduzidas para 8 segmentos x 4 anéis (80 faces) e cabeças para 12x6 (144 faces). Total de faces da cena caiu de **330.110 para 12.142 (-96,3%)**.
- **Modo de sombra ortogonal (1 divisão, 45m):** Draw calls reduzidas de **707 para 351 (-50,3%)** e primitivas de **1.195.008 para 77.802 (-93,5%)**.
- **Tempo de quadro medido no hardware (Intel UHD 620):**
  - *Com sombras ligadas:* tempo médio caiu de 7,15 ms para **4,80 ms** (~208 FPS destravado) — **abaixo do teto de 8,33 ms necessário para 120 FPS**.
  - *Com sombras desligadas (F1):* tempo médio de **2,35 ms** (~426 FPS destravado, 123 draw calls).
- **Telemetria ao vivo no HUD:** Exibe `FPS`, `Frame Time (ms)`, `Browser RAF (Hz)`, `DrawCalls`, `Primitives` e `Shadows [ON/OFF]`.
- **Tecla F1:** Permite ligar/desligar sombras dinamicamente durante a partida no navegador para comparação instantânea.
- **Configuração do motor:** `run/max_fps=0` e `window/vsync/vsync_mode=0` em `project.godot`.

## 2. Estado das Validações

- **verified:** Benchmark empírico de GPU (`scripts/bench.ps1`) registrando 4,80 ms (208 FPS) com sombras e 2,35 ms (426 FPS) sem sombras na Intel UHD 620.
- **verified:** Suite automatizada quádrupla (`scripts/test.ps1`) passando com código 0 (Editor parse, smoke 60 frames, movimento determinístico e 8 testes de câmera).
- **verified:** Script de auditoria geométrica (`scripts/audit_meshes.gd`) confirmando 12.142 faces totais.
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerando pacote atualizado com monitor de RAF integrado em `build/web/`.
- **verified:** Servidor web ativo em segundo plano (`http://localhost:8080/`).
- **pending (validação humana):** Conferência da taxa de quadros e comportamento da câmera em modo janela no Chrome via `http://localhost:8080/`.

## 3. Arquivos Alterados / Criados

- `scenes/hero/stick_figure.tscn`: segmentos de `SphereMesh` reduzidos para juntas (8x4) e cabeça (12x6).
- `scenes/arena/dummy_enemy.tscn`: segmentos de `SphereMesh` reduzidos para juntas e cabeça dos dummies.
- `scenes/arena/spire_allied.tscn` & `spire_enemy.tscn`: anéis de `TorusMesh` otimizados.
- `scenes/main.tscn`: sombra direcional em modo ortogonal com distância de 45m; anel do marcador otimizado.
- `scenes/main.gd`: telemetria de milissegundos e RAF, contador de draw calls/primitivas e tecla F1 para alternar sombras.
- `project.godot`: `max_fps=0` e `vsync_mode=0`.
- `scripts/test_performance.gd`: script de medição automatizada de tempos de quadro, draw calls e primitivas.
- `scripts/bench.ps1`: atalho PowerShell para executar o benchmark GPU em um comando.
- `scripts/audit_meshes.gd`: script de inspeção detalhada de faces geométricas por classe de malha.

## 4. Instruções para o Teste Manual

Acesse **`http://localhost:8080/`** no Google Chrome em janela normal (tecle `Ctrl+Shift+R`):
1. **Verificar HUD de Desempenho:**
   - Observe a primeira linha: `FPS: [N] ([M] ms) | Browser RAF: [K] Hz | DrawCalls: [D] | Primitives: [P] | Shadows: [ON]`.
2. **Alternar Sombras com F1:**
   - Pressione `F1` para desligar as sombras. Verifique a variação imediata de FPS e tempo de quadro (ms).
3. **Validar Câmera em Janela:**
   - Edge scrolling nas quatro bordas internas, arrasto com botão do meio (MMB), `Espaço` para centralizar no herói sem rolar a página da web, e clique direito para movimentar.
