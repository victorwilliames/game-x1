# Direção de arte — protótipo game-x1

**Status:** direção inicial, a ser validada visualmente no próprio jogo.

## Intenção visual

Fantasia estilizada, 3D verdadeiro, legível de uma câmera MOBA elevada e inclinada. **Originalidade e consistência acima de realismo.** Proibido copiar modelos, personagens, ícones, mapas ou efeitos de jogos comerciais.

## Protótipo: arte por código

- Usar formas geométricas Godot (malhas, materiais, luz, partículas, shaders simples) para construir herói, minions, torre, base, terreno e vegetação.
- O herói deve ter cabeça, tronco, braços, pernas e acessório visual com pivôs manipuláveis para animação básica.
- Formas e cores devem distinguir rapidamente equipes, inimigos, unidades e estruturas; nunca depender **somente** da cor para informação importante.
- Silhuetas claras, pouca textura, materiais simples, VFX com contraste mas sem cobrir áreas relevantes de combate.
- Não gastar tempo produzindo rigs detalhados ou texturas avançadas antes do primeiro playtest.

## Movimento e animação

- Idle: respiração e leve balanço.
- Run: braços/pernas alternados, resposta imediata a mudança de direção.
- Basic attack: preparação curta, disparo na janela correta, recuperação.
- Cast Q/W/E/R: gesto correspondente à magia com emissão sincronizada.
- Dodge: inclinação, aceleração/desaceleração e rastro curto.
- Hit/death/respawn: feedback visível e cancelamento correto de ações quando necessário.
- Animações devem responder ao estado real da simulação; não criar dano como efeito colateral da animação.

## Efeitos e HUD

- Cada habilidade precisa ter identidade própria por silhueta, som (quando existir), movimento e contraste.
- Telegraphs mostram área/tempo antes do impacto; partículas não substituem validação de hitboxes.
- HUD simples e coeso, fontes sans-serif nítidas, ícones e cooldowns acessíveis; evitar interface genérica poluída.
- Revisar efeitos na **distância normal da câmera**, não apenas em close.

## Revisão

Critérios: leitura de alvos, clareza de equipes, orientação espacial, feedback de dano, transições, responsividade e desempenho Web. Capturas reais do jogo e testes da build têm precedência sobre mockups.

## Futuro pipeline

Quando aprovado o gameplay, considerar **Blender CLI + Python → glTF/.glb → Godot** para modelos e animações originais refinados. Preservar separação entre visual e lógica para troca progressiva; pacotes terceiros são opcionais, sujeitos a licença e direção artística.
