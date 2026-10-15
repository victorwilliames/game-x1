# Direção de Arte e Visual — game-x1 (Branch: port/game-x0-1to1)

**Regra vigente nesta branch:** Paridade visual 1:1 com o protótipo aprovado **`game-x0-moba`**.
A antiga exigência de "apenas bonecos-palito e arte provisória" está revogada para esta migração, conforme ordem explícita do proprietário.

---

## 1. Identidade Visual da Referência (game-x0-moba)

O visual do jogo deve reproduzir exatamente o que é renderizado no `game-x0-moba`:

1. **Cenário de Testes:**
   - Fundo escuro azulado `#03070c`.
   - Piso de desenvolvimento cinza ardósia `#0a1016` ($80 \times 80\text{ m}$).
   - Grid técnico com linhas primárias douradas `#c29d53` e secundárias azul escuro `#162838`.
   - Iluminação direcionada e suave com projeção de sombras PBR.

2. **Personagem Jogável (Caitlyn):**
   - Modelo oficial completo (`CaitlynComplete.glb`) na escala $0.055$.
   - Texturas PBR originais e materiais fiéis à versão de referência.
   - Animações oficiais de Idle, Run e Attack integradas com sincronismo de velocidade e kiting.

3. **Inimigos (Dummies):**
   - Cápsulas estilizadas em vermelho escuro `#9e2a2b` com olhos em `#ff3b30`.
   - Contorno vermelho puro `#ff0000` espesso para feedback de seleção e hover.
   - Círculo roxo de tolerância no chão (`#aa00ff`, raio $3.0\text{ m}$).

4. **Interface (HUD e Overlays):**
   - Placa de campeão inspirada no League of Legends (quadrado de nível 5, barra de vida verde, mana azul, divisores a cada 100 HP).
   - Barras de vida de inimigos com moldura dourada e barra vermelha.
   - Números de dano flutuantes em fonte estilo Outfit (laranja e vermelho crítico).
   - Marcador verde de clique rotativo (`pointTarget.glb`).
   - Cursores customizados de MOBA (`normal.cur`, `alt.cur`, `link.cur`).

---

## 2. Princípios de Implementação no Godot 4

- Renderizador `Compatibility` (WebGL 2.0 / OpenGL 3.3).
- Carregamento nativo dos arquivos `.glb` sem dependências externas.
- Preservação da alta taxa de quadros (meta de 120 FPS em monitores de 120 Hz).
