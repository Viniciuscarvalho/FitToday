# [5.0] Criar 3–5 programas iniciais (metabolic/strength) + assets/seed (S/M)

## Objetivo
- Criar os programas iniciais (3–5) com dados completos (nome, duração, tag, imagem) e mapear para treinos existentes, deixando a experiência atrativa e pronta para recomendação.

## Subtarefas
- [ ] 5.1 Definir lista de programas iniciais (metabolic/strength) e seus treinos/templates
- [ ] 5.2 Adicionar assets de imagem de fundo (ou placeholders) e atualizar seed no bundle
- [ ] 5.3 Validar que cada programa aparece corretamente na UI (cards) e abre detalhe

## Critérios de Sucesso
- 3–5 programas aparecem em “Programas” com imagem de fundo e metadados.
- Cada programa tem duração e CTA coerentes.

## Dependências
- Depende de 4.0 (entidade + repositório).

## Observações
- Se não houver imagens finais, usar placeholders consistentes do Design System.

## markdown

## status: completed # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>data/content</domain>
<type>implementation</type>
<scope>configuration</scope>
<complexity>medium</complexity>
<dependencies></dependencies>
</task_context>

# Tarefa 5.0: Criar 3–5 programas iniciais

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Precisamos de um conjunto inicial de Programas para alimentar a nova Home e a nova tab “Programas”.

<requirements>
- Criar 3–5 programas seed
- Garantir imagens de fundo (asset) e metadados
- Mapear para treinos existentes válidos
</requirements>

## Subtarefas

- [ ] 5.1 Elaborar programas “metabolic” e “strength” (pelo menos 1 de cada)
- [ ] 5.2 Adicionar assets e atualizar referências no seed

## Detalhes de Implementação

- Referenciar o modelo `Program` e seed no `techspec.md`.

## Critérios de Sucesso

- “Programas” mostra 3–5 itens visualmente atrativos

## Arquivos relevantes
- `FitToday/FitToday/Data/Resources/`
- `FitToday/FitToday/Assets.xcassets/`


