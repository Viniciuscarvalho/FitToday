# [9.0] Treino gerado: lista + detalhe do exercício + execução + conclusão (L)

## Objetivo
- Implementar a experiência do treino: exibir plano gerado, permitir navegar por exercícios (detalhe), executar com “Próximo/Pular” e concluir registrando o resultado.

## Subtarefas
- [ ] 9.1 Implementar tela “Treino gerado” (header + lista de exercícios).
- [ ] 9.2 Implementar detalhe do exercício (imagem, descrição curta, dica, botões).
- [ ] 9.3 Implementar estado de sessão (`WorkoutSession`) e avanço/pulo entre exercícios.
- [ ] 9.4 Implementar tela final (“Treino concluído”) e persistência no histórico.
- [ ] 9.5 Garantir navegação via Router e funcionamento dentro do stack do tab atual.
- [ ] 9.6 Utilizar a ExerciseDB (https://github.com/ExerciseDB/exercisedb-api) para utilizar as imagens e GIFs na aplicação.

## Critérios de Sucesso
- Usuário percorre o treino sem travar, e ao final o histórico reflete “concluído” ou “pulado”.
- UI é leve: listas com identidade estável e sem trabalho pesado em `body`.

## Dependências
- 1.0 Fundação.
- 2.0 Design System.
- 3.0 Domain.
- 8.0 Motor de treino.
- 10.0 Histórico (persistência e listagem). Pode iniciar salvando e listar depois.

## Observações
- Timer avançado fica fora do MVP; foco em fluxo simples e claro.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>presentation/workout</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>high</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 9.0: UI do treino + execução

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Transformar o plano gerado em uma experiência de treino utilizável. O usuário precisa ver o que fazer e avançar facilmente pelos exercícios, com conclusão clara.

<requirements>
- Tela “Treino gerado” com lista de exercícios e metadata.
- Detalhe do exercício (imagem/descrição/dica) + navegação “Próximo/Pular”.
- Registro de conclusão/pulo no histórico.
</requirements>

## Subtarefas

- [ ] 9.1 Implementar Views/ViewModels do treino e detalhe do exercício.
- [ ] 9.2 Implementar estado de sessão e integração com histórico.
- [ ] 9.3 Garantir navegação via Router e compatibilidade com stacks por tab.

## Detalhes de Implementação

Referenciar:
- “Treino Gerado”, “Execução do Exercício” e “Final do Treino” em `prd.md`.
- “Performance SwiftUI” em `techspec.md` (evitar invalidações e trabalho pesado).

## Critérios de Sucesso

- Concluir treino grava entrada de histórico.
- UI sem jank perceptível em listas de exercícios (MVP).

## Arquivos relevantes
- `tasks/prd-mvp-fittoday/prd.md`
- `tasks/prd-mvp-fittoday/techspec.md`





