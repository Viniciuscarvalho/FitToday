# Tasks: Ajustes em Desafios, Stats, Configuracoes e Explorar

## Task 1: Ocultar API Key em Producao
**Arquivo**: `Presentation/Features/Pro/ProfileProView.swift`
**Descricao**: Envolver SettingsRow da API key + Divider em `#if DEBUG`
**Complexidade**: Baixa
**Dependencias**: Nenhuma

## Task 2: Conectar Botao Explorar
**Arquivos**: `Router/AppRouter.swift`, `Root/TabRootView.swift`, `Programs/Views/ProgramsListView.swift`
**Descricao**:
- Adicionar `case libraryExplore` ao enum `AppRoute`
- Adicionar destination no `TabRootView`
- Conectar acao do botao "Explorar" ao push da rota
**Complexidade**: Baixa
**Dependencias**: Nenhuma

## Task 3: Wire Share/Invite nos Desafios
**Arquivos**: `Activity/Views/ChallengesView.swift`, `Groups/Views/GroupsView.swift`
**Descricao**:
- ChallengeDetailView: adicionar groupId param, showShareSheet state, wiring com InviteShareSheet + GenerateInviteLinkUseCase
- GroupsView: implementar handleInviteTapped com showInviteSheet + InviteShareSheet
**Complexidade**: Media
**Dependencias**: `InviteShareSheet`, `GenerateInviteLinkUseCase` (ambos existentes)

## Task 4: Criar ActivityStatsViewModel
**Arquivo NOVO**: `Presentation/Features/Activity/ViewModels/ActivityStatsViewModel.swift`
**Descricao**:
- @Observable @MainActor class com UserStatsRepository + WorkoutHistoryRepository
- Metodo loadStats() para buscar UserStats
- Metodo loadChartData() para agrupar WorkoutHistoryEntry por dia e por semana
- Models: DailyChartEntry, WeeklyChartEntry
**Complexidade**: Media
**Dependencias**: `UserStatsRepository`, `WorkoutHistoryRepository`

## Task 5: Reescrever ActivityStatsView com Swift Charts
**Arquivo**: `Presentation/Features/Activity/Views/ActivityTabView.swift`
**Descricao**:
- Adicionar `import Charts`
- Conectar ActivityStatsView ao ActivityStatsViewModel
- Substituir dados mock por dados reais
- Criar graficos de barras: treinos diarios (semana) + treinos semanais (mes)
- Manter summary cards no topo com dados reais
**Complexidade**: Alta
**Dependencias**: Task 4

## Task 6: Build e Verificacao
**Descricao**: Compilar e verificar que tudo funciona
**Complexidade**: Baixa
**Dependencias**: Tasks 1-5
