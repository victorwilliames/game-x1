# Engenharia Reversa Completa — game-x0-moba

Este documento detalha o mapeamento arquitetural, sistemas, entidades, constantes numéricas, dependências e regras de gameplay efetivamente implementadas e ativas no jogo de referência **`game-x0-moba`** (Three.js + TypeScript + Vite).

---

## 1. Visão Geral e Pilha Tecnológica de Origem

- **Motor / Framework:** Three.js `v0.160.0`, TypeScript `v5.2.2`, Vite `v5.0.0`.
- **Ponto de entrada:** `jogo/src/main.ts` -> instancia `Game` e chama `game.init()`.
- **Canvas / Loop:** `renderer.setAnimationLoop(this.animate.bind(this))` com `clock.getDelta()` clampado em máximo `0.1s`.
- **Resolução / PixelRatio:** `renderer.setPixelRatio(1.0)` fixo para máximo desempenho (meta 120 FPS).
- **Cor de Fundo da Cena:** `#03070c`.

---

## 2. Mapa de Sistemas e Arquivos Ativos

```
jogo/src/
├── main.ts              # Inicialização do DOM e bootstrapping da classe Game
├── Game.ts              # Orquestrador central: cena, luzes, chão, raycast, loop, HUD e FX
├── Camera.ts            # Câmera isométrica (FOV 38°), modos Locked/Free, Edge Pan, Drag
├── Input.ts             # Mapeamento de teclado/mouse, Pointer Lock e cursor visual
├── Targeting.ts         # Seleção inteligente em 2 etapas (cursor primeiro, proximidade depois)
└── entities/
    ├── Character.ts     # Caitlyn: modelo GLB, animações, estados, kiting, ataque melee/ranged
    ├── Dummy.ts         # Inimigos: cápsula vermelha, outline 3D, círculo roxo, vida, morte, respawn
    └── Projectile.ts    # Bala Hextech rosa: perseguição teleguiada ou disparo livre, colisão
```

---

## 3. Câmera (`Camera.ts`) — Parâmetros e Comportamento 1:1

- **Projeção:** `PerspectiveCamera(38, aspect, 1, 1000)`.
- **Posição Base (Offset):** `(0, 56, 48)` em relação ao `cameraTarget`.
  - Altura $Y = 56$, recuo $Z = 48$.
  - Inclinação (Pitch): $\arctan(56 / 48) \approx 49,4^\circ$ olhando para o chão em direção a $-Z$.
- **Modo Padrão:** `isLocked = true` (inicia travada no campeão).
- **Folga Dinâmica com Mouse (Mouse Ratio Offset):**
  - Calcula a razão do cursor em relação ao centro da tela:
    $$\text{ratioX} = \frac{\text{mouseX} - \frac{W}{2}}{\frac{W}{2}}, \quad \text{ratioY} = \frac{\text{mouseY} - \frac{H}{2}}{\frac{H}{2}}$$
  - Deslocamento máximo da folga: `maxLockOffset = 6.0` unidades.
  - $\text{target.x} = \text{playerPos.x} + \text{ratioX} \times 6.0$
  - $\text{target.z} = \text{playerPos.z} + \text{ratioY} \times 6.0$
  - Suavização: `cameraTarget.lerp(tempTarget, 0.08)`.
- **Modo Livre (`isLocked = false`):**
  - **Edge Scrolling:** Ativa se cursor estiver a $\le 18\text{px}$ das bordas. Velocidade = $40\text{ unidades/s}$.
  - **Arrasto com Botão do Meio (MMB Drag):** $\Delta X, \Delta Y$ multiplicados por `dragSpeed = 0.05 * currentZoom`.
- **Limites da Câmera no Cenário:** Clampa $X \in [-38, 38]$ e $Z \in [-38, 38]$.
- **Controles de Câmera:**
  - Alternar trava (`ToggleCameraLock`): Tecla `Y` (toggle em keydown).
  - Centralizar temporariamente (`CenterCamera`): Tecla `'` (Quote / Apóstrofo) no código de origem (`Input.ts`), descrita como `Espaço` no HUD. Na versão Godot, ambas devem acionar `CenterCamera`.
  - Zoom manual: `handleZoom()` está **desabilitado/comentado** no código original para preservar distância constante.

---

## 4. Personagem / Caitlyn (`Character.ts`)

- **Asset 3D:** `assets/Personagens Principais/caitlyn/source/CaitlynComplete.glb`.
- **Escala no Mundo:** `scale.set(0.055, 0.055, 0.055)`.
- **Posição Inicial:** `(0, 0, 0)`.
- **Atributos:**
  - `speed = 16.0`
  - `maxHp = 1072`, `hp = 1072`
  - `attackRange = 18.0`
  - `attackSpeed = 1.85` (ataques por segundo base)
  - `height = 3.5` (offset da barra de vida: $+5.2$ em $Y$)
