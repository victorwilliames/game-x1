# Progresso — game-x1

**Atualizado:** 2026-10-15  
**Fase:** Experiência Web em modo janela e controles de câmera aprimorados (edge scrolling responsivo para janela/canvas, arrasto por botão do meio MMB, prevenção de scroll de página em Espaço/Wheel, suporte a redimensionamento e 8 testes automatizados de câmera).  
**Fonte de verdade:** commits + este arquivo. Nunca marcar como concluído sem evidência real.

## Situação verificada

- [x] Repositório GitHub `victorwilliames/game-x1` criado e sincronizado.
- [x] Primeira documentação técnica/visual e escopo do jogo registrados.
- [x] Godot 4 disponível e sua versão registrada na máquina de desenvolvimento (`Godot v4.7.2.stable.official.ed1daf0bf`).
- [x] Projeto Godot mínimo criado no repositório com cena 3D (chão, iluminação direcional com sombras, marcador central e câmera inclinada).
- [x] Exportação Web (GL Compatibility) gerada e validada via CLI.
- [x] Pipeline reproduzível CLI para testar (`test.ps1`), exportar (`export_web.ps1`), rodar (`run.ps1`) e servir localmente (`serve_web.ps1`).
- [x] Prova visual inicial Web da Etapa 0 confirmada por captura no Chrome (60 FPS).
- [x] Personagem 3D estilo boneco-palito articulado (`scenes/hero/stick_figure.tscn`) com juntas e membros nativos.
- [x] Animações procedurais nativas de `Idle` (respiração) e `Run` (passadas e braços alternados) sincronizadas com a velocidade horizontal.
- [x] Anel de seleção circular no chão sob os pés do herói (`SelectionRing`, ciano emissivo).
- [x] Movimentação por clique no chão com raycast físico restrito à arena e sem overshoot (`step_speed = min(move_speed, distance / delta)`).
- [x] Teste determinístico automatizado de movimentação e chegada precisa sem oscilação (`scripts/test_movement.gd`).
- [x] Controlador de câmera isolado estilo LoL (`scenes/moba_camera.gd`, `MobaCamera`):
  - Câmera livre como modo padrão, centrada inicialmente no herói.
  - Edge scrolling responsivo proporcional ao tamanho da janela (5% largura, 7% altura, min 36px, max 80px) com aceleração gradual, funcionando perfeitamente em modo janela sem encostar na borda física do monitor.
  - Navegação alternativa por arrasto com o botão do meio do mouse (MMB Drag-scroll), sem exigir fullscreen ou pointer lock.
  - Segurar Espaço centraliza suavemente no herói; soltar retorna à câmera livre no local atual sem saltos.
  - Tecla Y alterna entre câmera livre e câmera travada no herói.
  - Zoom por scroll do mouse com interpolação suave e limites (9.0m a 22.0m), sem reposicionar o pivô.
  - Yaw e pitch fixos, com movimentação independente do herói respeitando os limites da arena.
  - Botão direito exclusivo para movimentar (clique ou arrasto); botão esquerdo não comanda movimento.
  - Prevenção de rolagem de página no navegador via script em `export_presets.cfg` (`html/head_include`) e `JavaScriptBridge` em `main.gd` (Espaço e Wheel interceptados sobre o canvas; navegação normal preservada fora da área do jogo).
  - HUD e texto de ajuda atualizados com o modo atual da câmera `[Free]`, `[Locked]`, `[Panning (MMB)]` ou `[Free (Space Centering)]`.
- [x] Testes automatizados quádruplos (`scripts/test.ps1`: Editor parse, Smoke check 60 frames, Deterministic movement e 8 verificações do Camera controller).
- [x] Arena isométrica escura com muretas, pilastras, spires de time e 4 dummies inimigos de teste.

## Próximos incrementos

**0. Fundação e prova Web**
- [x] Projeto Godot 4.x com cena 3D, chão, luz e câmera inclinada.
- [x] Comando/script para importar e executar pelo terminal (`scripts/test.ps1`, `scripts/run.ps1`).
- [x] Exportação Web funcional gerando HTML/WASM/PCK (`scripts/export_web.ps1`) e servida com headers COOP/COEP (`scripts/serve_web.ps1`).
- [x] Captura real da cena Web no Chrome (chão, cubo/sombra, câmera, HUD, ~60 FPS).
- [ ] Teste simples para Windows; avaliação inicial das limitações Android.

**1. Herói e movimentação**
- [x] (1A) Boneco-palito 3D articulado com segmentos/juntas visíveis, Idle e Run (visual de desenvolvimento, sem arte final).
- [x] (1A) Clique para mover com botão direito, rotação coerente e parada sem overshoot.
- [x] (1A Refinada) Arena isométrica escura com muretas, pilastras, spires de time, 4 dummies inimigos e anel de seleção.
- [x] (UX/Câmera) Câmera estilo League of Legends com otimização completa para modo janela Web (edge pan responsivo, MMB drag, Espaço sem scroll de página, Y, zoom suave, limites e HUD).
- [ ] (1B) Esquiva (Shift) com animação, cooldown e colisão.

**2. Combate básico**
- [ ] Ataque e HP/dano/morte.
- [ ] Q/W/E/R com alvos, tempos, efeitos e testes.
- [ ] HUD legível.

**3. Partida 1v1 contra bot**
- [ ] Lane, duas bases, uma torre por lado.
- [ ] Minions e bot funcional.
- [ ] Vitória/derrota/respawn/reinício e balanceamento inicial.

**4. Aprimoramento de gameplay**
- [ ] Melhorar game feel, animações, VFX, UX e desempenho Web.
- [ ] Definir se vale incorporar um Godot MCP e validar o ganho real.

**5. 1v1 online**
- [ ] Simulação/servidor autoritativo, conexão de dois clientes e sincronização.
- [ ] Testes de latência, divergência de estado, desconexão e reconexão.

## Regras para atualizar

Registrar por incremento: commit, funcionalidade jogável, comando/teste executado, resultado, captura real (quando visual) e limitações. Não reportar aprovação estética sem playtest humano.

**Próxima tarefa para o Antigravity:** Após validação humana da navegação de câmera na janela do navegador, implementar a Etapa 1B (esquiva no Shift com recarga e rastro/feedback visual).
