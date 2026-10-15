# Referência Executável e Baseline Visual — game-x0-moba

Este documento estabelece o baseline de aceitação visual e funcional baseado na versão executável de **`game-x0-moba`**.

---

## 1. Como Executar a Versão de Referência

### A. Versão Local de Desenvolvimento (Vite)
1. Abrir terminal no diretório:
   ```bash
   cd "C:\.PROJETOS - Sites 2026\godot\game-x0-moba\jogo"
   ```
2. Executar o servidor de desenvolvimento:
   ```bash
   npm run dev
   ```
   *Servidor acessível em:* [http://localhost:3005/](http://localhost:3005/)

### B. Versão Publicada no GitHub Pages
👉 **URL Oficial:** [https://victorwilliames.github.io/game-x0-moba/](https://victorwilliames.github.io/game-x0-moba/)

---

## 2. Checklist do Baseline Visual e Interativo

### 1. Cena Inicial e Enquadramento
- **Fundo:** Preto azulado escuro `#03070c`.
- **Piso:** Plano $80 \times 80$ em `#0a1016`.
- **Grid de Desenvolvimento:**
  - Células quadradas de $2 \times 2$ metros.
  - Linhas primárias douradas `#c29d53`, linhas secundárias azul ardósia escura `#162838`.
- **Câmera:**
  - Perspectiva com FOV de $38^\circ$.
  - Posicionada em $(0, 56, 48)$ olhando diretamente para a Caitlyn na origem $(0, 0, 0)$.
  - Visão ampla e limpa sem muretas, paredes ou obeliscos.
  - Segue suavemente o mouse em até 6 unidades no modo travado (`isLocked = true`).

### 2. Personagem Principal (Caitlyn)
- Modelo 3D da Caitlyn oficial completo (`CaitlynComplete.glb`), escala $0.055$.
- Texturas originais com materiais PBR e projeção de sombras no chão.
- **Idle:** Animação suave e contínua com rifle em punho.
- **Run:** Animação de corrida acelerada em $2.5\times$, perfeitamente sincronizada com a velocidade de deslocamento de $16.0\text{ m/s}$.
- **Rotação:** Gira suavemente na direção de deslocamento com interpolação angular de $0.25$ por frame.
- **Parada:** Chegada limpa e imediata ao ponto clicado, transicionando suavemente para Idle.

### 3. Inimigos (Dois Dummies)
- **Dummy Estático:** Posição $(7, 0, 7)$. Cápsula vermelha `#9e2a2b` com dois olhos vermelhos brilhantes `#ff3b30`.
- **Dummy Móvel:** Posição inicial $(-7, 0, 7)$. Move-se para a esquerda e direita a $2.5\text{ m/s}$ oscilando em $\pm 8.0$ metros e girando $180^\circ$ a cada inversão.
- **Círculo Roxo de Tolerância:** Anel translúcido de raio $3.0$ no chão sob cada dummy.
- **Borda de Seleção Vermelha (Outline):** Silhueta espessa vermelha sólida `#ff0000` ativada ao passar o cursor sobre a área do dummy ou ao travá-lo como alvo.
- **Flash de Dano:** Ao receber impacto, o dummy pisca em branco brilhante por $0.1\text{ s}$.
- **Morte e Respawn:** Ao zerar 600 HP, tomba $90^\circ$ no chão e ressurge exatamente $3.0\text{ s}$ depois com HP cheio.

### 4. Combate, Projéteis e Feedback
- **Ataque Básico (Clique Direito ou Tecla X):**
  - Caitlyn para de andar, aponta o rifle para o alvo.
  - Windup de $0.04\text{ s}$ seguido de disparo com animação a $3.5\times$ de velocidade.
  - Projétil rosa Hextech `#ff007f` voando a $25.0\text{ m/s}$ teleguiado até o alvo.
  - Caso o inimigo esteja a $\le 3.2\text{ m}$, desfere coronhada física corpo a corpo com efeito visual de faísca amarela instantânea.
- **Números de Dano Flutuantes:**
  - Valores de dano laranjas `#ff9f00` de 26px (ou críticos vermelhos `#ff3300` de 34px com `"!"`).
  - Nascem sobre o alvo e sobem $3.2\text{ m/s}$ desvanecendo em $0.8\text{ s}$.
- **Indicador de Clique (pointTarget.glb):**
  - Símbolo verde giratório de clique que escala e desaparece em $0.35\text{ s}$.

### 5. Interface e HUD
- **Card no Topo Esquerdo:**
  - Placa escura com borda dourada exibindo Status, FPS e lista de atalhos.
- **Placas de Vida Flutuantes:**
  - Caitlyn: Caixa de nível `"5"`, barra verde de HP com divisores a cada 100 HP, barra de Mana azul, nome e valores textuais.
  - Dummies: Borda dourada, barra vermelha de HP com divisores a cada 100 HP, nome e texto `"600 / 600 (100%)"`.
- **Cursores do Mouse:**
  - Cursor clássico de MOBA (mão/manopla metálica com gema dourada/azul).
  - Espada vermelha ao passar o cursor sobre a área de ataque de um dummy.

---

## 3. Critérios de Comparação Lado a Lado (Godot vs Three.js)

Para considerar cada sistema migrado com sucesso:
1. Abrir `game-x0-moba` e `game-x1` lado a lado na mesma resolução ($1280 \times 720$).
2. Executar o mesmo comando (ex: clique direito, alternar trava, ataque com X, kiting contínuo).
3. Verificar a paridade visual (escala, ângulos, iluminação, cores) e a resposta tátil (sem atraso perceptível de clique).

---

## 4. Paridade Visual e Pipeline Gráfico Verificado (2026-10-15)

- **Antialiasing:** MSAA 2x ativo no WebGL 2.0 (`rendering/anti_aliasing/quality/msaa_3d = 1`), eliminando o aliasing de borda da Caitlyn sem o borrado do FXAA.
- **Anisotropia:** Nível 4x (`anisotropic_filtering_level = 2`) para nitidez em ângulos rasos da câmera isométrica.
- **Calibragem do Piso PBR:** Albedo calibrado para `[24, 26, 28]` no Godot vs `[23, 25, 27]` no Three.js ($\Delta \le 1$ valor RGB).
- **Sombras PCF:** Alcance ortogonal ajustado para 55.0m com viés de 0.02, garantindo sombras nítidas acopladas aos pés.
- **Tipografia:** Fonte `Outfit` com pesos 0.15/0.45 e snapping de pixel inteiro nas placas flutuantes.
- **Evidências:** Composições salvas em `docs/migration/visual/C_comparison_side_by_side.png` e detalhes em `ART_DIRECTION.md`.
