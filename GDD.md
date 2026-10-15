# GDD — game-x1 (Port 1:1 de game-x0-moba)

**Status:** Documento de Especificação da Migração 1:1 para Godot 4 (Branch: `port/game-x0-1to1`).  
**Fonte da verdade:** `game-x0-moba` (código Three.js/TypeScript e gameplay aprovado).

---

## 1. Visão do Projeto

O objetivo do `game-x1` nesta branch é realizar a **migração integral e reprodução fiel do jogo `game-x0-moba`** para Godot 4.
Não estamos criando um novo jogo ou outra interpretação do gênero MOBA: estamos reconstruindo a recriação já aprovada pelo proprietário no motor Godot, garantindo que ambas as versões sejam visual e funcionalmente idênticas.

---

## 2. Cenário e Arena

- **Dimensões:** Piso plano $80 \times 80$ metros na cor cinza escuro `#0a1016`.
- **Fundo:** `#03070c`.
- **Grid de Desenvolvimento:**
  - Células quadradas de $2 \times 2$ metros.
  - Linhas primárias douradas `#c29d53`, linhas secundárias azul ardósia `#162838`.
- **Limites da Câmera:** Área visível restrita a $\pm 38$ metros nos eixos X e Z.
- **Iluminação:**
  - Luz ambiente `#121b26` (intensidade 1.5).
  - Luz direcional `#ffffff` (intensidade 2.0 em $(20, 40, 20)$ com projeção de sombras no chão).

---

## 3. Personagem Jogável (Caitlyn)

- **Modelo 3D:** Modelo completo da Caitlyn (`CaitlynComplete.glb`), escala $0.055$.
- **Atributos:**
  - Vida: $1072$ HP.
  - Velocidade de Movimento: $16.0\text{ m/s}$.
  - Alcance de Ataque: $18.0\text{ metros}$.
  - Velocidade de Ataque Base: $1.85\text{ ataques/s}$.
  - Dano Base: $55$ (25% de chance de crítico para $96$).
- **Movimentação:**
  - Clique direito no chão define destino.
  - Transição imediata entre Idle e Run.
  - Animação de corrida acelerada a $2.5\times$ de velocidade.
  - Rotação suave em direção ao vetor de deslocamento (`diff * 0.25` por frame).
- **Combate e Kiting:**
  - Windup de $0.04\text{ s}$ e tempo de animação de tiro de $0.12\text{ s}$ (acelerada a $3.5\times$).
  - Disparo de projétil Hextech rosa `#ff007f` a $25.0\text{ m/s}$ (teleguiado ao alvo).
  - Ataque corpo a corpo automático a $\le 3.2\text{ m}$ (coronhada com dano instantâneo e faísca amarela).
  - **Mecânica de Kiting:** Cliques rápidos no ritmo de $0.10\text{ s}$ a $0.42\text{ s}$ concedem $+15\%$ a $+45\%$ de velocidade de ataque por $1.0\text{ s}$ e reduzem $0.14\text{ s}$ do cooldown restante.
  - Cancelamento imediato de animação ao clicar no chão para andar.

---

## 4. Inimigos (Dummies de Teste)

1. **Dummy Estático:** Posição $(7, 0, 7)$, $600$ HP.
2. **Dummy Móvel:** Posição $(-7, 0, 7)$, $600$ HP, move-se a $2.5\text{ m/s}$ no eixo X oscilando $\pm 8.0\text{ m}$ e girando $180^\circ$.
- **Visual:** Cápsula vermelha escura `#9e2a2b` com dois olhos vermelhos brilhantes `#ff3b30`.
- **Outline:** Contorno espesso vermelho puro `#ff0000` ativado em hover do mouse ou seleção.
- **Círculo de Tolerância:** Anel roxo no chão com raio de $3.0\text{ m}$ facilitando cliques no alvo.
- **Reação:** Flash branco por $0.1\text{ s}$ ao receber dano. Tomba $90^\circ$ ao morrer e ressurge após $3.0\text{ s}$.

---

## 5. Controles e Entradas

| Comando | Entrada | Ação |
| :--- | :--- | :--- |
| **Mover / Atacar** | Botão Direito | Clicar no chão move; clicar no dummy (ou na área roxa de $3.0\text{ m}$) ataca. |
| **Attack Move** | Tecla `A` + Clique Esquerdo | Exibe círculo vermelho de alcance e ataca o inimigo mais próximo do clique. |
| **Ataque Direcional** | Tecla `X` | Disparo direcional na direção do cursor (estilo Wild Rift). |
| **Trava de Câmera** | Tecla `Y` | Alterna entre câmera travada no campeão e câmera livre. |
| **Centralizar Câmera**| `Espaço` ou `'` (Quote) | Centraliza suavemente a visão na Caitlyn. |
| **Arrastar Câmera** | Botão do Meio (MMB) | Arrasta o cenário com deslocamento livre. |
| **Edge Scrolling** | Bordas da tela ($\le 18\text{px}$) | Desloca a câmera livre a $40\text{ unidades/s}$. |

---

## 6. Interface (HUD) e Feedback Visual

- **Placa da Caitlyn:** Nível "5", barra de HP verde com ticks pretos a cada 100 HP, barra de Mana azul, nome e valores textuais.
- **Placa dos Dummies:** Borda dourada, barra vermelha de HP com ticks a cada 100 HP, nome e texto quantitativo.
- **Números de Dano:** Laranja `#ff9f00` (26px) para acertos comuns e vermelho `#ff3300` (34px) com `"!"` para críticos.
- **Indicador de Clique:** Modelo `pointTarget.glb` verde `#00ff88` giratório desvanecendo em $0.35\text{ s}$.
- **Cursores Customizados:** Cursores oficiais de League of Legends (`normal.cur`, `alt.cur`, `link.cur`).
