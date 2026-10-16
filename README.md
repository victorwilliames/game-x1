# game-x1 — MOBA 3D com Godot 4

Projeto **Godot 4 + GDScript** de base única, reproduzindo o [game-x0-moba](https://github.com/victorwilliames/game-x0-moba) em Three.js com fidelidade de jogabilidade e visual.

**Branch de desenvolvimento única:** `main`. ChatGPT e Antigravity contribuem em turnos alternados.

## Estado atual

- Cena 3D com Caitlyn animada, dois dummies (estático e móvel), arena escura com grid dourado, câmera isométrica e sombras.
- Movimentação por clique, seleção e combate ranged/melee, projéteis, kiting, barras, números de dano, HUD nativo e cursores.
- Export Web `Compatibility` (WebGL2) e testes/benchmarks Windows nativo e Chrome.
- Destinos do mesmo projeto: **Windows, Linux, macOS, Android e Web**. Nem todas as plataformas já possuem resultados de build/teste.
- **Meta de performance: 300 FPS bruto com qualidade visual completa** em hardware de referência; ainda NÃO demonstrada consistentemente com FXAA ativo e em Chrome. Consulte `docs/migration/visual/` e `HANDOFF.md` para os resultados medidos.

## Comandos de desenvolvimento (Windows)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/test.ps1
powershell -ExecutionPolicy Bypass -File scripts/export_web.ps1
powershell -ExecutionPolicy Bypass -File scripts/serve_web.ps1
```

Janela Web local: `http://localhost:8080/`. O servidor deve permanecer aberto enquanto os testes Chrome rodam.

Benchmark nativo:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_perf_bench.ps1 -Configs "full,pass_only,no_fxaa" -Runs 3 -Sec 12 -Warmup 6
```

Experimentos `crop_draw` e `crop_copy` em `scripts/perf_bench.gd` são somente diagnósticos e não preservam a suavização de toda a cena.

## Documentação
- [AGENTS.md](AGENTS.md): regras atualizadas de Git, qualidade e validação.
- [HANDOFF.md](HANDOFF.md): estado recente, testes e próximos passos.
- [PROGRESS.md](PROGRESS.md): histórico de implementação (algumas seções descrevem abordagens anteriores).
- [GDD.md](GDD.md): escopo de gameplay.
- [ART_DIRECTION.md](ART_DIRECTION.md): identidade e comparativos.
- [docs/migration/](docs/migration/): engenharia reversa e benchmarking.

**Política:** não reportar ganhos nem testes como comprovados sem executar a compilação e os benchmarks adequados.
