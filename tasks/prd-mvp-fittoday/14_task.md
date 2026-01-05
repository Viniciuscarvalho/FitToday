# [14.0] Performance e acessibilidade: auditoria SwiftUI + otimizações + polish (M)

## Objetivo
- Revisar e melhorar performance e acessibilidade do MVP, garantindo navegação fluida, listas eficientes e UI alinhada a boas práticas (sem invalidações excessivas, imagens otimizadas, labels adequados).

## Subtarefas
- [ ] 14.1 Auditar invalidações: reduzir updates amplos e estabilizar identidades de listas.
- [ ] 14.2 Remover trabalho pesado do `body` (formatters/sort/filter) e mover para ViewModel/cache.
- [ ] 14.3 Otimizar imagens (evitar decodificação na main thread; placeholders).
- [ ] 14.4 Revisar acessibilidade:
  - VoiceOver labels
  - contraste
  - touch targets
  - Dynamic Type (onde fizer sentido)
- [ ] 14.5 Validar navegação: stacks independentes por tab e deep links sem inconsistência.

## Critérios de Sucesso
- Scrolling e navegação sem jank perceptível nas listas principais.
- Elementos interativos acessíveis e com tamanho mínimo.
- Melhorias verificáveis via revisão de código e/ou Instruments (quando aplicável).

## Dependências
- Implementação das principais telas (5.0–12.0).

## Observações
- Se a auditoria só por code review for insuficiente, coletar traces no Instruments (SwiftUI + Time Profiler).

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>performance/swiftui</domain>
<type>performance</type>
<scope>performance</scope>
<complexity>medium</complexity>
<dependencies>external_apis</dependencies>
</task_context>

# Tarefa 14.0: Performance e Acessibilidade

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Garantir que o MVP “pareça premium”: transições suaves, listas eficientes e UI acessível. A meta é evitar gargalos clássicos do SwiftUI (identidade instável, trabalho pesado no body, imagens grandes).

<requirements>
- Identidade estável em listas e `ForEach`.
- Sem trabalho pesado no `body` (formatters/sorting).
- Acessibilidade mínima bem feita (labels/touch targets/contraste).
</requirements>

## Subtarefas

- [ ] 14.1 Revisar e corrigir invalidações e identidade em listas.
- [ ] 14.2 Otimizar computações e imagens.
- [ ] 14.3 Revisar acessibilidade e UX final.

## Detalhes de Implementação

Referenciar:
- “Performance e acessibilidade” e “Concurrency” em `techspec.md`.
- “Experiência do Usuário” em `prd.md`.

## Critérios de Sucesso

- UI responsiva em device.
- Checklist básico de acessibilidade atendido.

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/techspec.md`
- `tasks/prd-mvp-fittoday/prd.md`



