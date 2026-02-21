# PRD: Ajustes em Desafios, Stats, Configuracoes e Explorar

## Resumo

Correcao de bugs e melhorias em quatro areas do app FitToday:
1. **Desafios**: Share/invite nao funciona, criacao de desafio limitada
2. **Stats**: Substituir cards por graficos (Swift Charts)
3. **Configuracoes**: Ocultar chave de API em producao
4. **Explorar**: Botao sem funcionalidade

## Problemas Identificados

### 1. Desafios - Share/Invite Nao Funciona
- **ChallengeDetailView**: Botao de compartilhar na toolbar e um stub sem acao
- **GroupsView.handleInviteTapped()**: Stub com comentario, nao conectado ao `InviteShareSheet`
- **InviteShareSheet** e **GenerateInviteLinkUseCase** ja existem e estao implementados, so nao estao wired

### 2. Stats - Cards Estaticos com Dados Mock
- **ActivityStatsView**: Placeholder com dados hardcoded ("3", "2.5 ton", "12")
- Sem ViewModel — nao conectado ao `UserStatsRepository`
- **UserStats** domain entity ja existe com dados reais (weekly/monthly)
- Nenhum uso de Swift Charts no projeto

### 3. Configuracoes - API Key Visivel para Todos
- `ProfileProView.swift` exibe `SettingsRow(icon: "key")` para todos os usuarios
- Essa e uma chave pessoal OpenAI, deve ser visivel apenas em `#if DEBUG`

### 4. Explorar - Botao Sem Funcionalidade
- `ProgramsListView.swift`: Botao "Explorar" tem acao vazia (TODO)
- Nao existe rota `AppRoute.explore` no Router
- Rota deve levar ao catalogo de exercicios da Library

## Requisitos

### R1: Conectar Share/Invite nos Desafios
- Wiring do share button em `ChallengeDetailView` com `InviteShareSheet`
- Wiring do invite button em `GroupsView` com `InviteShareSheet`
- Usar `GenerateInviteLinkUseCase` existente

### R2: Stats com Swift Charts
- Criar `ActivityStatsViewModel` conectado ao `UserStatsRepository`
- Substituir `ActivityStatCard` por graficos usando `import Charts`
- Grafico de barras para treinos semanais (dia a dia)
- Grafico de barras para treinos mensais (semana a semana)
- Manter cards resumo no topo (total treinos, calorias, streak)

### R3: Ocultar API Key em Producao
- Envolver o `SettingsRow` da API key em `#if DEBUG`

### R4: Conectar Botao Explorar
- Adicionar rota `AppRoute.libraryExplore` no Router
- Conectar botao "Explorar" em `ProgramsListView` a essa rota
- Destino: tela de Library existente (catalogo de exercicios)

## Fora de Escopo
- Criacao de novos tipos de desafio
- Backend changes
- Novos endpoints de API
