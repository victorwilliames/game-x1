# HANDOFF — memória operacional do game-x1

**Atualizado por:** Antigravity (programador principal) em 2026-10-16  
**Situação:** Migração integral 1:1 de `game-x0-moba` para Godot 4 — **Refinamento Tipográfico e Calibragem Visual 1:1**.
- Criada a classe `MobaFonts` (`scripts/moba_fonts.gd`) aproveitando nativamente o eixo OpenType `wght` da fonte variável `Outfit-Variable.ttf` (pesos 500 Medium, 700 Bold, 800 ExtraBold e 900 Black) sem artefatos de `variation_embolden`.
- Corrigidas as alturas de projeção das placas flutuantes para bater 1:1 com o Three.js original: Caitlyn em $y + 5.2$ (antes $6.1$) e Dummies em $y + 3.4$ (antes $3.8$).
- Substituído o contorno invasivo das fontes pequenas por sombra projetada (`text-shadow: 1px 1px 1px #000`), eliminando o preenchimento de letras vazadas ('e', 'a', 'o', '0').
- StatusHUD atualizado com `MobaFonts.outfit_medium()`, `MobaFonts.outfit_bold()` e sombras de texto de alto contraste.
- Grade da arena recalibrada: linha central dourada intensificada para alcançar `[151, 124, 69]` e linhas secundárias atenuadas para `[22, 34, 44]`.
- 5/5 suítes de teste passando com 0 erros (`scripts/test.ps1`), exportação Web atualizada (`scripts/export_web.ps1`).  
**Branch:** `port/game-x0-1to1`

## 1. Links do Projeto e Referências

- **Repositório Destino (Godot 4):** [https://github.com/victorwilliames/game-x1](https://github.com/victorwilliames/game-x1)
  - **Branch ativa:** `port/game-x0-1to1`
  - **Diretório local:** `C:\.PROJETOS - Sites 2026\godot\game-x1`
  - **Servidor Web Local (Godot):** [http://localhost:8080/](http://localhost:8080/)
- **Repositório de Referência (Three.js):** [https://github.com/victorwilliames/game-x0-moba](https://github.com/victorwilliames/game-x0-moba)
  - **Jogo publicado de referência:** [https://victorwilliames.github.io/game-x0-moba/](https://victorwilliames.github.io/game-x0-moba/)
  - **Diretório local:** `C:\.PROJETOS - Sites 2026\godot\game-x0-moba\jogo`
  - **Servidor Dev Local (Three.js):** [http://localhost:3005/](http://localhost:3005/)

## 2. O que o jogador e o avaliador podem verificar agora

1. **Paridade Visual e de Imagem 1:1:**
   - **Tipografia Nítida e Variável:** Textos do StatusHUD e das barras flutuantes usando pesos nativos do Outfit (500/700/800/900) com sombra projetada preta `(1, 1)`, perfeitamente legíveis sem deformações.
   - **Placas Flutuantes Posicionadas 1:1:** Barra da Caitlyn ancorada a $y+5.2$ sobre o chapéu e barras dos Dummies ancoradas a $y+3.4$.
   - **Grid Calibrado:** Linhas secundárias sutis que não dominam a visão e linha central dourada nítida.
   - **Antialiasing de Hardware (MSAA 2x):** Bordas do modelo 3D da Caitlyn, rifle e Dummies suaves e definidas.
   - **Sombras PCF Acopladas:** Sombra direcional nítida e suave projetada sob os pés da Caitlyn sem descolamento (bias 0.02, normal_bias 1.0, alcance 55m).
2. **Jogabilidade e Combate 1:1 LoL:**
   - Caitlyn oficial 3D (`CaitlynComplete.glb`, 16.0 m/s, HP 1072, alcance 18m).
   - Ataque básico com windup 0.04s e animação acelerada a 3.5x.
   - Projéteis rosas Hextech a 25.0 m/s (55 dano / 96 crítico).
   - Coronhada melee instantânea a $\le 3.2$ m com faísca amarela.
   - Kiting com bônus de cliques rápidos (+15% a cada stack até +45%).
   - Câmera LoL: FOV 38°, offset (0, 56, 48), folga do cursor no modo travado, edge pan, arrasto MMB e limites $\pm 38$.

## 3. Estado das validações

- **verified:** Suíte quíntupla (`scripts/test.ps1`) com 100% de sucesso (código de saída 0):
  - 1/5: Import & parse do editor headless.
  - 2/5: Smoke check de 60 frames.
  - 3/5: Movimento determinístico e parada sem overshoot (`test_movement.gd`).
  - 4/5: 7 verificações de câmera e limites (`test_camera.gd`).
  - 5/5: 7 verificações de combate, dummies, projéteis, kiting e targeting (`test_combat.gd`).
- **verified:** Exportação Web (`scripts/export_web.ps1`) gerando pacote atualizado em `build/web/`.

## 4. Próxima ação recomendada

1. Continuar refinamento dos cartões e ícones do StatusHUD se necessário.
2. Manter testes e builds sincronizados na branch `port/game-x0-1to1`.
