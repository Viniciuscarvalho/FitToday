# PRD: Treinos do Personal (Visual Workouts)

## Resumo Executivo

Adicionar uma terceira aba na área de Treino chamada "Personal" que exibe treinos submetidos pelo treinador via CMS. Os treinos são arquivos visuais (geralmente PDF) que o usuário pode visualizar diretamente no app.

## Problema

1. **Limitação atual**: O app possui apenas duas abas de treino - "Meus Treinos" (gerados por IA) e "Programas" (templates pré-definidos)
2. **Alucinações da IA**: A geração de treinos via IA apresenta problemas:
   - Não faz shuffle adequado dos exercícios
   - Carrega sempre do cache em vez de randomizar
   - Não varia os treinos de acordo com o grupo muscular
   - Causa experiência ruim para o usuário
3. **Necessidade do Personal**: Treinadores precisam de uma forma de enviar treinos personalizados diretamente para seus alunos

## Solução Proposta

### Nova Aba "Personal"

Adicionar uma terceira aba no `WorkoutTabView` para exibir treinos enviados pelo Personal Trainer via CMS.

### Funcionalidades

1. **Listagem de Treinos do Personal**
   - Exibir treinos submetidos pelo treinador
   - Ordenar por data (mais recente primeiro)
   - Mostrar nome do treino, data de envio e status (novo/visualizado)

2. **Visualização de PDF**
   - Abrir PDFs diretamente no app usando `PDFKit`
   - Suporte a zoom e navegação entre páginas
   - Cache local para visualização offline

3. **Integração com Firebase**
   - Armazenar metadados no Firestore
   - Armazenar arquivos PDF no Firebase Storage
   - Path: `/personalWorkouts/{trainerId}/{userId}/{filename}`

4. **Notificações**
   - Notificar usuário quando novo treino for enviado
   - Badge de "novo" na aba Personal

## Requisitos Técnicos

### Modelos de Dados

```swift
struct PersonalWorkout: Identifiable, Codable {
    let id: String
    let trainerId: String
    let userId: String
    let title: String
    let description: String?
    let fileURL: String        // URL do Firebase Storage
    let fileType: FileType     // .pdf, .image
    let createdAt: Date
    let viewedAt: Date?

    enum FileType: String, Codable {
        case pdf
        case image
    }
}
```

### Estrutura Firestore

```
/personalWorkouts/{documentId}
  - trainerId: String
  - userId: String
  - title: String
  - description: String?
  - fileURL: String
  - fileType: String
  - createdAt: Timestamp
  - viewedAt: Timestamp?
```

### Regras de Storage

```
/personalWorkouts/{trainerId}/{userId}/{filename}
  - Leitura: usuário autenticado que é o destinatário
  - Escrita: apenas via CMS (admin/trainer)
```

## UI/UX

### Navegação

```
WorkoutTabView
├── Tab 1: Meus Treinos (existente)
├── Tab 2: Programas (existente)
└── Tab 3: Personal (NOVO)
    ├── PersonalWorkoutsListView
    │   └── PersonalWorkoutRow
    └── PDFViewerView
```

### Design

- Seguir o Design System existente (FitTodayColor, FitTodayFont, etc.)
- Cards com thumbnail do PDF (primeira página)
- Badge vermelho para treinos não visualizados
- Empty state quando não há treinos do personal

## Critérios de Aceitação

1. [ ] Nova aba "Personal" visível no WorkoutTabView
2. [ ] Listagem de treinos do personal com loading state
3. [ ] Visualização de PDF funcional com zoom
4. [ ] Cache local dos PDFs para acesso offline
5. [ ] Badge de notificação para treinos novos
6. [ ] Empty state apropriado
7. [ ] Regras de segurança no Firebase Storage
8. [ ] Testes unitários para o ViewModel

## Fora do Escopo (V1)

- CMS para o treinador (será feito separadamente)
- Chat entre personal e aluno
- Comentários/feedback no treino
- Edição de treinos pelo personal no app mobile

## Métricas de Sucesso

- Taxa de visualização de treinos enviados > 80%
- Tempo médio para abrir PDF < 3 segundos
- Zero crashes relacionados à visualização de PDF

## Cronograma Estimado

| Fase | Descrição | Prioridade |
|------|-----------|------------|
| 1 | Modelos e Repository | Alta |
| 2 | UI da lista de treinos | Alta |
| 3 | Visualizador de PDF | Alta |
| 4 | Integração Firebase | Alta |
| 5 | Notificações e badges | Média |
| 6 | Cache offline | Média |
| 7 | Testes | Alta |

## Dependências

- Firebase Storage configurado (já resolvido)
- PDFKit (nativo do iOS)
- Firestore rules atualizadas
