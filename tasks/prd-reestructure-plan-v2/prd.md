# 🏋️ Plano de Reestruturação - Fitness App

> **Versão:** 1.0  
> **Data:** Janeiro 2026  
> **Autor:** Vinicius  
> **Objetivo:** Reestruturação completa do app com migração de API, novo sistema de workouts e integração de dados

---

## 📋 Índice

1. [Visão Geral do Projeto](#1-visão-geral-do-projeto)
2. [Fase 1: Migração de API (ExerciseDB → Wger)](#2-fase-1-migração-de-api)
3. [Fase 2: Novo Sistema de Workouts](#3-fase-2-novo-sistema-de-workouts)
4. [Fase 3: Programas Pré-Montados](#4-fase-3-programas-pré-montados)
5. [Fase 4: Integração Histórico + Desafios](#5-fase-4-integração-histórico--desafios)
6. [Fase 5: Tela Inicial com IA](#6-fase-5-tela-inicial-com-ia)
7. [Arquitetura de Dados](#7-arquitetura-de-dados)
8. [Cronograma de Execução](#8-cronograma-de-execução)
9. [Checklist de Implementação](#9-checklist-de-implementação)

---

## 1. Visão Geral do Projeto

### 1.1 Mudanças Principais

| Área | Estado Atual | Estado Futuro |
|------|--------------|---------------|
| API de Exercícios | ExerciseDB (paga/limitada) | Wger API (gratuita) |
| TabBar | Programas | Workout |
| Criação de Treinos | Apenas IA | IA + Manual + Programas |
| Histórico | Separado | Integrado com Desafios |
| Dados | Firebase isolado | Firebase + Apple Health sync |
| Tela Inicial | Fluxo complexo | Fluxo simplificado com IA |

### 1.2 Nova Estrutura da TabBar

```
┌─────────────────────────────────────────────────────────┐
│                      TAB BAR                            │
├──────────┬──────────┬──────────┬──────────┬────────────┤
│   Home   │ Workout  │    +     │ Activity │  Profile   │
│  (IA)    │(Templates│ (Quick)  │(Histórico│            │
│          │+Programas│          │+Desafios)│            │
└──────────┴──────────┴──────────┴──────────┴────────────┘
```

### 1.3 Dependências do Projeto

```
- Swift 6.0+
- iOS 17.0+
- SwiftUI
- Firebase (Firestore, Auth)
- HealthKit
- OpenAI API
- Wger API (nova)
```

---

## 2. Fase 1: Migração de API

### 2.1 Comparativo ExerciseDB vs Wger

| Característica | ExerciseDB | Wger API |
|----------------|------------|----------|
| Custo | Freemium (limite requests) | 100% Gratuita |
| Exercícios | ~1300 | ~800+ |
| Imagens | GIFs animados | Imagens estáticas |
| Idiomas | Inglês | Multi-idioma (PT-BR) |
| Documentação | RapidAPI | Aberta |
| Rate Limit | Sim | Não |

### 2.2 Mapeamento de Endpoints

#### Endpoints Wger API Necessários

```
Base URL: https://wger.de/api/v2/

GET /exercise/          - Lista de exercícios
GET /exercise/{id}/     - Detalhes do exercício
GET /exerciseimage/     - Imagens dos exercícios
GET /exercisecategory/  - Categorias (muscle groups)
GET /muscle/            - Lista de músculos
GET /equipment/         - Lista de equipamentos
GET /language/          - Idiomas disponíveis
```

#### Parâmetros Importantes

```
?language=4             - Português (PT)
?language=2             - Inglês (EN)
?limit=100              - Paginação
?offset=0               - Offset da paginação
?category={id}          - Filtro por categoria
?equipment={id}         - Filtro por equipamento
```

### 2.3 Mapeamento de Categorias Wger

| ID | Categoria | Tradução |
|----|-----------|----------|
| 8  | Arms | Braços |
| 9  | Legs | Pernas |
| 10 | Abs | Abdômen |
| 11 | Chest | Peito |
| 12 | Back | Costas |
| 13 | Shoulders | Ombros |
| 14 | Calves | Panturrilhas |
| 15 | Cardio | Cardio |

### 2.4 Mapeamento de Equipamentos Wger

| ID | Equipamento | Tradução |
|----|-------------|----------|
| 1  | Barbell | Barra |
| 2  | SZ-Bar | Barra W |
| 3  | Dumbbell | Halteres |
| 4  | Gym mat | Colchonete |
| 5  | Swiss Ball | Bola Suíça |
| 6  | Pull-up bar | Barra fixa |
| 7  | None (bodyweight) | Peso corporal |
| 8  | Bench | Banco |
| 9  | Incline bench | Banco inclinado |
| 10 | Kettlebell | Kettlebell |

### 2.5 Estrutura do Novo Service

```swift
// MARK: - Arquivo: Services/WgerAPIService.swift

protocol ExerciseServiceProtocol {
    func fetchExercises(language: String, category: Int?, equipment: Int?) async throws -> [Exercise]
    func fetchExerciseDetail(id: Int) async throws -> ExerciseDetail
    func fetchExerciseImages(exerciseId: Int) async throws -> [ExerciseImage]
    func searchExercises(query: String, language: String) async throws -> [Exercise]
}

final class WgerAPIService: ExerciseServiceProtocol {
    private let baseURL = "https://wger.de/api/v2"
    private let cache: ExerciseCacheProtocol
    private let decoder: JSONDecoder
    
    // Implementação dos métodos...
}
```

### 2.6 Modelo de Dados Wger

```swift
// MARK: - Arquivo: Models/WgerModels.swift

struct WgerExercise: Codable, Identifiable {
    let id: Int
    let uuid: String
    let name: String
    let description: String
    let category: Int
    let muscles: [Int]
    let musclesSecondary: [Int]
    let equipment: [Int]
    
    enum CodingKeys: String, CodingKey {
        case id, uuid, name, description, category, muscles, equipment
        case musclesSecondary = "muscles_secondary"
    }
}

struct WgerExerciseImage: Codable, Identifiable {
    let id: Int
    let exercise: Int
    let image: String
    let isMain: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, exercise, image
        case isMain = "is_main"
    }
}

struct WgerPaginatedResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}
```

### 2.7 Sistema de Cache Local

```swift
// MARK: - Arquivo: Services/ExerciseCacheManager.swift

final class ExerciseCacheManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 dias
    
    struct CachedData<T: Codable>: Codable {
        let data: T
        let cachedAt: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(cachedAt) > maxCacheAge
        }
    }
    
    func cacheExercises(_ exercises: [WgerExercise]) async throws
    func getCachedExercises() async throws -> [WgerExercise]?
    func cacheImage(_ imageData: Data, for exerciseId: Int) async throws
    func getCachedImage(for exerciseId: Int) async throws -> Data?
    func clearExpiredCache() async throws
}
```

### 2.8 Tarefas de Migração

```
□ 2.8.1  Criar WgerAPIService.swift
□ 2.8.2  Criar WgerModels.swift
□ 2.8.3  Criar ExerciseCacheManager.swift
□ 2.8.4  Criar mapeamento de categorias/equipamentos
□ 2.8.5  Implementar busca com paginação
□ 2.8.6  Implementar cache de imagens em disco
□ 2.8.7  Criar fallback visual (SF Symbols) para exercícios sem imagem
□ 2.8.8  Remover dependências ExerciseDB
□ 2.8.9  Atualizar todos os ViewModels que usavam ExerciseDB
□ 2.8.10 Testar todos os fluxos de exercícios
```

---

## 3. Fase 2: Novo Sistema de Workouts

### 3.1 Arquitetura da Tela Workout

```
┌─────────────────────────────────────────────────────────┐
│                    WORKOUT TAB                          │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │           SEGMENTED CONTROL                      │   │
│  │   [ Meus Treinos ]  [ Programas ]               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ════════════════════════════════════════════════════  │
│                                                         │
│  SE "Meus Treinos":                                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │  + Criar Novo Treino                            │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📋 Treino A - Peito e Tríceps                  │   │
│  │  Último: 2 dias atrás  •  8 exercícios          │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📋 Treino B - Costas e Bíceps                  │   │
│  │  Último: 3 dias atrás  •  7 exercícios          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ════════════════════════════════════════════════════  │
│                                                         │
│  SE "Programas":                                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │  FILTROS                                         │   │
│  │  [Nível ▼] [Objetivo ▼] [Equipamento ▼]        │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🏋️ Push Pull Legs                              │   │
│  │  Intermediário • Hipertrofia • Academia         │   │
│  │  6 dias/semana • 18 exercícios                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Modelos de Dados - Workout

```swift
// MARK: - Arquivo: Models/WorkoutModels.swift

// Template de treino criado pelo usuário
struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [WorkoutExercise]
    var notes: String?
    var colorTheme: String // Cor do card
    var iconName: String   // SF Symbol
    var createdAt: Date
    var updatedAt: Date
    var lastPerformedAt: Date?
    var timesCompleted: Int
    var estimatedDuration: Int // minutos
    var isFromProgram: Bool
    var programId: String?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.exercises = []
        self.colorTheme = "blue"
        self.iconName = "dumbbell.fill"
        self.createdAt = Date()
        self.updatedAt = Date()
        self.timesCompleted = 0
        self.estimatedDuration = 0
        self.isFromProgram = false
    }
}

// Exercício dentro de um template
struct WorkoutExercise: Identifiable, Codable {
    let id: UUID
    let exerciseId: Int        // ID do Wger
    var exerciseName: String
    var exerciseImageURL: String?
    var targetMuscle: String
    var equipment: String
    var sets: [ExerciseSet]
    var notes: String?
    var restSeconds: Int
    var order: Int
    
    init(from wgerExercise: WgerExercise, order: Int) {
        self.id = UUID()
        self.exerciseId = wgerExercise.id
        self.exerciseName = wgerExercise.name
        self.targetMuscle = "" // Mapear da categoria
        self.equipment = ""    // Mapear do equipamento
        self.sets = [ExerciseSet(), ExerciseSet(), ExerciseSet()] // 3 séries padrão
        self.restSeconds = 90
        self.order = order
    }
}

// Série de um exercício
struct ExerciseSet: Identifiable, Codable {
    let id: UUID
    var type: SetType
    var targetReps: Int
    var targetWeight: Double?
    var targetRPE: Int?         // 1-10
    var isCompleted: Bool
    var actualReps: Int?
    var actualWeight: Double?
    
    init(type: SetType = .working, targetReps: Int = 12) {
        self.id = UUID()
        self.type = type
        self.targetReps = targetReps
        self.isCompleted = false
    }
}

enum SetType: String, Codable, CaseIterable {
    case warmup = "Aquecimento"
    case working = "Normal"
    case dropset = "Drop Set"
    case failure = "Falha"
    case superSet = "Super Set"
}
```

### 3.3 Fluxo de Criação de Treino

```
┌──────────────────┐
│  Tela Workout    │
│  [+ Criar Novo]  │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│         CRIAR NOVO TREINO                │
├──────────────────────────────────────────┤
│  Nome do Treino: [___________________]   │
│                                          │
│  Ícone: 🏋️ 💪 🔥 ⚡ 🎯 (selecionável)     │
│  Cor:   🔴 🟠 🟡 🟢 🔵 🟣 (selecionável)   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  + ADICIONAR EXERCÍCIO             │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Exercícios adicionados:                 │
│  (lista vazia ou com exercícios)         │
│                                          │
│  [CANCELAR]              [SALVAR TREINO] │
└──────────────────────────────────────────┘
         │
         │ Clique em "+ Adicionar"
         ▼
┌──────────────────────────────────────────┐
│      BUSCAR EXERCÍCIO                    │
├──────────────────────────────────────────┤
│  🔍 [Buscar exercício...              ]  │
│                                          │
│  Filtros:                                │
│  [Músculo ▼] [Equipamento ▼]            │
│                                          │
│  Resultados:                             │
│  ┌────────────────────────────────────┐  │
│  │ 🖼️ Supino Reto                     │  │
│  │    Peito • Barra                   │  │
│  │                            [+ADD]  │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │ 🖼️ Supino Inclinado                │  │
│  │    Peito • Barra                   │  │
│  │                            [+ADD]  │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
         │
         │ Após adicionar exercícios
         ▼
┌──────────────────────────────────────────┐
│      CONFIGURAR EXERCÍCIO                │
├──────────────────────────────────────────┤
│  Supino Reto                             │
│                                          │
│  Séries:                                 │
│  ┌──────┬──────┬──────┬───────────────┐  │
│  │ Tipo │ Reps │ Peso │    Ação       │  │
│  ├──────┼──────┼──────┼───────────────┤  │
│  │ 🔥   │  12  │  60  │     🗑️        │  │
│  │ 💪   │  10  │  70  │     🗑️        │  │
│  │ 💪   │  8   │  80  │     🗑️        │  │
│  └──────┴──────┴──────┴───────────────┘  │
│                                          │
│  [+ Adicionar Série]                     │
│                                          │
│  Descanso entre séries: [90s ▼]         │
│                                          │
│  Notas: [________________________]       │
│                                          │
│  [CONFIRMAR]                             │
└──────────────────────────────────────────┘
```

### 3.4 Tela de Execução de Treino

```
┌──────────────────────────────────────────┐
│  ←  Treino A - Peito e Tríceps     ✕    │
├──────────────────────────────────────────┤
│                                          │
│         ⏱️ 00:45:32                      │
│         Tempo de treino                  │
│                                          │
│  Progresso: ████████░░░░░░░ 4/8          │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│  EXERCÍCIO ATUAL (4 de 8)               │
│  ┌────────────────────────────────────┐  │
│  │        [IMAGEM DO EXERCÍCIO]       │  │
│  │                                    │  │
│  │  Supino Inclinado com Halteres     │  │
│  │  Peito Superior • Halteres         │  │
│  └────────────────────────────────────┘  │
│                                          │
│  SÉRIES                                  │
│  ┌──────┬──────┬──────┬───────────────┐  │
│  │ Set  │ Reps │ Peso │    Status     │  │
│  ├──────┼──────┼──────┼───────────────┤  │
│  │  1   │  12  │ 20kg │      ✅       │  │
│  │  2   │  10  │ 22kg │      ✅       │  │
│  │  3   │  10  │ 22kg │  ▶️ ATUAL     │  │
│  │  4   │  8   │ 24kg │      ⬜       │  │
│  └──────┴──────┴──────┴───────────────┘  │
│                                          │
│  Registrar série atual:                  │
│  Reps: [  10  ]    Peso: [ 22 ] kg      │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │         ✅ COMPLETAR SÉRIE          │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [← ANTERIOR]              [PRÓXIMO →]   │
│                                          │
└──────────────────────────────────────────┘
         │
         │ Após completar série
         ▼
┌──────────────────────────────────────────┐
│           ⏱️ DESCANSO                    │
├──────────────────────────────────────────┤
│                                          │
│              01:30                       │
│         ━━━━━━━━━━━━━━━━                 │
│                                          │
│    [PULAR]        [+30s]                 │
│                                          │
│  Próxima série:                          │
│  Série 4 • 8 reps • 24kg                 │
│                                          │
└──────────────────────────────────────────┘
```

### 3.5 Tarefas de Implementação - Workouts

```
□ 3.5.1  Criar WorkoutModels.swift
□ 3.5.2  Criar WorkoutTemplateRepository.swift (persistência)
□ 3.5.3  Criar WorkoutTabView.swift (tela principal)
□ 3.5.4  Criar MyWorkoutsView.swift (lista de templates)
□ 3.5.5  Criar CreateWorkoutView.swift (criação)
□ 3.5.6  Criar ExerciseSearchView.swift (busca de exercícios)
□ 3.5.7  Criar ExerciseConfigSheet.swift (configurar séries)
□ 3.5.8  Criar WorkoutExecutionView.swift (execução)
□ 3.5.9  Criar RestTimerView.swift (timer de descanso)
□ 3.5.10 Criar WorkoutSummaryView.swift (resumo pós-treino)
□ 3.5.11 Implementar drag & drop para reordenar exercícios
□ 3.5.12 Implementar swipe actions (editar, deletar)
□ 3.5.13 Implementar haptic feedback nas interações
□ 3.5.14 Testar fluxo completo de criação e execução
```

---

## 4. Fase 3: Programas Pré-Montados

### 4.1 Estrutura de Programas

```swift
// MARK: - Arquivo: Models/ProgramModels.swift

struct WorkoutProgram: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let level: FitnessLevel
    let goal: FitnessGoal
    let equipment: EquipmentType
    let daysPerWeek: Int
    let weeksTotal: Int
    let workoutTemplates: [ProgramWorkout]
    let imageURL: String?
    let isPremium: Bool
    
    // Computed property para matching de filtros
    func matches(level: FitnessLevel?, goal: FitnessGoal?, equipment: EquipmentType?) -> Bool {
        let levelMatch = level == nil || self.level == level
        let goalMatch = goal == nil || self.goal == goal
        let equipmentMatch = equipment == nil || self.equipment == equipment
        return levelMatch && goalMatch && equipmentMatch
    }
}

struct ProgramWorkout: Identifiable, Codable {
    let id: String
    let dayNumber: Int        // Dia 1, 2, 3...
    let name: String          // "Push Day", "Leg Day"
    let exercises: [ProgramExercise]
    let targetMuscles: [String]
    let estimatedMinutes: Int
}

struct ProgramExercise: Identifiable, Codable {
    let id: String
    let wgerExerciseId: Int
    let exerciseName: String
    let sets: Int
    let repsRange: String      // "8-12", "12-15"
    let restSeconds: Int
    let notes: String?
    let alternatives: [Int]?   // IDs de exercícios alternativos
}

enum FitnessLevel: String, Codable, CaseIterable {
    case beginner = "Iniciante"
    case intermediate = "Intermediário"
    case advanced = "Avançado"
}

enum FitnessGoal: String, Codable, CaseIterable {
    case muscleGain = "Ganho de Massa"
    case strength = "Força"
    case weightLoss = "Perda de Peso"
    case endurance = "Resistência"
}

enum EquipmentType: String, Codable, CaseIterable {
    case fullGym = "Academia Completa"
    case dumbbellOnly = "Apenas Halteres"
    case bodyweight = "Peso Corporal"
    case homeGym = "Academia em Casa"
}
```

### 4.2 Catálogo de 26 Programas

```swift
// MARK: - Arquivo: Data/ProgramsCatalog.swift

struct ProgramsCatalog {
    
    static let allPrograms: [WorkoutProgram] = [
        
        // ═══════════════════════════════════════════════════════════
        // PUSH PULL LEGS (6 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 1. PPL - Iniciante - Hipertrofia - Academia
        WorkoutProgram(
            id: "ppl_beginner_muscle_gym",
            name: "Push Pull Legs",
            description: "Programa clássico de 6 dias para iniciantes focado em hipertrofia",
            level: .beginner,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 6,
            weeksTotal: 8,
            workoutTemplates: PPLTemplates.beginnerMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 2. PPL - Intermediário - Hipertrofia - Academia
        WorkoutProgram(
            id: "ppl_intermediate_muscle_gym",
            name: "Push Pull Legs Pro",
            description: "Versão avançada do PPL com técnicas intensificadoras",
            level: .intermediate,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 6,
            weeksTotal: 10,
            workoutTemplates: PPLTemplates.intermediateMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 3. PPL - Avançado - Força - Academia
        WorkoutProgram(
            id: "ppl_advanced_strength_gym",
            name: "Push Pull Legs - Força",
            description: "PPL focado em força com progressão de cargas",
            level: .advanced,
            goal: .strength,
            equipment: .fullGym,
            daysPerWeek: 6,
            weeksTotal: 12,
            workoutTemplates: PPLTemplates.advancedStrengthGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // FULL BODY (6 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 4. Full Body - Iniciante - Hipertrofia - Academia
        WorkoutProgram(
            id: "fullbody_beginner_muscle_gym",
            name: "Full Body Iniciante",
            description: "Treino de corpo inteiro 3x por semana para iniciantes",
            level: .beginner,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 3,
            weeksTotal: 8,
            workoutTemplates: FullBodyTemplates.beginnerMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 5. Full Body - Iniciante - Hipertrofia - Halteres
        WorkoutProgram(
            id: "fullbody_beginner_muscle_dumbbell",
            name: "Full Body com Halteres",
            description: "Treino completo usando apenas halteres",
            level: .beginner,
            goal: .muscleGain,
            equipment: .dumbbellOnly,
            daysPerWeek: 3,
            weeksTotal: 8,
            workoutTemplates: FullBodyTemplates.beginnerMuscleDumbbell,
            imageURL: nil,
            isPremium: false
        ),
        
        // 6. Full Body - Intermediário - Perda de Peso - Academia
        WorkoutProgram(
            id: "fullbody_intermediate_weightloss_gym",
            name: "Full Body Fat Burn",
            description: "Circuito de corpo inteiro para queima de gordura",
            level: .intermediate,
            goal: .weightLoss,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 8,
            workoutTemplates: FullBodyTemplates.intermediateWeightLossGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 7. Full Body - Iniciante - Peso Corporal
        WorkoutProgram(
            id: "fullbody_beginner_muscle_bodyweight",
            name: "Full Body Calistenia",
            description: "Treino sem equipamentos para fazer em qualquer lugar",
            level: .beginner,
            goal: .muscleGain,
            equipment: .bodyweight,
            daysPerWeek: 3,
            weeksTotal: 6,
            workoutTemplates: FullBodyTemplates.beginnerBodyweight,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // UPPER LOWER (6 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 8. Upper Lower - Iniciante - Hipertrofia - Academia
        WorkoutProgram(
            id: "upperlower_beginner_muscle_gym",
            name: "Upper Lower Básico",
            description: "Divisão superior/inferior 4 dias por semana",
            level: .beginner,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 8,
            workoutTemplates: UpperLowerTemplates.beginnerMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 9. Upper Lower - Intermediário - Força - Academia
        WorkoutProgram(
            id: "upperlower_intermediate_strength_gym",
            name: "Upper Lower Força",
            description: "Foco em movimentos compostos para força",
            level: .intermediate,
            goal: .strength,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 10,
            workoutTemplates: UpperLowerTemplates.intermediateStrengthGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 10. Upper Lower - Avançado - Hipertrofia - Academia
        WorkoutProgram(
            id: "upperlower_advanced_muscle_gym",
            name: "Upper Lower Hipertrofia",
            description: "Alto volume para ganho muscular máximo",
            level: .advanced,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 5,
            weeksTotal: 12,
            workoutTemplates: UpperLowerTemplates.advancedMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 11. Upper Lower - Intermediário - Halteres
        WorkoutProgram(
            id: "upperlower_intermediate_muscle_dumbbell",
            name: "Upper Lower Halteres",
            description: "Divisão superior/inferior apenas com halteres",
            level: .intermediate,
            goal: .muscleGain,
            equipment: .dumbbellOnly,
            daysPerWeek: 4,
            weeksTotal: 8,
            workoutTemplates: UpperLowerTemplates.intermediateMuscleDumbbell,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // BRO SPLIT (4 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 12. Bro Split - Intermediário - Hipertrofia - Academia
        WorkoutProgram(
            id: "brosplit_intermediate_muscle_gym",
            name: "Bro Split Clássico",
            description: "Um grupo muscular por dia, 5x por semana",
            level: .intermediate,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 5,
            weeksTotal: 8,
            workoutTemplates: BroSplitTemplates.intermediateMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 13. Bro Split - Avançado - Hipertrofia - Academia
        WorkoutProgram(
            id: "brosplit_advanced_muscle_gym",
            name: "Bro Split Volume",
            description: "Alto volume por grupo muscular",
            level: .advanced,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 5,
            weeksTotal: 10,
            workoutTemplates: BroSplitTemplates.advancedMuscleGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // STRENGTH FOCUSED (4 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 14. Starting Strength Style - Iniciante - Força
        WorkoutProgram(
            id: "strength_beginner_gym",
            name: "Fundamentos de Força",
            description: "Baseado em Starting Strength para iniciantes",
            level: .beginner,
            goal: .strength,
            equipment: .fullGym,
            daysPerWeek: 3,
            weeksTotal: 12,
            workoutTemplates: StrengthTemplates.beginnerGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 15. 5x5 - Intermediário - Força
        WorkoutProgram(
            id: "strength_intermediate_5x5_gym",
            name: "5x5 Força",
            description: "Programa clássico 5x5 para força intermediária",
            level: .intermediate,
            goal: .strength,
            equipment: .fullGym,
            daysPerWeek: 3,
            weeksTotal: 12,
            workoutTemplates: StrengthTemplates.intermediate5x5Gym,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // WEIGHT LOSS FOCUSED (4 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 16. Fat Burn - Iniciante - Academia
        WorkoutProgram(
            id: "weightloss_beginner_gym",
            name: "Queima Total Iniciante",
            description: "Circuitos para queima de gordura",
            level: .beginner,
            goal: .weightLoss,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 8,
            workoutTemplates: WeightLossTemplates.beginnerGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // 17. Fat Burn - Intermediário - Peso Corporal
        WorkoutProgram(
            id: "weightloss_intermediate_bodyweight",
            name: "HIIT Peso Corporal",
            description: "Treinos intensos sem equipamentos",
            level: .intermediate,
            goal: .weightLoss,
            equipment: .bodyweight,
            daysPerWeek: 5,
            weeksTotal: 6,
            workoutTemplates: WeightLossTemplates.intermediateBodyweight,
            imageURL: nil,
            isPremium: false
        ),
        
        // 18. Fat Burn - Avançado - Academia
        WorkoutProgram(
            id: "weightloss_advanced_gym",
            name: "Metabolic Conditioning",
            description: "Treino metabólico avançado",
            level: .advanced,
            goal: .weightLoss,
            equipment: .fullGym,
            daysPerWeek: 5,
            weeksTotal: 8,
            workoutTemplates: WeightLossTemplates.advancedGym,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // HOME/MINIMAL EQUIPMENT (4 variações)
        // ═══════════════════════════════════════════════════════════
        
        // 19. Home Gym - Iniciante - Hipertrofia
        WorkoutProgram(
            id: "home_beginner_muscle",
            name: "Home Gym Básico",
            description: "Treino em casa com equipamentos mínimos",
            level: .beginner,
            goal: .muscleGain,
            equipment: .homeGym,
            daysPerWeek: 3,
            weeksTotal: 8,
            workoutTemplates: HomeGymTemplates.beginnerMuscle,
            imageURL: nil,
            isPremium: false
        ),
        
        // 20. Home Gym - Intermediário - Hipertrofia
        WorkoutProgram(
            id: "home_intermediate_muscle",
            name: "Home Gym Avançado",
            description: "Maximizando resultados com equipamentos limitados",
            level: .intermediate,
            goal: .muscleGain,
            equipment: .homeGym,
            daysPerWeek: 4,
            weeksTotal: 10,
            workoutTemplates: HomeGymTemplates.intermediateMuscle,
            imageURL: nil,
            isPremium: false
        ),
        
        // ═══════════════════════════════════════════════════════════
        // SPECIALIZED (6 variações extras)
        // ═══════════════════════════════════════════════════════════
        
        // 21. Arnold Split
        WorkoutProgram(
            id: "arnold_advanced_muscle_gym",
            name: "Arnold Split",
            description: "O programa clássico do Arnold Schwarzenegger",
            level: .advanced,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 6,
            weeksTotal: 12,
            workoutTemplates: SpecializedTemplates.arnoldSplit,
            imageURL: nil,
            isPremium: false
        ),
        
        // 22. PHUL (Power Hypertrophy Upper Lower)
        WorkoutProgram(
            id: "phul_intermediate_gym",
            name: "PHUL",
            description: "Combinação de força e hipertrofia",
            level: .intermediate,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 10,
            workoutTemplates: SpecializedTemplates.phul,
            imageURL: nil,
            isPremium: false
        ),
        
        // 23. Minimalist - 2 dias
        WorkoutProgram(
            id: "minimalist_beginner_gym",
            name: "Treino Minimalista",
            description: "Para quem tem pouco tempo - apenas 2x por semana",
            level: .beginner,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 2,
            weeksTotal: 12,
            workoutTemplates: SpecializedTemplates.minimalist,
            imageURL: nil,
            isPremium: false
        ),
        
        // 24. Women's Glute Focus
        WorkoutProgram(
            id: "glute_intermediate_gym",
            name: "Glúteos & Pernas",
            description: "Foco em glúteos e membros inferiores",
            level: .intermediate,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 8,
            workoutTemplates: SpecializedTemplates.gluteFocus,
            imageURL: nil,
            isPremium: false
        ),
        
        // 25. Functional Fitness
        WorkoutProgram(
            id: "functional_intermediate_gym",
            name: "Funcional",
            description: "Treino funcional para atletas e dia a dia",
            level: .intermediate,
            goal: .endurance,
            equipment: .fullGym,
            daysPerWeek: 4,
            weeksTotal: 8,
            workoutTemplates: SpecializedTemplates.functional,
            imageURL: nil,
            isPremium: false
        ),
        
        // 26. Beginner Complete
        WorkoutProgram(
            id: "beginner_complete_gym",
            name: "Programa Completo Iniciante",
            description: "O melhor programa para quem está começando",
            level: .beginner,
            goal: .muscleGain,
            equipment: .fullGym,
            daysPerWeek: 3,
            weeksTotal: 12,
            workoutTemplates: SpecializedTemplates.beginnerComplete,
            imageURL: nil,
            isPremium: false
        ),
    ]
    
    // Busca com filtros
    static func filter(
        level: FitnessLevel? = nil,
        goal: FitnessGoal? = nil,
        equipment: EquipmentType? = nil
    ) -> [WorkoutProgram] {
        allPrograms.filter { $0.matches(level: level, goal: goal, equipment: equipment) }
    }
}
```

### 4.3 Matriz de Combinações (26 programas)

```
┌──────────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│ PROGRAMA         │ INICIANTE   │ INTERMED.   │ AVANÇADO    │ TOTAL       │
├──────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ Push Pull Legs   │ 1 (Gym)     │ 1 (Gym)     │ 1 (Gym)     │ 3           │
│ Full Body        │ 3 (G/D/BW)  │ 1 (Gym)     │ -           │ 4           │
│ Upper Lower      │ 1 (Gym)     │ 2 (G/D)     │ 1 (Gym)     │ 4           │
│ Bro Split        │ -           │ 1 (Gym)     │ 1 (Gym)     │ 2           │
│ Strength         │ 1 (Gym)     │ 1 (Gym)     │ -           │ 2           │
│ Weight Loss      │ 1 (Gym)     │ 1 (BW)      │ 1 (Gym)     │ 3           │
│ Home Gym         │ 1 (Home)    │ 1 (Home)    │ -           │ 2           │
│ Specialized      │ 2           │ 3           │ 1           │ 6           │
├──────────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ TOTAL            │ 10          │ 11          │ 5           │ 26          │
└──────────────────┴─────────────┴─────────────┴─────────────┴─────────────┘

Legenda: G = Gym, D = Dumbbell, BW = Bodyweight, Home = Home Gym
```

### 4.4 UI dos Filtros

```swift
// MARK: - Arquivo: Views/Workout/ProgramFiltersView.swift

struct ProgramFiltersView: View {
    @Binding var selectedLevel: FitnessLevel?
    @Binding var selectedGoal: FitnessGoal?
    @Binding var selectedEquipment: EquipmentType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: selectedLevel?.rawValue ?? "Nível",
                    isSelected: selectedLevel != nil,
                    options: FitnessLevel.allCases,
                    selection: $selectedLevel
                )
                
                FilterChip(
                    title: selectedGoal?.rawValue ?? "Objetivo",
                    isSelected: selectedGoal != nil,
                    options: FitnessGoal.allCases,
                    selection: $selectedGoal
                )
                
                FilterChip(
                    title: selectedEquipment?.rawValue ?? "Equipamento",
                    isSelected: selectedEquipment != nil,
                    options: EquipmentType.allCases,
                    selection: $selectedEquipment
                )
                
                if hasActiveFilters {
                    Button("Limpar") {
                        clearFilters()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}
```

### 4.5 Tarefas de Implementação - Programas

```
□ 4.5.1  Criar ProgramModels.swift
□ 4.5.2  Criar ProgramsCatalog.swift com todos os 26 programas
□ 4.5.3  Criar arquivos de templates (PPLTemplates.swift, etc.)
□ 4.5.4  Definir exercícios específicos para cada programa (IDs Wger)
□ 4.5.5  Criar ProgramsListView.swift
□ 4.5.6  Criar ProgramFiltersView.swift
□ 4.5.7  Criar ProgramDetailView.swift
□ 4.5.8  Criar ProgramWorkoutPreviewView.swift
□ 4.5.9  Implementar "Iniciar Programa" (converte para templates)
□ 4.5.10 Implementar progresso de programa (semana atual, etc.)
□ 4.5.11 Criar testes unitários para filtros
□ 4.5.12 Testar todas as combinações de filtros
```

---

## 5. Fase 4: Integração Histórico + Desafios

### 5.1 Nova Estrutura da Aba Activity

```
┌─────────────────────────────────────────────────────────┐
│                    ACTIVITY TAB                         │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │           SEGMENTED CONTROL                      │   │
│  │   [ Histórico ]  [ Desafios ]  [ Stats ]        │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ════════════════════════════════════════════════════  │
│                                                         │
│  SE "Histórico":                                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📅 CALENDÁRIO MENSAL                           │   │
│  │  ┌───┬───┬───┬───┬───┬───┬───┐                 │   │
│  │  │ D │ S │ T │ Q │ Q │ S │ S │                 │   │
│  │  ├───┼───┼───┼───┼───┼───┼───┤                 │   │
│  │  │   │   │ 1 │ 2 │🔵│ 4 │ 5 │                 │   │
│  │  │ 6 │🔵│🔵│ 9 │🔵│11 │12 │                 │   │
│  │  │...│...│...│...│...│...│...│                 │   │
│  │  └───┴───┴───┴───┴───┴───┴───┘                 │   │
│  │  🔵 = Dias com treino                           │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  JANEIRO 2026                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📋 Treino A - Peito e Tríceps                  │   │
│  │  Seg, 27 Jan • 45min • 12,500kg volume         │   │
│  │  8 exercícios • 24 séries                       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ════════════════════════════════════════════════════  │
│                                                         │
│  SE "Desafios":                                        │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🏆 DESAFIOS ATIVOS                             │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🔥 30 Dias de Treino                           │   │
│  │  Progresso: 18/30 dias                          │   │
│  │  ████████████░░░░░░░░ 60%                       │   │
│  │  Termina em: 12 dias                            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Sincronização de Dados

```
┌─────────────────────────────────────────────────────────┐
│                  FLUXO DE DADOS                         │
└─────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │  APPLE HEALTH │
                    │  (HealthKit)  │
                    └──────┬───────┘
                           │
                           │ Leitura de:
                           │ - Workout sessions
                           │ - Active energy burned
                           │ - Heart rate
                           │ - Steps
                           ▼
┌──────────────────────────────────────────────────────────┐
│                  SYNC MANAGER                            │
│  ┌────────────────────────────────────────────────────┐ │
│  │  1. Busca workouts do Apple Health                 │ │
│  │  2. Busca workouts do Firebase                     │ │
│  │  3. Merge baseado em timestamp + source            │ │
│  │  4. Evita duplicatas                               │ │
│  │  5. Atualiza Firebase com dados consolidados       │ │
│  │  6. Atualiza progresso de desafios                 │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │  HISTÓRICO │  │  DESAFIOS  │  │   STATS    │
    │  (Lista)   │  │ (Progresso)│  │ (Gráficos) │
    └────────────┘  └────────────┘  └────────────┘
```

### 5.3 Modelo de Dados Unificado

```swift
// MARK: - Arquivo: Models/ActivityModels.swift

// Sessão de treino unificada (fonte única de verdade)
struct UnifiedWorkoutSession: Identifiable, Codable {
    let id: String
    let userId: String
    
    // Identificação
    var name: String
    var templateId: String?
    var programId: String?
    
    // Timing
    var startedAt: Date
    var completedAt: Date?
    var duration: TimeInterval
    
    // Métricas
    var totalVolume: Double          // kg totais levantados
    var totalSets: Int
    var totalReps: Int
    var caloriesBurned: Double?
    var avgHeartRate: Double?
    
    // Exercícios
    var exercises: [CompletedExercise]
    
    // Fonte dos dados
    var source: WorkoutSource
    var healthKitId: UUID?           // ID do Apple Health se sincronizado
    
    // Desafios
    var challengeContributions: [ChallengeContribution]
    
    // Computed
    var isCompleted: Bool { completedAt != nil }
}

enum WorkoutSource: String, Codable {
    case app = "app"                 // Criado no app
    case healthKit = "health_kit"    // Importado do Apple Health
    case merged = "merged"           // Dados combinados
}

struct ChallengeContribution: Codable {
    let challengeId: String
    let contributionType: ContributionType
    let value: Double
    let countedAt: Date
}

enum ContributionType: String, Codable {
    case workout = "workout"         // +1 treino
    case volume = "volume"           // +X kg de volume
    case duration = "duration"       // +X minutos
    case calories = "calories"       // +X calorias
}
```

### 5.4 Sync Manager

```swift
// MARK: - Arquivo: Services/WorkoutSyncManager.swift

final class WorkoutSyncManager: ObservableObject {
    private let healthKitService: HealthKitService
    private let firestoreService: FirestoreService
    private let challengeService: ChallengeService
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    // Sincronização principal
    func syncWorkouts() async throws {
        syncStatus = .syncing
        
        do {
            // 1. Buscar workouts do HealthKit (últimos 30 dias)
            let healthWorkouts = try await healthKitService.fetchWorkouts(
                from: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                to: Date()
            )
            
            // 2. Buscar workouts do Firebase
            let firebaseWorkouts = try await firestoreService.fetchUserWorkouts(
                from: Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            )
            
            // 3. Merge inteligente
            let mergedWorkouts = mergeWorkouts(
                healthKit: healthWorkouts,
                firebase: firebaseWorkouts
            )
            
            // 4. Salvar workouts novos/atualizados
            for workout in mergedWorkouts where workout.needsSync {
                try await firestoreService.saveWorkout(workout)
            }
            
            // 5. Atualizar progresso dos desafios
            try await challengeService.updateProgress(with: mergedWorkouts)
            
            syncStatus = .completed
            lastSyncDate = Date()
            
        } catch {
            syncStatus = .failed(error)
            throw error
        }
    }
    
    // Merge de workouts evitando duplicatas
    private func mergeWorkouts(
        healthKit: [HKWorkout],
        firebase: [UnifiedWorkoutSession]
    ) -> [UnifiedWorkoutSession] {
        var merged: [UnifiedWorkoutSession] = []
        var processedHealthKitIds: Set<UUID> = []
        
        // Processar workouts do Firebase
        for fbWorkout in firebase {
            if let hkId = fbWorkout.healthKitId {
                processedHealthKitIds.insert(hkId)
            }
            merged.append(fbWorkout)
        }
        
        // Adicionar workouts do HealthKit não processados
        for hkWorkout in healthKit {
            if !processedHealthKitIds.contains(hkWorkout.uuid) {
                // Verificar se já existe por timestamp similar (±5 min)
                let isDuplicate = firebase.contains { fb in
                    abs(fb.startedAt.timeIntervalSince(hkWorkout.startDate)) < 300
                }
                
                if !isDuplicate {
                    let unified = UnifiedWorkoutSession(from: hkWorkout)
                    merged.append(unified)
                }
            }
        }
        
        return merged.sorted { $0.startedAt > $1.startedAt }
    }
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(Error)
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}
```

### 5.5 Tarefas de Implementação - Activity

```
□ 5.5.1  Criar ActivityModels.swift
□ 5.5.2  Criar UnifiedWorkoutSession model
□ 5.5.3  Criar WorkoutSyncManager.swift
□ 5.5.4  Criar HealthKitService.swift (leitura de workouts)
□ 5.5.5  Atualizar FirestoreService para novo modelo
□ 5.5.6  Criar ActivityTabView.swift (nova aba unificada)
□ 5.5.7  Criar WorkoutHistoryView.swift com calendário
□ 5.5.8  Criar WorkoutDetailView.swift (histórico detalhado)
□ 5.5.9  Criar ChallengesListView.swift
□ 5.5.10 Criar ChallengeDetailView.swift
□ 5.5.11 Criar StatsView.swift com gráficos
□ 5.5.12 Implementar lógica de merge sem duplicatas
□ 5.5.13 Implementar atualização automática de desafios
□ 5.5.14 Adicionar background sync
□ 5.5.15 Testar sincronização bidirecional
```

---

## 6. Fase 5: Tela Inicial com IA

### 6.1 Novo Fluxo da Home

```
┌─────────────────────────────────────────────────────────┐
│                      HOME TAB                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Olá, [Nome]! 👋                                       │
│  Pronto para treinar?                                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  🧠 GERAR TREINO COM IA                         │   │
│  │                                                  │   │
│  │  O que você quer treinar hoje?                  │   │
│  │  ┌────────────────────────────────────────────┐ │   │
│  │  │ Peito │ Costas │ Pernas │ Ombros │ Braços │ │   │
│  │  │  ✓   │       │   ✓    │        │        │ │   │
│  │  └────────────────────────────────────────────┘ │   │
│  │                                                  │   │
│  │  Como está seu corpo?                           │   │
│  │  😫 ─────●───── 💪                              │   │
│  │  Cansado      Descansado                        │   │
│  │                                                  │   │
│  │  Quanto tempo você tem?                         │   │
│  │  [ 30min ] [ 45min ] [ 60min ] [ 90min ]       │   │
│  │             ✓                                   │   │
│  │                                                  │   │
│  │  ┌────────────────────────────────────────────┐ │   │
│  │  │       ✨ GERAR MEU TREINO                  │ │   │
│  │  └────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                                         │
│  📋 CONTINUAR TREINO                                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Treino A - Peito e Tríceps                     │   │
│  │  Último: ontem • Próximo exercício: Supino      │   │
│  │                              [CONTINUAR →]      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  🔥 SEU STREAK: 5 dias                                 │
│  ████████████░░░░░░░░░░░░░ Meta: 7 dias               │
│                                                         │
│  📊 ESTA SEMANA                                        │
│  Treinos: 3/5 • Volume: 45,000kg • Tempo: 2h 15min    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Integração OpenAI + Wger

```swift
// MARK: - Arquivo: Services/AIWorkoutGenerator.swift

final class AIWorkoutGenerator {
    private let openAIService: OpenAIService
    private let wgerService: WgerAPIService
    private let exerciseCache: ExerciseCacheManager
    
    struct GenerationInput {
        let targetMuscles: [MuscleGroup]
        let fatigueLevel: Int          // 1-5
        let availableTime: Int         // minutos
        let equipment: EquipmentType
        let fitnessLevel: FitnessLevel
        let recentWorkouts: [UnifiedWorkoutSession] // Últimos 7 dias
    }
    
    func generateWorkout(input: GenerationInput) async throws -> GeneratedWorkout {
        // 1. Buscar exercícios disponíveis da Wger para os músculos selecionados
        let availableExercises = try await fetchAvailableExercises(
            muscles: input.targetMuscles,
            equipment: input.equipment
        )
        
        // 2. Construir prompt otimizado
        let prompt = buildPrompt(input: input, exercises: availableExercises)
        
        // 3. Chamar OpenAI
        let response = try await openAIService.generateCompletion(
            prompt: prompt,
            responseFormat: .json
        )
        
        // 4. Parsear resposta em workout estruturado
        let workout = try parseResponse(response, availableExercises: availableExercises)
        
        return workout
    }
    
    private func buildPrompt(input: GenerationInput, exercises: [WgerExercise]) -> String {
        """
        Você é um personal trainer experiente. Crie um treino personalizado.
        
        CONTEXTO DO USUÁRIO:
        - Músculos alvo: \(input.targetMuscles.map(\.rawValue).joined(separator: ", "))
        - Nível de fadiga: \(input.fatigueLevel)/5 (\(fatigueDescription(input.fatigueLevel)))
        - Tempo disponível: \(input.availableTime) minutos
        - Equipamento: \(input.equipment.rawValue)
        - Nível fitness: \(input.fitnessLevel.rawValue)
        - Treinos recentes: \(summarizeRecentWorkouts(input.recentWorkouts))
        
        EXERCÍCIOS DISPONÍVEIS (use APENAS estes IDs):
        \(formatExercisesList(exercises))
        
        REGRAS:
        1. Use APENAS os IDs de exercícios listados acima
        2. Ajuste volume baseado na fadiga (menos séries se fadiga > 3)
        3. Respeite o tempo disponível
        4. Evite repetir músculos treinados nos últimos 2 dias
        5. Inclua aquecimento se tempo > 45min
        
        RESPONDA EM JSON:
        {
            "name": "Nome do treino",
            "exercises": [
                {
                    "exerciseId": 123,
                    "sets": 3,
                    "reps": "8-12",
                    "restSeconds": 90,
                    "notes": "Dica opcional"
                }
            ],
            "estimatedDuration": 45,
            "warmupIncluded": true,
            "focusAreas": ["peito", "tríceps"]
        }
        """
    }
    
    private func fetchAvailableExercises(
        muscles: [MuscleGroup],
        equipment: EquipmentType
    ) async throws -> [WgerExercise] {
        var allExercises: [WgerExercise] = []
        
        for muscle in muscles {
            let categoryId = muscle.wgerCategoryId
            let exercises = try await wgerService.fetchExercises(
                language: "4", // Português
                category: categoryId,
                equipment: equipment.wgerEquipmentIds
            )
            allExercises.append(contentsOf: exercises)
        }
        
        return allExercises.uniqued(by: \.id)
    }
}

struct GeneratedWorkout {
    let name: String
    let exercises: [WorkoutExercise]
    let estimatedDuration: Int
    let warmupIncluded: Bool
    let focusAreas: [String]
    
    func toTemplate() -> WorkoutTemplate {
        var template = WorkoutTemplate(name: name)
        template.exercises = exercises
        template.estimatedDuration = estimatedDuration
        return template
    }
}
```

### 6.3 Mapeamento Músculos → Wger Categories

```swift
// MARK: - Arquivo: Models/MuscleMapping.swift

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "Peito"
    case back = "Costas"
    case shoulders = "Ombros"
    case biceps = "Bíceps"
    case triceps = "Tríceps"
    case legs = "Pernas"
    case core = "Abdômen"
    case glutes = "Glúteos"
    
    var wgerCategoryId: Int {
        switch self {
        case .chest: return 11
        case .back: return 12
        case .shoulders: return 13
        case .biceps: return 8
        case .triceps: return 8  // Arms category
        case .legs: return 9
        case .core: return 10
        case .glutes: return 9   // Legs category
        }
    }
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .biceps: return "figure.boxing"
        case .triceps: return "figure.boxing"
        case .legs: return "figure.run"
        case .core: return "figure.core.training"
        case .glutes: return "figure.run"
        }
    }
}
```

### 6.4 Tarefas de Implementação - Home + IA

```
□ 6.4.1  Criar AIWorkoutGenerator.swift
□ 6.4.2  Criar MuscleMapping.swift
□ 6.4.3  Atualizar OpenAIService para novo prompt
□ 6.4.4  Criar HomeTabView.swift (nova home)
□ 6.4.5  Criar AIWorkoutInputView.swift (seleção de inputs)
□ 6.4.6  Criar MuscleSelectionGrid.swift
□ 6.4.7  Criar FatigueSlider.swift
□ 6.4.8  Criar TimeSelectionView.swift
□ 6.4.9  Criar AIGeneratingView.swift (loading state)
□ 6.4.10 Criar GeneratedWorkoutPreview.swift
□ 6.4.11 Implementar "Iniciar Treino" direto da geração
□ 6.4.12 Implementar "Salvar como Template"
□ 6.4.13 Adicionar streak tracking
□ 6.4.14 Adicionar weekly summary
□ 6.4.15 Testar geração com diferentes inputs
□ 6.4.16 Otimizar prompt para melhores resultados
```

---

## 7. Arquitetura de Dados

### 7.1 Estrutura Firebase Firestore

```
firestore/
├── users/
│   └── {userId}/
│       ├── profile/
│       │   └── data (nome, email, foto, preferências)
│       │
│       ├── workoutTemplates/
│       │   └── {templateId} (WorkoutTemplate)
│       │
│       ├── workoutSessions/
│       │   └── {sessionId} (UnifiedWorkoutSession)
│       │
│       ├── challenges/
│       │   └── {challengeId}/
│       │       ├── data (Challenge info)
│       │       └── progress (ChallengeProgress)
│       │
│       ├── stats/
│       │   └── weekly/
│       │       └── {weekId} (WeeklyStats)
│       │
│       └── settings/
│           └── preferences (notificações, unidades, etc.)
│
├── programs/
│   └── {programId} (WorkoutProgram - read-only)
│
├── exerciseCache/
│   └── {language}/
│       └── exercises (cache da Wger API)
│
└── publicChallenges/
    └── {challengeId} (desafios globais)
```

### 7.2 Estrutura Local (Core Data / SwiftData)

```swift
// MARK: - Arquivo: Models/LocalModels.swift

// Cache local para acesso offline
@Model
class CachedExercise {
    @Attribute(.unique) var id: Int
    var name: String
    var descriptionText: String
    var category: Int
    var muscles: [Int]
    var equipment: [Int]
    var imageData: Data?
    var lastUpdated: Date
}

@Model
class LocalWorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var exercisesData: Data // JSON encoded
    var lastModified: Date
    var needsSync: Bool
}
```

### 7.3 Diagrama de Relacionamentos

```
┌──────────────────────────────────────────────────────────────────┐
│                        USER                                       │
├──────────────────────────────────────────────────────────────────┤
│ id: String                                                        │
│ email: String                                                     │
│ displayName: String                                               │
│ photoURL: String?                                                 │
│ createdAt: Date                                                   │
│ settings: UserSettings                                            │
└──────────────────────────────────────────────────────────────────┘
        │
        │ 1:N
        ▼
┌──────────────────────────────────────────────────────────────────┐
│                   WORKOUT_TEMPLATE                                │
├──────────────────────────────────────────────────────────────────┤
│ id: UUID                                                          │
│ userId: String (FK)                                               │
│ name: String                                                      │
│ exercises: [WorkoutExercise]                                     │
│ programId: String? (FK)                                          │
│ createdAt: Date                                                   │
└──────────────────────────────────────────────────────────────────┘
        │
        │ 1:N
        ▼
┌──────────────────────────────────────────────────────────────────┐
│                 WORKOUT_SESSION                                   │
├──────────────────────────────────────────────────────────────────┤
│ id: String                                                        │
│ userId: String (FK)                                               │
│ templateId: UUID? (FK)                                           │
│ exercises: [CompletedExercise]                                   │
│ startedAt: Date                                                   │
│ completedAt: Date?                                                │
│ source: WorkoutSource                                             │
│ healthKitId: UUID?                                                │
└──────────────────────────────────────────────────────────────────┘
        │
        │ N:N
        ▼
┌──────────────────────────────────────────────────────────────────┐
│                     CHALLENGE                                     │
├──────────────────────────────────────────────────────────────────┤
│ id: String                                                        │
│ name: String                                                      │
│ type: ChallengeType                                               │
│ goal: Double                                                      │
│ currentProgress: Double                                           │
│ startDate: Date                                                   │
│ endDate: Date                                                     │
│ participants: [String]                                            │
└──────────────────────────────────────────────────────────────────┘
```

---

## 8. Cronograma de Execução

### 8.1 Timeline Geral (10 Semanas)

```
┌──────────────────────────────────────────────────────────────────┐
│                    TIMELINE DE EXECUÇÃO                          │
├──────┬───────────────────────────────────────────────────────────┤
│ S01  │ 🔄 FASE 1: Migração API (Wger)                            │
│      │    - Setup WgerAPIService                                 │
│      │    - Modelos de dados                                     │
│      │    - Sistema de cache                                     │
├──────┼───────────────────────────────────────────────────────────┤
│ S02  │ 🔄 FASE 1: Migração API (Finalização)                     │
│      │    - Fallback visual                                      │
│      │    - Remover ExerciseDB                                   │
│      │    - Testes de integração                                 │
├──────┼───────────────────────────────────────────────────────────┤
│ S03  │ 💪 FASE 2: Sistema de Workouts (Modelos)                  │
│      │    - WorkoutTemplate, Session models                      │
│      │    - Persistência local + Firebase                        │
│      │    - Repository pattern                                   │
├──────┼───────────────────────────────────────────────────────────┤
│ S04  │ 💪 FASE 2: Sistema de Workouts (UI Criação)               │
│      │    - WorkoutTabView                                       │
│      │    - CreateWorkoutView                                    │
│      │    - ExerciseSearchView                                   │
├──────┼───────────────────────────────────────────────────────────┤
│ S05  │ 💪 FASE 2: Sistema de Workouts (UI Execução)              │
│      │    - WorkoutExecutionView                                 │
│      │    - RestTimerView                                        │
│      │    - WorkoutSummaryView                                   │
├──────┼───────────────────────────────────────────────────────────┤
│ S06  │ 📚 FASE 3: Programas Pré-Montados                         │
│      │    - Catálogo de 26 programas                             │
│      │    - Sistema de filtros                                   │
│      │    - UI de listagem e detalhes                            │
├──────┼───────────────────────────────────────────────────────────┤
│ S07  │ 📊 FASE 4: Histórico + Desafios (Sync)                    │
│      │    - WorkoutSyncManager                                   │
│      │    - HealthKit integration                                │
│      │    - Merge logic                                          │
├──────┼───────────────────────────────────────────────────────────┤
│ S08  │ 📊 FASE 4: Histórico + Desafios (UI)                      │
│      │    - ActivityTabView unificada                            │
│      │    - Calendário de histórico                              │
│      │    - Desafios com progresso                               │
├──────┼───────────────────────────────────────────────────────────┤
│ S09  │ 🧠 FASE 5: Home com IA                                    │
│      │    - Nova HomeTabView                                     │
│      │    - AIWorkoutGenerator                                   │
│      │    - Integração OpenAI + Wger                             │
├──────┼───────────────────────────────────────────────────────────┤
│ S10  │ 🧪 FASE FINAL: Testes e Polish                            │
│      │    - Testes E2E                                           │
│      │    - Bug fixes                                            │
│      │    - Performance optimization                             │
│      │    - Preparação para release                              │
└──────┴───────────────────────────────────────────────────────────┘
```

### 8.2 Milestones

| Milestone | Data | Entregável |
|-----------|------|------------|
| M1 | Fim S02 | API Wger funcionando, ExerciseDB removida |
| M2 | Fim S05 | Fluxo completo de criar/executar treino |
| M3 | Fim S06 | 26 programas disponíveis com filtros |
| M4 | Fim S08 | Histórico + Desafios unificados com sync |
| M5 | Fim S10 | App pronto para beta testing |

---

## 9. Checklist de Implementação

### 9.1 Fase 1: Migração API ✅

```
□ Criar estrutura de pastas para novos services
□ WgerAPIService.swift
□ WgerModels.swift
□ ExerciseCacheManager.swift
□ Mapeamento de categorias (muscle groups)
□ Mapeamento de equipamentos
□ Busca com paginação
□ Cache de imagens em disco
□ Fallback visual (SF Symbols)
□ Remover ExerciseDB dependencies
□ Atualizar ViewModels existentes
□ Testes unitários
```

### 9.2 Fase 2: Sistema de Workouts ✅

```
□ WorkoutModels.swift (Template, Exercise, Set)
□ WorkoutTemplateRepository.swift
□ WorkoutSessionRepository.swift
□ WorkoutTabView.swift
□ MyWorkoutsView.swift
□ CreateWorkoutView.swift
□ ExerciseSearchView.swift
□ ExerciseConfigSheet.swift
□ WorkoutExecutionView.swift
□ RestTimerView.swift
□ WorkoutSummaryView.swift
□ Drag & drop para reordenar
□ Swipe actions
□ Haptic feedback
□ Build da aplicação
```

### 9.3 Fase 3: Programas Pré-Montados ✅

```
□ ProgramModels.swift
□ ProgramsCatalog.swift
□ PPLTemplates.swift
□ FullBodyTemplates.swift
□ UpperLowerTemplates.swift
□ BroSplitTemplates.swift
□ StrengthTemplates.swift
□ WeightLossTemplates.swift
□ HomeGymTemplates.swift
□ SpecializedTemplates.swift
□ ProgramsListView.swift
□ ProgramFiltersView.swift
□ ProgramDetailView.swift
□ ProgramWorkoutPreviewView.swift
□ "Iniciar Programa" flow
□ Progresso de programa
□ Testes de filtros
```

### 9.4 Fase 4: Histórico + Desafios ✅

```
□ ActivityModels.swift
□ UnifiedWorkoutSession model
□ ChallengeContribution model
□ WorkoutSyncManager.swift
□ HealthKitService.swift
□ Atualizar FirestoreService
□ ActivityTabView.swift
□ WorkoutHistoryView.swift (com calendário)
□ WorkoutDetailView.swift
□ ChallengesListView.swift
□ ChallengeDetailView.swift
□ StatsView.swift
□ Merge logic sem duplicatas
□ Auto-update de desafios
□ Background sync
□ Testes de sincronização
```

### 9.5 Fase 5: Home + IA ✅

```
□ AIWorkoutGenerator.swift
□ MuscleMapping.swift
□ Atualizar OpenAIService
□ HomeTabView.swift
□ AIWorkoutInputView.swift
□ MuscleSelectionGrid.swift
□ FatigueSlider.swift
□ TimeSelectionView.swift
□ AIGeneratingView.swift
□ GeneratedWorkoutPreview.swift
□ "Iniciar Treino" da geração
□ "Salvar como Template"
□ Streak tracking
□ Weekly summary
□ Testes de geração
□ Otimização de prompt
```

### 9.6 Tarefas Gerais ✅

```
□ Atualizar TabBar (Programs → Workout)
□ Atualizar Navigation structure
□ Atualizar App entry point
□ Configurar HealthKit entitlements
□ Configurar Firebase rules
□ Criar README atualizado
□ Preparar TestFlight build
```

---

## 📝 Notas Adicionais

### Riscos e Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Wger API indisponível | Alto | Cache agressivo + fallback local |
| OpenAI rate limits | Médio | Debounce + cache de respostas similares |
| Sync conflicts | Médio | Last-write-wins + conflict resolution UI |
| Performance com muitos exercícios | Baixo | Lazy loading + paginação |

### Decisões Técnicas

1. **SwiftData vs Core Data**: Usar SwiftData (iOS 17+) para cache local
2. **Async/Await**: Usar em todos os services novos
3. **Combine vs AsyncStream**: Preferir AsyncStream para novos fluxos
4. **Navigation**: Usar AppRouter com path-based navigation

### Recursos Úteis

- [Wger API Docs](https://wger.de/en/software/api)
- [HealthKit Best Practices](https://developer.apple.com/documentation/healthkit)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [Firebase Firestore](https://firebase.google.com/docs/firestore)

---

**Última atualização:** Janeiro 2026  
**Versão do documento:** 1.0