- **Estados:** `IDLE`, `WALKING`, `ATTACKING`.
- **Animações (Mixer & TimeScales):**
  - `idle`: `idle1.anm` ou `idle.anm` (loop infinito, crossfade 0.25s).
  - `run`: `run.anm` com `timeScale = 2.5` fixo.
  - `attack`: `attack1.anm` ou `attack2.anm` com `timeScale = 3.5 * (1.0 + attackSpeedBonus)` (disparo super ágil).
- **Mecânica de Rotação Suave:**
  - $\text{targetAngle} = \text{atan2}(\text{dir.x}, \text{dir.z})$.
  - Interpolação angular frame a frame: `rotationY += diff * 0.25` (com unwrapping de $-\pi$ a $+\pi$).
- **Mecânica Avançada de Kiting & Combate:**
  - `attackWindupTimer = 0.04s` (tempo de preparação antes do projétil nascer).
  - `attackAnimTimer = 0.12s` (tempo total travado na animação de tiro).
  - `isAttackWindupTriggered`: após 0.04s, dispara o projétil via callback `onShoot`.
  - **Cancelamento de Ataque (`cancelAttack`):** Movimentar cancela a animação e retorna imediatamente para `IDLE`/`WALKING`.
  - **Bônus por Cliques Rápidos (Kiting Frenético):**
    - Se intervalo entre cliques estiver entre $0.10s$ e $0.42s$, acumula até 3 cliques rápidos (`consecutiveFastClicks`).
    - Bônus: $+15\%$ por clique rápido (máximo $+45\%$ de velocidade de ataque). Duração do bônus: $1.0s$.
    - Se clicar enquanto estiver em cooldown e o windup já passou: **reduz o cooldown restante em $0.14s$ (140 ms)** por clique rápido.
  - **Ataque Melee (Coronhada de Rifle):**
    - Se alvo estiver a $\le 3.2$ unidades de distância, não gera projétil: aplica dano instantâneo de 55 com efeito visual de faísca amarela (`spawnMeleeSlashEffect`).

---

## 5. Inimigos / Dummies (`Dummy.ts`)

- **Instâncias no Jogo:**
  1. **Dummy Estático:** Posição inicial `(7, 0, 7)`.
  2. **Dummy Móvel:** Posição inicial `(-7, 0, 7)`.
- **Movimentação do Móvel:**
  - `moveSpeed = 2.5` no eixo $X$.
  - Inverte direção ao atingir $\pm 8.0$ unidades de deslocamento a partir de `startX` (rotação em $Y = 0$ ou $\pi$).
- **Geometria e Visual:**
  - Corpo: `CapsuleGeometry(0.7, 1.5, 8, 16)` na cor vermelha escura `#9e2a2b` em $Y = 1.45$.
  - Olhos: dois `BoxGeometry(0.15, 0.15, 0.25)` na cor `#ff3b30` em $(\pm 0.25, 2.0, 0.55)$.
  - **Outline Vermelho (Borda do LoL):** `CapsuleGeometry(0.85, 1.65, 8, 16)` com `BackSide` puro `#ff0000`. Visível quando selecionado ou em hover do mouse.
  - **Círculo de Tolerância de Clique (Roxo):**
    - Disco no chão com raio $3.0$ unidades (`RingGeometry(0, 3.0)` com opacidade 0.04 e borda `RingGeometry(2.96, 3.0)` com opacidade 0.35, cor `#aa00ff`).
- **Vida e Respawn:**
  - `maxHp = 600`, `hp = 600`.
  - Dano recebido: flash branco puro em todos os materiais por $0.1s$.
  - Morte: deita o dummy no chão (`rotation.z = Math.PI / 2`, `position.y = 0.2`), desativa tolerância e outline.
  - Respawn: $3.0s$ após a morte, regenera 100% do HP, restaura rotação e retorna a `startX`.

---

## 6. Projétil (`Projectile.ts`)

- **Visual:** `SphereGeometry(0.12, 8, 8)` rosa Hextech brilhante `#ff007f`.
- **Origem:** Posição da Caitlyn $+ 1.85$ em $Y$.
- **Velocidade:** $25.0$ unidades/s.
- **Alcance Máximo:** $40.0$ unidades.
- **Dano:** Base 55 (com chance de 25% de crítico causando $55 \times 1.75 \approx 96$).
- **Modos:**
  1. *Teleguiado (Homing):* Se criado com alvo ativo, ajusta vetor em tempo real na direção do dummy. Se dummy morrer em voo, segue em linha reta na última direção.
  2. *Livre (Skillshot / Wild Rift):* Segue o vetor direcional `tempDirection`. Colide com dummies no raio $(0.7 + 0.12) = 0.82$ unidades.

---

## 7. Sistema de Alvos (`TargetingSystem.ts`)

- **Prioridade 1:** Dummy mais próximo do cursor do mouse, com tolerância máxima de raio $5.0$ unidades ($\text{distSq} < 25.0$).
- **Prioridade 2:** Se nenhum dummy estiver perto do cursor, seleciona o dummy ativo mais próximo da Caitlyn que esteja dentro de `attackRange = 18.0`.

