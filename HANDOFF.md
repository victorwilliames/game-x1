# HANDOFF — memória operacional do game-x1

**Atualizado por:** ChatGPT (tech lead) em 2026-10-15
**Situação:** Etapa 0 em andamento no Windows local; GitHub ainda sem código Godot nesta revisão.
**Branch remota verificada:** `main` em `9778de3` (antes deste handoff).
**Confiabilidade:** as declarações de execução abaixo vieram do relatório do Antigravity fornecido pelo usuário. **Ainda não foram comprovadas via GitHub, logs ou execução por ChatGPT.**

## Último relato do Antigravity (local, ainda não publicado)

- **Reportado, não verificado remotamente:** Godot 4.7.2 instalado/reconhecido via WinGet; templates Web instalados.
- **Reportado, não verificado remotamente:** cena 3D com chão/colisão, luz e céu, marcador central, câmera inclinada e HUD de FPS.
- **Reportado, não verificado remotamente:** `scripts/run.ps1`, `scripts/test.ps1`, `scripts/export_web.ps1` e `scripts/serve_web.ps1` criados.
- **Reportado, não verificado remotamente:** teste headless concluiu com sucesso e exportação Web gerou arquivos HTML, WASM e PCK.
- **Não verificado:** execução **no navegador**, captura visual real, ausência de erros de JavaScript/console, funcionamento correto de input e HUD.
- **Não publicado:** no GitHub, não há `project.godot`, cenas, scripts Godot ou scripts PowerShell deste relato.
- **Estado exato da árvore de trabalho local:** desconhecido; o Antigravity deve conferir com `git status`.

## Próximas ações (nesta ordem)

1. Retomar sem reinstalar ferramentas nem refazer trabalho local já concluído. Verificar os arquivos existentes, o estado do Git e possíveis processos pendentes; evitar downloads duplicados.
2. Executar a versão Web por `scripts/serve_web.ps1` (verificar nome/caminho reais), testar **em navegador com renderização gráfica** e capturar evidência. Verificar cena, câmera, HUD/FPS, input básico e console do navegador; corrigir apenas problemas que impeçam o teste.
3. Caso não haja controle automatizado de navegador disponível, **não afirmar teste visual aprovado**: abrir/fornecer URL e solicitar validação humana ou produzir capturas por ferramenta visual realmente disponível. Registrar a limitação.
4. Executar novamente os testes mínimos e exportação se necessário, registrando **comandos efetivamente rodados, resultado, versão da Godot e arquivos de saída**. Teste headless e exportação não equivalem a playtest gráfico.
5. Atualizar `PROGRESS.md` exclusivamente com verificações concluídas e este `HANDOFF.md` com o estado real.
6. Sincronizar a `main` remota com cuidado, preservando mudanças locais. Commitar e fazer push de projeto/scripts/testes/documentação, **sem** diretórios gerados `.godot/` ou `build/`; informar SHA do commit.
7. Só após validação e publicação planejar a Etapa 1 (boneco-palito 3D articulado, Idle/Run e movimentação). **Não iniciar a Etapa 1 neste handoff.**

## Como manter esta memória

Após cada incremento relevante ou antes de pausar, o Antigravity deve substituir o resumo acima por um relatório curto e atualizado:

- **Estado:** etapa, objetivo, andamento e bloqueio (se existir).
- **Git:** branch, commit remoto, arquivos locais modificados/não commitados, push pendente.
- **Feito:** funcionalidades efetivamente implementadas, sem inferir validação.
- **Testado:** comandos exatos, resultados e evidência; separar headless/exportação/navegador.
- **Problemas:** bugs reproduzíveis, mensagens úteis e próximos riscos.
- **Próxima ação:** **uma** tarefa clara que permita a outro agente retomar em minutos.

Não preencher o arquivo com transcrição de conversa nem declarar sucesso sem comprovação. Não usar esta memória como substituto para commits ou `PROGRESS.md`.
