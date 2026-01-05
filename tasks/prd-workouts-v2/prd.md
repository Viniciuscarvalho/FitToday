# PRD — FitToday Workouts v2

## Visão Geral

O FitToday precisa evoluir a experiência de treino para parecer “montado por especialista” e, ao mesmo tempo, tornar a experiência mais visual e confiável. Hoje existem dois problemas centrais:

1) **Mídia de exercícios falha**: imagens/GIFs do ExerciseDB não carregam ou não estão sendo resolvidos corretamente. Isso reduz confiança e usabilidade.

2) **Geração de treinos pobre/incompleta**: o treino diário precisa ter estrutura de sessão (aquecimento, principais, acessórios, condicionamento quando fizer sentido), volume/descanso coerentes e adaptação por dor (DOMS) e foco do dia. O app já possui infraestrutura para OpenAI (`OpenAIClient`) e perfis de especialidade em `personal-active/`, mas a composição precisa ser aprimorada.

Este Workouts v2 entrega:

- **Mídia robusta** (imagem/GIF) via `v2.exercisedb.io` (sem auth), com fallback e cache.
- **Detalhe de exercício acessível**: ao tocar no exercício, abrir uma tela com execução (GIF prioritário) + instruções + prescrição (séries/reps/descanso).
- **Treino diário “completo”**: estrutura e qualidade guiadas pelos perfis:
  - `personal-active/performance.md`
  - `personal-active/força-pura.md`
  - `personal-active/emagrecimento.md`
  - `personal-active/condicionamento-fisico.md`

## Objetivos

- Elevar a qualidade percebida do treino gerado: **treinos completos, coerentes e adaptativos**.
- Aumentar a confiança do usuário no exercício com **mídia confiável** (GIF ou imagem).
- Garantir navegação clara e consistente: biblioteca e treino gerado devem permitir abrir **detalhe do exercício**.

Métricas sugeridas:

- Taxa de carregamento de mídia (sucesso vs falha) por sessão.
- Tempo médio até o usuário iniciar o treino (Home -> Questionário -> Treino).
- Engajamento: abertura de detalhe de exercício (proxy de confiança/curiosidade).
- Retenção D3/D7 e conclusão de treinos (quando aplicável).

## Histórias de Usuário

- Como **usuário Free**, eu quero ver treinos da biblioteca com exercícios que tenham **GIF/imagem de execução**, para ter confiança na técnica.
- Como **usuário**, eu quero tocar em um exercício e ver **detalhes e execução** para realizar corretamente.
- Como **usuário Pro**, eu quero um treino diário **completo e bem estruturado**, adaptado ao meu foco do dia e ao meu nível, para treinar sem precisar pensar.
- Como **usuário com DOMS alto**, eu quero que o treino seja **ajustado com segurança** (redução de volume/intensidade e troca de estímulo quando necessário) para evitar piora e manter consistência.

Casos extremos:

- Sem rede/instabilidade: mídia pode falhar; o app deve mostrar placeholder e ainda permitir treinar.
- ExerciseDB com URL inválida: deve haver fallback e logs/telemetria de falha.
- Resposta OpenAI inválida: fallback completo para geração local com validações mínimas.

## Funcionalidades Principais

### 1) Mídia de exercícios (ExerciseDB v2)

- O que faz: resolve e exibe imagem/GIF confiavelmente.
- Por que é importante: aumenta confiança e qualidade percebida.
- Como funciona: usar `exercise.id` como chave para construir URLs `https://v2.exercisedb.io/image/{id}` e priorizar GIF quando aplicável; cache via `URLCache`/`AsyncImage` e fallback.

Requisitos funcionais:

1.1 Todo exercício exibido deve tentar carregar **GIF** (preferencial) ou **imagem** (fallback).  
1.2 Em falha de rede/URL, mostrar placeholder e manter UI responsiva.  
1.3 Registrar falhas (log local) para debug.

### 2) Detalhe do exercício com execução