---

## 8. Cenário, Iluminação e Efeitos 3D (`Game.ts`)

- **Chão:** Plano de $80 \times 80$ unidades na cor `#0a1016` (rugosidade 0.8, metalicidade 0.1) em $Y = 0$.
- **Grid de Desenvolvimento:** `GridHelper(80, 40, '#c29d53', '#162838')`:
  - 40 subdivisões em 80 unidades = células de $2 \times 2$ unidades.
  - Eixos principais em dourado `#c29d53` e linhas secundárias em azul ardósia escuro `#162838`.
  - Posição vertical: $Y = 0.01$.
- **Iluminação:**
  - Luz ambiente: `#121b26`, intensidade 1.5.
  - Luz direcional: cor `#ffffff`, intensidade 2.0, posição $(20, 40, 20)$ apontando para a origem.
  - Sombras: mapa $1024 \times 1024$, câmera ortográfica com tamanho $d = 30$, bias $-0.0005$.
- **Indicador de Alcance de Ataque:** Círculo verde no chão centrado no jogador (`RingGeometry(17.92, 18.08)`), opacidade 0.12 (muda para vermelho `#ff0055` e opacidade 0.35 quando em modo Attack Move `KeyA`).
- **Marcador de Alvo Selecionado:** Anel vermelho `#ff3b30` pulsante no chão sob o alvo (`RingGeometry(0.75, 0.95)`), escala oscila com $\sin(\text{time} \times 0.01) \times 0.1$.
- **Linha de Mira (Ataque Direcional com X):** Linha verde de 0 a 18 unidades apontando do jogador para o cursor.
- **Indicador de Clique Verde:** Modelo `assets/UI/rts-target/source/pointTarget.glb` tingido de verde `#00ff88` (escala 1.5), rotaciona $6\text{ rad/s}$ e desvanece em $0.35s$.

---

## 9. Interface e HUD (`style.css` + HTML)

- **Fonte:** `Outfit`, sans-serif.
- **Card de Status (Superior Esquerdo):**
  - Fundo translúcido `rgba(6, 12, 19, 0.85)` com `backdrop-filter: blur(10px)`.
  - Borda dourada `1px solid rgba(194, 157, 83, 0.4)`.
  - Itens: Status, FPS, Controles (Botão direito, X, A, Y, Space, Scroll/MMB).
- **Barras de Vida Flutuantes:**
  - **Jogador (Caitlyn):**
    - Placa LoL com quadrado de nível `"5"` (`#122436` com borda `#c29d53` e texto `#00ffcc`).
    - Barra de HP verde `#2ecc71` com divisores (ticks) pretos a cada 100 HP.
    - Barra de Mana azul `#00bfff` logo abaixo da de HP.
    - Textos no topo: nome `"Caitlyn"` e vida quantitativa `"1072 / 1072 (100%)"`.
  - **Inimigos (Dummies):**
    - Borda dourada `#c29d53` de 1.5px.
    - Barra de HP vermelha gradiente `#e74c3c` com ticks de 100 HP.
    - Nome `"Dummy (Estático)"` ou `"Dummy (Móvel)"` no topo.
    - Vida quantitativa `"600 / 600 (100%)"` em `#00ffcc`.
- **Números de Dano Flutuantes:**
  - Laranja LoL `#ff9f00` (tam 26px) para acertos normais, ou vermelho `#ff3300` com `!` (tam 34px) para críticos.
  - Contorno preto sólido de 2.5px.
  - Sobem $3.2$ unidades/s e duram $0.8s$.
- **Cursores Customizados:**
  - `normal.cur`: cursor dourado/azul padrão de League of Legends.
  - `alt.cur`: espada vermelha de ataque ao passar sobre a área roxa do dummy.
  - `link.cur`: mãozinha para interações.

---

## 10. Inventário de Recursos Ativos vs. Inativos

| Recurso | Origem | Status no game-x0 | Uso na Migração Godot |
| :--- | :--- | :---: | :---: |
| `CaitlynComplete.glb` | `assets/Personagens Principais/caitlyn/source/` | **ATIVO** (Heroína principal) | **OBRIGATÓRIO** (Importar no Godot) |
| `pointTarget.glb` | `assets/UI/rts-target/source/` | **ATIVO** (Indicador de clique) | **OBRIGATÓRIO** (Importar no Godot) |
| Cursores (`.cur`) | `assets/UI/pointers/` | **ATIVO** (Normal, Attack, Link) | **OBRIGATÓRIO** (Converter/Configurar) |
| `masteryi.glb` | `assets/Personagens Principais/master-yi/source/` | *INATIVO* (Roadmap Fase 3) | Não instanciar nesta fase |
| Minions HotS (`.glb`) | `assets/Inimigos/Minions/...` | *INATIVO* (Roadmap Fase 4) | Não instanciar nesta fase |
| Mapa 5v5 (`scene.gltf`)| `assets/Mapa/5v5_game_map/` | *INATIVO* (Não usado na v0) | Não instanciar nesta fase |
