# Progresso — game-x1

**Atualizado:** 2026-10-14  
**Fase:** preparação, sem implementação Godot validada  
**Fonte de verdade:** commits + este arquivo. Nunca marcar como concluído sem evidência real.

## Situação verificada

- [x] Repositório GitHub `victorwilliames/game-x1` criado.
- [x] Primeira documentação técnica/visual e escopo do jogo registrados.
- [ ] Godot 4 disponível e sua versão registrada na máquina de desenvolvimento.
- [ ] Projeto Godot mínimo criado no repositório.
- [ ] Renderização 3D Web (Compatibility) executada e validada.
- [ ] Pipeline reproduzível CLI para testar e exportar.

## Próximos incrementos

**0. Fundação e prova Web**
- [ ] Projeto Godot 4.x com cena 3D, chão, luz e câmera inclinada.
- [ ] Comando/script para importar e executar pelo terminal.
- [ ] Exportação Web jogável no navegador, não apenas headless.
- [ ] Teste simples para Windows; avaliação inicial das limitações Android.

**1. Herói e movimentação**
- [ ] Mago 3D geométrico original com Idle e Run.
- [ ] Clique para mover, rotação coerente, câmera acompanhando.
- [ ] Esquiva (Shift) com animação, cooldown e colisão.

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

**Próxima tarefa para o Antigravity:** etapa 0, em incrementos pequenos. Ainda não começar arte detalhada ou multiplayer online.