- O que faz: abre uma tela de detalhe ao tocar um exercício.
- Como funciona: a tela mostra mídia (GIF preferencial), nome, grupo muscular/equipamento, instruções em bullets, e prescrição (séries/reps/descanso/dica).

Requisitos funcionais:

2.1 Em Biblioteca: tocar no exercício abre detalhe do exercício (execução + instruções).  
2.2 Em Treino Gerado: tocar no exercício abre detalhe do exercício (execução + prescrição).  
2.3 A tela deve ser acessível (alvos 44pt, labels, bom contraste, texto legível).

### 3) Treino diário com qualidade “especialista” (Local + OpenAI)

- O que faz: gera treino completo e coerente a partir do perfil + check-in do dia.
- Como funciona: compõe o treino localmente com blocos/heurísticas e, quando Pro e permitido, chama OpenAI para **ajustar** seleção/ordem/volume/descanso dentro de limites, usando os guias de `personal-active/`.

Requisitos funcionais:

3.1 Treino gerado deve conter: aquecimento (quando aplicável), principais, acessórios e finalização/condicionamento quando fizer sentido ao objetivo.  
3.2 Ajustar volume/intensidade/impacto para DOMS alto conforme guias (ex.: reduzir 10–35%, evitar falha, evitar pliometria).  
3.3 OpenAI não “inventa” exercícios: apenas seleciona/ajusta dentro de catálogo existente.  
3.4 Se OpenAI falhar (timeout, erro, JSON inválido), fallback para geração local com validação mínima de completude.

### 4) Consistência de UI (Design System)

- O que faz: reforça consistência visual com tema dark e componentes existentes.
- Como funciona: usar tokens em `FitToday/FitToday/Presentation/DesignSystem/` e regras em `.cursor/skills/design/skill-design.md`.

Requisitos funcionais:

4.1 Cards/listas/botões devem usar `FitTodayColor`, `FitTodaySpacing`, `FitTodayRadius` e estilos existentes.  
4.2 Mídia deve respeitar desempenho: evitar layouts instáveis, usar tamanhos fixos e placeholders.

## Experiência do Usuário

Fluxos principais:

- Biblioteca:
  - Lista de treinos -> detalhe do treino -> lista de exercícios -> tocar em exercício -> detalhe com GIF/imagem.
- Treino diário (Pro):
  - Home -> questionário diário -> treino gerado -> tocar exercício -> detalhe com GIF/imagem + prescrição -> concluir/pular.

Considerações de UI/UX:

- Priorizar clareza e “fitness app look” (dark, alto contraste, destaque de ação primária).
- Em listas, miniaturas devem carregar rápido e ter placeholder.
- No detalhe, mídia deve ter prioridade visual (área acima da dobra).

Acessibilidade:

- Alvos mínimos 44×44.
- Labels em botões e imagens.
- Texto escalável quando possível (sem quebrar layout).

## Restrições Técnicas de Alto Nível

- iOS SwiftUI, arquitetura em camadas (Domain/Data/Presentation) no mesmo target.
- DI via Swinject.
- Navegação via Router/DeepLinks e stacks independentes por Tab.
- Mídia via `v2.exercisedb.io` sem autenticação.
- OpenAI via `OpenAIClient` existente; saída deve ser **JSON**, e deve existir fallback local.
- Respeitar padrões de código em `.cursor/rules/code-standards.md`.

## Não-Objetivos (Fora de Escopo)

- Download offline de toda biblioteca de GIFs.
- Editor avançado de treino (arrastar/soltar, customização livre).
- Chat com IA.
- Periodização avançada (mesociclos completos automatizados).

## Questões em Aberto

- A API `v2.exercisedb.io` oferece GIFs/formatos consistentes para todos os IDs do catálogo usado no app?  
- Preferência de playback: usar `AsyncImage` (GIF animado depende do sistema) ou um player dedicado (ex.: WebView/AV) quando necessário?  
- Regras exatas de “surpreenda-me”: deve seguir objetivo do perfil ou randomizar entre objetivos?  


