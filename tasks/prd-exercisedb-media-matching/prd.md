# Template de Documento de Requisitos de Produto (PRD)

## Visão Geral

Hoje, muitos exercícios não exibem imagem/GIF porque o nome do exercício no app não corresponde exatamente ao nome no ExerciseDB (RapidAPI). Isso gera uma UX “quebrada” (placeholder) e reduz a confiança do usuário.

Esta funcionalidade melhora a **assertividade e cobertura** da mídia, normalizando e “equalizando” chamadas na API do ExerciseDB para encontrar `exerciseId` de forma consistente e então buscar a imagem via endpoint `/image` (com `resolution` e `exerciseId`).

## Objetivos

- Aumentar a **cobertura de mídia**: reduzir drasticamente a quantidade de exercícios exibindo placeholder (ex.: “Lever Pec Deck Fly”).
- Garantir que o match de mídia seja **determinístico** (mesma entrada → mesmo `exerciseId` escolhido), com cache para reduzir chamadas.
- Manter a integração segura: **sem expor RapidAPI key** (Keychain) e com timeouts/erros tratados.

Métricas de sucesso (medidas em debug e/ou analytics futuro):
- % de exercícios com mídia resolvida (imagem ou GIF) em telas de lista e detalhe.
- Taxa de erro/timeout do ExerciseDB por sessão.
- Tempo médio para primeira mídia (TTFI) em tela de detalhe.

## Histórias de Usuário

- Como usuário, eu quero ver uma imagem/GIF no detalhe do exercício para entender rapidamente o movimento.
- Como usuário, eu quero que a mídia apareça na maior parte dos exercícios, mesmo que não seja uma correspondência perfeita de nome, para não ver placeholders.
- Como desenvolvedor, eu quero regras de match previsíveis e cacheadas para diagnosticar facilmente quando um exercício não encontra mídia.

## Funcionalidades Principais

1) Resolução de mídia por “tipo” (target) com fallback
- O app deve consultar a lista de targets disponíveis no ExerciseDB (ex.: bíceps, peitoral etc.) e cachear localmente.
- Para cada exercício do catálogo local, o app deve derivar um `target` provável (baseado em `MuscleGroup` e/ou heurísticas) e buscar candidatos por target no ExerciseDB.
- O app deve escolher um candidato usando um ranking simples (equipamento + similaridade de nome) priorizando **cobertura**.
- Caso não haja candidatos por target, o app deve fazer fallback para busca por nome (método atual), ainda com heurísticas para aumentar match.

Requisitos funcionais:
1.1 O app deve buscar `GET /exercises/targetList` e cachear os targets por um período configurável (ex.: 7 dias) ou até limpeza manual em debug.
1.2 O app deve buscar candidatos via `GET /exercises/target/{target}` quando tiver um target válido.
1.3 O app deve persistir o mapeamento `localExerciseId -> exerciseDBId` para evitar buscar repetidamente.
1.4 O app deve resolver imagem via `GET /image?resolution={resolution}&exerciseId={exerciseId}` com resolução adequada ao contexto (thumbnail/card/detail).
1.5 O app deve ter fallback robusto (erro de rede, 404, timeout): usar placeholder sem travar a UI.

2) Ferramentas de validação (debug)
- Em builds DEBUG, permitir limpar cache de mapping e forçar re-resolução (já existe no Perfil, modo debug).
- Logs DEBUG devem explicar “por que escolheu” o candidato (query/target/ranking).

Requisitos funcionais:
2.1 Deve existir uma forma de limpar o mapping de ExerciseDB e refazer o match para validação em device.
2.2 Logs DEBUG devem registrar: target derivado, número de candidatos, candidato escolhido e razão (score).

## Experiência do Usuário

- Na tela de detalhe do exercício, ao abrir:
  - se houver mídia resolvida, exibir imagem/GIF.
  - se não houver, exibir placeholder, sem bloquear o restante do conteúdo (prescrição/instruções).
- Em listas/cards, usar resolução mais baixa (melhor performance) e cache.

Acessibilidade:
- Caso a mídia esteja indisponível, o conteúdo textual (nome, músculos, instruções) deve continuar acessível e legível.

## Restrições Técnicas de Alto Nível

- A integração deve usar a RapidAPI key via **Keychain** (sem chaves hardcoded/commitadas).
- Respeitar timeouts e evitar excesso de chamadas (cache e/ou prefetch controlado).
- Manter compatibilidade com a arquitetura atual (SwiftUI + services em Data layer).

## Não-Objetivos (Fora de Escopo)

- Não é objetivo garantir match perfeito 100% “exato” de nome para todos os exercícios (prioridade é cobertura).
- Não inclui criar/editar manualmente uma base de mapeamentos via UI para o usuário final (apenas debug).
- Não inclui analytics/telemetria em produção nesta fase (pode ser adicionado depois).

## Questões em Aberto

- Quais targets oficiais do ExerciseDB devem ser priorizados para cada `MuscleGroup` do domínio (ex.: peito → “pectorals” vs “chest”)?
- Política de cache: por quanto tempo manter `targetList` e mappings antes de invalidar automaticamente?



