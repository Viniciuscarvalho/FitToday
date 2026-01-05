# [11.0] Trocar sugestão do treino diário 1x + CTA pós-treino “Próximo treino em breve” (M)

## Objetivo
- Permitir que o usuário troque a sugestão do treino diário **ao menos uma vez** caso não goste. Após “ver e terminar” o treino, o CTA principal da Home deve mudar para “Próximo treino em breve”.

## Subtarefas
- [ ] 11.1 Definir estado do treino diário (sugerido/visualizado/iniciado/concluído) e persistir por dia
- [ ] 11.2 Implementar regra de troca 1x (contador/flag diário) e atualizar UI/CTA da Home
- [ ] 11.3 Validar comportamento com Pro/Free (IA only Pro) e com histórico

## Critérios de Sucesso
- Usuário consegue trocar sugestão 1x no dia.
- Após concluir treino, Home mostra “Próximo treino em breve”.
- Estado reseta no próximo dia (conforme regra definida).

## Dependências
- Depende de 7.0 (Home reestruturada) e do fluxo de treino/histórico existente.
- Pode depender de 10.0 (IA only Pro) indiretamente para decidir regeneração.

## Observações
- Definir claramente quando conta como “ver e terminar”: ao abrir a tela do treino + marcar como concluído no histórico.

## markdown

## status: pending # Opções: pending, in-progress, completed, excluded

<task_context>
<domain>engine/state</domain>
<type>implementation</type>
<scope>core_feature</scope>
<complexity>medium</complexity>
<dependencies>database</dependencies>
</task_context>

# Tarefa 11.0: Trocar sugestão 1x + CTA pós-treino

<critical>Ler os arquivos de prd.md e techspec.md desta pasta, se você não ler esses arquivos sua tarefa será invalidada</critical>

## Visão Geral

Melhorar o controle do “treino do dia” para permitir uma troca e alterar o CTA depois que o treino for concluído.

<requirements>
- Permitir troca 1x por dia
- Persistir estado do treino do dia
- Atualizar CTA após conclusão para “Próximo treino em breve”
</requirements>

## Subtarefas

- [ ] 11.1 Criar modelo/estado (ex.: `DailyWorkoutState`) e persistência (SwiftData/AppStorage)
- [ ] 11.2 Implementar UI/ações na Home para “Trocar sugestão” e CTA pós-treino

## Detalhes de Implementação

- Referenciar “Trocar sugestão do treino” em `prd.md` e a seção de estado em `techspec.md`.

## Critérios de Sucesso

- Troca 1x funciona e CTA muda após conclusão

## Arquivos relevantes
- `FitToday/FitToday/Presentation/Features/Home/HomeView.swift`
- `FitToday/FitToday/Presentation/Features/Home/HomeViewModel.swift`
- `FitToday/FitToday/Domain/UseCases/HistoryUseCases.swift`


