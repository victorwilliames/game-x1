# game-x1 — Regras operacionais de desenvolvimento

**Branch oficial única: `main` | Projeto Godot 4 multiplataforma**

Este projeto migra fielmente o jogo existente [game-x0-moba](https://github.com/victorwilliames/game-x0-moba) (Three.js + TypeScript) para uma **única base Godot 4/GDScript**, exportável para Web, Windows, Linux, macOS e Android.

## Regras de colaboração e Git

- Antes de cada turno: leia `HANDOFF.md`, `PROGRESS.md`, verifique o SHA de `origin/main`, `git status` e sincronize com `git pull --ff-only origin main`. Só a **`main`** recebe desenvolvimento; nunca criar branches separadas. Proibido force push, reset destrutivo e apagar dados não commitados.
- **ChatGPT e Antigravity trabalham em turnos**, não simultaneamente nos mesmos arquivos. Cada turno termina com commit publicado, estado verificado, testes executados e limitações reais registradas. Não sobrescrever alterações de outro agente.
- Godot é a fonte de gameplay e UI em todas as plataformas. Não introduzir HTML/CSS como HUD principal nem duplicar gameplay para Web. Perfis gráficos específicos de plataforma são válidos quando necessários.
- Código tocado via GitHub **sem Godot local** pode ser inspecionado/verificado estaticamente, mas **não deve ser declarado compilado, exportado ou testado no Chrome/Windows** sem execução real. Informar validações pendentes claramente.

## Fidelidade e performance

- O `game-x0-moba` é referência de controles, câmera, visuais, tipografia, ataques e animações. Preservar Caitlyn original, 2 dummies, anéis, sombras, grid, rifle, chapéu, HUD, fontes Outfit, combate e kiting; não substituir elementos visuais por proxies piores para obter FPS.
- Movimento: 16 m/s, alcance 18 m, AS base 1,85, câmera FOV 38°, offset (0,56,48), controles Y/Espaço/MMB, limites ±38 m. Use dados do jogo original para demais timings.
- **Meta de engenharia: 300 FPS (~3,33 ms/frame) com imagem completa, inclusive antialiasing.** Resultados `no_fxaa` são diagnósticos, não cumprimento da meta visual. FPS bruto não equivale a quadros visíveis em uma tela de 60 Hz; não prometer 300 em hardware arbitrário.
- Medir `full`, tempo CPU/GPU quando disponível, intervalos p50/p95/p99, cenário e resolução; repetir benchmarks e evitar confundir `requestAnimationFrame` com FPS da GPU.
- Atenção especial à legibilidade dos textos pequenos do HUD. Não resolver serrilhado borrando a UI com pós-processamento; testar renderização da fonte em 100%, escalas DPI e tamanho real.
- Web Godot 4 requer Compatibility/WebGL2; renderizadores nativos podem ter perfis próprios, mas manter o projeto único.

## Qualidade e testes

```powershell
git pull --ff-only origin main
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
powershell -ExecutionPolicy Bypass -File scripts/export_web.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_perf_bench.ps1 -Configs "full,no_fxaa" -Runs 3 -Sec 12 -Warmup 6
```

- Export Web no Chrome: `http://localhost:8080/` após `scripts/serve_web.ps1`; referência Three.js: `http://localhost:3005/`.
- `scripts/perf_bench.gd` possui modos `pass_only`, `crop_draw`, `crop_copy` **experimentais**. Eles não substituem o `full` de produção nem demonstram qualidade visual equivalente. `BackBufferCopy` e região parcial exigem validação nativa e Web antes de recomendar uso de produção.
- A física `Dummy` não realiza colisões completas: antes de obstáculos físicos, revisar a configuração e os testes.
- Após cada alteração que toque gameplay, testar as cinco suítes. Não marcar como passou sem executá-las. Fazer comparativo visual com screenshots e medições antes/depois quando houver impacto gráfico.
