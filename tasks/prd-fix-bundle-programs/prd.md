# PRD: Migrar Programas para API Wger

## Problema

Os programas de treino e exercícios não estão sendo carregados corretamente porque:

1. **Exercícios no JSON usam IDs estáticos** (`barbell_bench_press`, `incline_dumbbell_press`) que não correspondem aos IDs da API Wger
2. **Mídias são null** - os exercícios no `LibraryWorkoutsSeed.json` têm `image_url: null` e `gif_url: null`
3. **Arquivos podem não estar no bundle** - ProgramsSeed.json e LibraryWorkoutsSeed.json podem não estar em "Copy Bundle Resources"
4. **Fluxo desconectado** - não há integração entre os programas seed e a API Wger que já funciona

## Solução Proposta

### Estratégia: Programas Híbridos com Exercícios Wger

Manter a estrutura dos 26 programas no JSON mas **substituir os exercícios estáticos por exercícios reais da API Wger** em tempo de execução.

### Fluxo Desejado

```
1. App carrega → Lista 26 programas (do JSON)
2. Usuário entra em programa → Carrega exercícios da Wger API por categoria/músculo
3. Usuário pode reordenar exercícios dentro do programa
4. Usuário pode adicionar/remover exercícios do programa
5. Exercícios mostram imagens/GIFs da API Wger
```

## Requisitos Funcionais

### RF1: Carregar Programas com Exercícios Wger
- [ ] Programas continuam vindo do `ProgramsSeed.json` (metadados)
- [ ] Exercícios são buscados da API Wger por categoria correspondente
- [ ] Mapeamento entre `workout_template_ids` e categorias Wger

### RF2: Mapeamento de Categorias
| Template ID | Categorias Wger |
|-------------|-----------------|
| `lib_push_*` | Chest (11), Shoulders (13), Triceps (5) |
| `lib_pull_*` | Back (12), Biceps (1) |
| `lib_legs_*` | Legs (9), Glutes (8), Calves (14) |
| `lib_fullbody_*` | Todas as categorias |
| `lib_core_*` | Abs (10) |
| `lib_hiit_*` | Cardio + exercícios compostos |
| `lib_upper_*` | Upper body muscles |
| `lib_lower_*` | Lower body muscles |

### RF3: Personalização do Programa
- [ ] Reordenar exercícios via drag & drop
- [ ] Adicionar exercícios da biblioteca Wger
- [ ] Remover exercícios do programa
- [ ] Salvar customizações localmente

### RF4: Exibição de Mídia
- [ ] Imagens dos exercícios da API Wger
- [ ] Fallback para ícone genérico se sem mídia
- [ ] Cache de imagens para offline

## Requisitos Não-Funcionais

### RNF1: Performance
- Carregar programa em < 2 segundos
- Cache de exercícios Wger por 24h
- Lazy loading de imagens

### RNF2: Offline
- Programas básicos disponíveis offline (do JSON)
- Exercícios cacheados ficam disponíveis
- Sincronizar quando online

## Arquitetura

### Componentes Afetados

```
Domain/
├── Entities/
│   ├── ProgramModels.swift          # Adicionar relação com WgerExercise
│   └── WgerModels.swift             # Já existe

Data/
├── Repositories/
│   ├── BundleProgramRepository.swift    # Manter para metadados
│   └── WgerProgramWorkoutRepository.swift  # NOVO: busca exercícios Wger
├── Services/
│   └── Wger/
│       └── WgerAPIService.swift     # Já existe, usar para exercícios

Presentation/
├── Features/
│   └── Programs/
│       ├── ProgramsListView.swift       # Já existe
│       ├── ProgramDetailView.swift      # Modificar para usar Wger
│       └── ProgramWorkoutDetailView.swift # NOVO: detalhe do treino
```

### Novo Repository: WgerProgramWorkoutRepository

```swift
protocol WgerProgramWorkoutRepository {
    /// Busca exercícios Wger para um template de workout
    func loadWorkoutExercises(templateId: String) async throws -> [WgerExercise]

    /// Busca exercícios por categoria Wger
    func loadExercisesByCategory(_ categoryId: Int) async throws -> [WgerExercise]

    /// Salva customização do usuário (ordem, adições, remoções)
    func saveUserCustomization(programId: String, workoutId: String, exercises: [WgerExercise]) async throws

    /// Carrega customização do usuário se existir
    func loadUserCustomization(programId: String, workoutId: String) async throws -> [WgerExercise]?
}
```

## Mapeamento Template → Categoria Wger

```swift
enum WorkoutTemplateType: String {
    case push, pull, legs, fullbody, core, hiit, upper, lower

    var wgerCategories: [Int] {
        switch self {
        case .push: return [11, 13, 5]     // Chest, Shoulders, Triceps
        case .pull: return [12, 1]         // Back, Biceps
        case .legs: return [9, 8, 14]      // Legs, Glutes, Calves
        case .fullbody: return [11, 12, 9, 10, 13] // All major
        case .core: return [10]            // Abs
        case .hiit: return [11, 9, 10]     // Compound movements
        case .upper: return [11, 12, 13, 1, 5] // All upper
        case .lower: return [9, 8, 14]     // All lower
        }
    }
}
```

## Fases de Implementação

### Fase 1: Core Infrastructure (P0)
1. Criar `WgerProgramWorkoutRepository`
2. Implementar mapeamento template → categorias Wger
3. Modificar `ProgramDetailView` para usar exercícios Wger

### Fase 2: UI & UX (P1)
1. Exibir exercícios com imagens da Wger
2. Implementar reordenação de exercícios
3. Adicionar/remover exercícios

### Fase 3: Persistência (P2)
1. Salvar customizações do usuário
2. Cache offline de exercícios
3. Sincronização

## Critérios de Aceite

### CA1: Programas Carregam
- [x] Lista 26 programas na tela inicial
- [ ] Cada programa mostra número correto de treinos
- [ ] Ao abrir programa, exercícios são carregados da Wger

### CA2: Exercícios com Mídia
- [ ] Exercícios mostram imagens da API Wger
- [ ] Fallback visual quando sem imagem
- [ ] Loading state durante busca

### CA3: Personalização
- [ ] Usuário pode reordenar exercícios
- [ ] Usuário pode adicionar exercícios
- [ ] Usuário pode remover exercícios
- [ ] Mudanças persistem entre sessões

## Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| API Wger offline | Alto | Cache agressivo + fallback local |
| Muitas requisições | Médio | Batch requests + rate limiting |
| Exercícios sem tradução PT | Médio | Usar EN como fallback |

## Métricas de Sucesso

- 100% dos programas carregam exercícios
- < 2s para carregar programa
- 0 erros de "exercício não encontrado"
- Imagens em > 80% dos exercícios
