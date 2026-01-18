# PRD: Otimização de Qualidade de Treinos e Integração Apple Health

## Overview

O FitToday atualmente gera treinos personalizados usando composição híbrida (Local + OpenAI) baseada em 3 perguntas do usuário. Apesar de funcional, os treinos gerados apresentam problemas de **repetitividade** e **excesso de exercícios**, impactando a experiência do usuário.

Este PRD define melhorias para: (1) otimizar a qualidade dos treinos via prompt OpenAI aprimorado, (2) implementar cache persistente para ExerciseDB, (3) completar a integração bidirecional com Apple Health, e (4) adicionar sistema de feedback que alimenta composições futuras.

## Objectives

| Objetivo | Métrica | Meta |
|----------|---------|------|
| Qualidade dos treinos | Avaliação média do usuário | +100% (2x melhor) |
| Redução de repetição | Exercícios únicos por semana | >80% únicos |
| Eficiência de API | Chamadas ExerciseDB/mês | <100 (atual ~50) |
| Completude de dados | Treinos com métricas HealthKit | >90% |
| Engajamento | Usuários que avaliam treinos | >60% |

## User Stories

**US1 - Treinos Variados**: Como usuário, quero receber treinos com exercícios variados para não fazer os mesmos movimentos toda semana.

**US2 - Quantidade Adequada**: Como usuário, quero treinos com quantidade apropriada de exercícios (não excessiva) para completar em tempo razoável.

**US3 - Sincronização Health**: Como usuário, quero que meus treinos sincronizem automaticamente com o Apple Health para ter meu histórico unificado.

**US4 - Visualizar Progresso**: Como usuário, quero ver minha frequência de treinos e calorias queimadas em comparativos semanais/mensais.

**US5 - Avaliar Treino**: Como usuário, quero avaliar o treino após completá-lo para que o app aprenda minhas preferências.

## Core Features

### F1. Otimização do Prompt OpenAI

**O que faz**: Reestrutura o prompt enviado à OpenAI para gerar treinos mais variados e com quantidade adequada de exercícios.

**Por que é importante**: Resolve o problema principal de repetitividade e excesso de exercícios.

**Requisitos Funcionais**:
- **F1.1**: O prompt deve incluir lista explícita de exercícios dos últimos 7 dias para evitar repetição
- **F1.2**: O prompt deve especificar limites claros de exercícios por fase (ex: warmup=2-3, strength=4-6)
- **F1.3**: O prompt deve considerar avaliações anteriores do usuário (muito fácil/difícil)
- **F1.4**: O sistema deve validar que ≥80% dos exercícios são diferentes dos últimos 3 treinos
- **F1.5**: O prompt deve incluir variação por padrão de movimento (push/pull/hinge/squat)

### F2. Cache Persistente ExerciseDB

**O que faz**: Armazena exercícios e mídias da ExerciseDB em SwiftData para reduzir chamadas à API.

**Por que é importante**: Garante operação dentro do limite de 200 requisições/mês.

**Requisitos Funcionais**:
- **F2.1**: Exercícios buscados devem ser persistidos em SwiftData com TTL de 30 dias
- **F2.2**: URLs de imagens/GIFs devem ser cacheados junto com os exercícios
- **F2.3**: O sistema deve verificar cache local antes de qualquer chamada à ExerciseDB
- **F2.4**: Exercícios sem imagem no cache podem ser enriquecidos em background (batch)
- **F2.5**: Dashboard de uso da API deve mostrar requisições restantes do mês

### F3. Integração Apple Health Bidirecional

**O que faz**: Exporta treinos completados para o Apple Health e importa métricas (calorias, duração).

**Por que é importante**: Unifica dados de saúde do usuário e fornece métricas precisas.

**Requisitos Funcionais**:
- **F3.1**: Treinos completados devem ser exportados automaticamente para HealthKit
- **F3.2**: Calorias queimadas devem ser lidas do HealthKit após o treino (se disponível)
- **F3.3**: Duração real do treino deve ser registrada (tempo de início até conclusão)
- **F3.4**: Cada treino exportado deve incluir metadata "FitToday" para identificação
- **F3.5**: Usuário pode habilitar/desabilitar sincronização nas configurações

### F4. Schema de Histórico Enriquecido

**O que faz**: Expande o modelo de histórico para incluir métricas detalhadas e exercícios completados.

**Por que é importante**: Permite análise de progressão e alimenta o sistema de recomendação.

**Requisitos Funcionais**:
- **F4.1**: Histórico deve armazenar: duração real, calorias (HealthKit), lista de exercícios feitos
- **F4.2**: Histórico deve incluir avaliação do usuário (1-5 estrelas ou fácil/adequado/difícil)
- **F4.3**: Sistema deve calcular e armazenar streak de dias consecutivos
- **F4.4**: Métricas agregadas (semanal/mensal) devem ser pré-calculadas para performance
- **F4.5**: Histórico deve ser consultável por período (última semana, mês, 3 meses)

### F5. Sistema de Feedback e Aprendizado

**O que faz**: Coleta avaliação do treino e usa para ajustar composições futuras.

**Por que é importante**: Personaliza a experiência baseado em preferências reais do usuário.

**Requisitos Funcionais**:
- **F5.1**: Após completar treino, usuário pode avaliar: "Muito Fácil", "Adequado", "Muito Difícil"
- **F5.2**: Avaliações devem ser armazenadas no histórico do treino
- **F5.3**: Prompt OpenAI deve incluir resumo das últimas 5 avaliações
- **F5.4**: Se maioria das avaliações for "Muito Fácil", próximo treino deve aumentar intensidade
- **F5.5**: Se maioria for "Muito Difícil", próximo treino deve reduzir volume/intensidade

## User Experience

### Fluxo Principal (Treino com Feedback)
1. Usuário responde 3 perguntas → Treino gerado
2. Usuário executa treino → Progresso visual
3. Treino concluído → Tela de conclusão com métricas (duração, calorias)
4. Prompt de avaliação → Usuário avalia (1-3 opções)
5. Sincronização automática → Dados salvos + exportados para Health

### Fluxo de Histórico
1. Usuário acessa aba "Histórico"
2. Visualiza streak atual e comparativo semanal
3. Pode filtrar por período (semana/mês/3 meses)
4. Cada treino mostra: data, duração, calorias, avaliação

### Requisitos de UX
- Avaliação de treino deve ser opcional mas incentivada (gamificação)
- Sincronização Health deve ser silenciosa (sem interrupção)
- Streak deve ser visualmente destacado para motivação

## High-Level Technical Constraints

- **Integração obrigatória**: Apple HealthKit (iOS 17+)
- **Persistência**: SwiftData (já existente no projeto)
- **API Externa**: ExerciseDB via RapidAPI (limite 200 req/mês)
- **AI**: OpenAI API (gpt-4o-mini ou superior)
- **Performance**: Geração de treino < 10 segundos
- **Privacidade**: Dados de saúde armazenados apenas localmente (no device)

## Non-Goals (Out of Scope)

- Mudanças nas 3 perguntas do questionário
- Novos tipos de treino (HIIT, Yoga, Pilates)
- Integração com wearables além do Apple Watch/HealthKit
- Rastreamento de peso/reps por exercício
- Importação de treinos de outros apps (apenas HealthKit nativo)
- Planos de treino multi-semana

## Open Questions

1. **Período de avaliações para ajuste**: Considerar últimas 5 ou 10 avaliações para ajustar intensidade?
2. **Fallback sem HealthKit**: Se usuário negar permissão, estimar calorias via MET?
3. **Visualização de progresso**: Gráficos simples (barras) ou mais elaborados (linhas de tendência)?
