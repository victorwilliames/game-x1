# Visualização de desenvolvimento — game-x1

**Regra vigente:** NÃO focar em gráficos finais. Este arquivo documenta somente a representação visual mínima que permite **desenvolver, observar, depurar e testar o jogo**.

## Referência visual aprovada para prototipagem

A imagem enviada pelo usuário em 15/10/2026 mostra um **boneco de linhas com articulações pontuadas**, desenhado sobre **piso escuro quadriculado em perspectiva**. É uma referência de **nível de simplicidade e linguagem de debug**, não uma exigência de reprodução artística exata.

- **Herói:** boneco-palito / esqueleto articulado no mundo 3D; braços e pernas como linhas ou cilindros finos, juntas como pontos/esferas pequenas. Cabeça e torso podem ser apenas marcadores simples.
- **Movimento:** visualizar claramente pivôs, rotação, direção, Idle, Run, Attack, Cast, Dodge, Hit e Death. Pode usar movimentação procedural ou AnimationPlayer simples.
- **Cenário:** plano 3D, grade de referência e limites da arena visíveis. Sem árvores, montanhas, props decorativos ou texturas complexas.
- **Minions e torres:** marcadores, cápsulas, cubos ou silhuetas geométricas simplificadas, distinguíveis por forma/equipe.
- **Poderes Q/W/E/R:** geometria básica, trajetórias, círculos de alcance, sinais de área, cor e duração suficientes para verificar timing/colisão/dano; nenhum VFX polido obrigatório.
- **HUD:** HP, cooldowns, alvo, status e informações de teste com texto/retângulos simples. Clareza funcional acima da aparência.
- **Depuração opcional:** hitboxes, raios de ataque, waypoints, navegação, velocidade, FPS e estados de IA, com exibição configurável.

## Como implementar

- Tudo permanece em **Godot 3D com câmera elevada e inclinada**, apesar do aspecto de boneco-palito. Não transformar o projeto em plataforma 2D.
- Preferir recursos nativos: MeshInstance3D, SphereMesh/CylinderMesh/BoxMesh, segmentos desenhados e materiais simples; evitar addons pesados.
- Articulações e animações devem refletir eventos reais da gameplay. Não usar animação como fonte autoritativa de dano/colisão.
- Separar classes/estado do herói da representação de debug. O visual deve ser substituível futuramente sem refazer movimentação, hit detection ou habilidades.
- **Não produzir** modelagem complexa, rigs de produção, texturas, cenários detalhados, shaders cinematográficos, efeitos de partículas elaborados, ícones finais ou ilustrações. Não usar Blender ou serviços pagos para cumprir estas etapas.

## Critério de aceite visual nesta fase

A pergunta não é 'está bonito?', mas sim: **o jogador consegue controlar e perceber o que aconteceu?** É possível observar direção, movimento, animação, esquiva, ataque, acerto, falha, colisão, vida, cooldown e objetivos na câmera real de jogo? A build Web representa corretamente estes estados?

Um protótipo pode estar completo para esta fase mesmo parecendo um ambiente de testes de física/animação.

## Fase artística futura

Somente após solicitação explícita da direção do produto: definir identidade visual final, modelos, materiais, cenários, animação profissional e pipeline opcional Blender CLI/glTF. Até lá, evitar tarefas de polimento visual.
