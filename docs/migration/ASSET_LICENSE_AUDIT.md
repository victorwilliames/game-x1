# Auditoria de Assets e Licenças — Migração game-x0-moba

Este documento registra a proveniência, direitos e status de uso de todos os assets identificados no repositório `game-x0-moba`.

---

## 1. Diretriz de Uso dos Assets

O objetivo desta migração é a **reprodução técnica 1:1 em ambiente local** da experiência já desenvolvida e aprovada pelo proprietário no protótipo `game-x0-moba`.

> [!IMPORTANT]
> **Diferenciação Estrita de Ambientes:**
> - **Ambiente Local de Desenvolvimento:** Utiliza os assets originais existentes na máquina do desenvolvedor para assegurar fidelidade geométrica, proporções e animações idênticas às do `game-x0`.
> - **Distribuição Pública:** Qualquer publicação pública futura deverá observar as políticas de propriedade intelectual de terceiros ou utilizar substitutos homologados.

---

## 2. Inventário de Assets e Status de Licença

| Recurso | Caminho de Origem | Propriedade / Licença | Status no Jogo | Tratamento na Migração |
| :--- | :--- | :--- | :---: | :--- |
| **Caitlyn (`CaitlynComplete.glb`)** | `assets/Personagens Principais/caitlyn/source/` | Riot Games (Proprietário / Fair Use para estudo local) | **ATIVO** (Heroína principal) | Copiado e utilizado localmente para paridade 1:1 de malha, esqueleto e animações. |
| **Indicador de Clique (`pointTarget.glb`)** | `assets/UI/rts-target/source/` | Asset 3D livre / Interface RTS | **ATIVO** (Feedback de clique) | Importado para o Godot para animação idêntica de clique verde. |
| **Ponteiros do Mouse (`*.cur`)** | `assets/UI/pointers/` | Riot Games / League of Legends Interface | **ATIVO** (Cursores) | Utilizados como cursores customizados no Godot. |
| **Master Yi (`masteryi.glb`)** | `assets/Personagens Principais/master-yi/source/` | Riot Games (Proprietário) | *INATIVO* (Roadmap futuro) | **Não migrar nesta fase**. |
| **Minions HotS (`*.glb`)** | `assets/Inimigos/Minions/...` | Blizzard Entertainment (Heroes of the Storm) | *INATIVO* (Roadmap futuro) | **Não migrar nesta fase**. |
| **Mapa 5v5 (`scene.gltf` / `scene.bin`)** | `assets/Mapa/5v5_game_map/` | Sketchfab / Licença CC-BY-NC | *INATIVO* (Não usado no gameplay v0) | **Não migrar nesta fase**. O cenário do game-x0 é o piso de desenvolvimento $80 \times 80$. |

---

## 3. Procedimento de Cópia e Não-Destruição

- Os arquivos originais em `C:\.PROJETOS - Sites 2026\godot\game-x0-moba\assets` permanecem intactos e inalterados.
- Os arquivos necessários são copiados para a árvore de recursos do Godot (`res://assets/...`) sem modificação destrutiva das fontes.
