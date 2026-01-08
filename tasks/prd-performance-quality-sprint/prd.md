# PRD - Performance & Quality Sprint

## Visão Geral

O FitToday possui um core sólido de geração de treinos com IA funcionando através de OpenAI, com arquitetura Clean Architecture bem estabelecida. No entanto, existem gaps críticos em três áreas fundamentais que impactam a experiência do usuário e a confiabilidade do app:

1. **Performance e Offline Experience**: Dependência de rede para carregar imagens durante treinos, sem cache persistente
2. **Error Handling**: Tratamento inconsistente de erros, mensagens técnicas expostas ao usuário final
3. **Query Performance**: Queries SwiftData sem otimização, causando lentidão em histórico extenso

**Solução**: Implementar melhorias incrementais organizadas em 3 fases, com foco inicial (Sprint de 2 semanas) em Performance e Error Handling.

**Valor para o usuário**:
- App utilizável 100% offline após primeiro uso
- Feedback claro e acionável quando algo dá errado
- Experiência fluida mesmo com histórico extenso de treinos
- Maior confiança na estabilidade do aplicativo

## Objetivos

### Fase 1 (Prioridade: CRITICAL - Sprint 2 semanas)

**Objetivos mensuráveis:**

1. **Reduzir falhas relacionadas a rede durante treinos**
   - Meta: 0% de falhas de carregamento de imagens após primeiro uso
   - Métrica: Taxa de cache hit > 95%

2. **Melhorar performance de queries SwiftData**
   - Meta: Carregar tela de histórico em < 100ms
   - Métrica: Time to interactive da HistoryView

3. **Implementar error handling consistente**
   - Meta: 100% dos erros mostram mensagem amigável
   - Métrica: 0 mensagens técnicas expostas em produção

4. **Tornar app utilizável offline**
   - Meta: Core features funcionam sem internet
   - Métrica: Teste de fluxo completo em modo avião

**Objetivos de negócio:**
- Reduzir churn relacionado a problemas técnicos
- Melhorar rating na App Store (reviews sobre crashes/erros)
- Aumentar engajamento (menos frustração = mais uso)

### Fase 2 (Prioridade: HIGH - Próximo sprint)

**Objetivos mensuráveis:**

1. **Melhorar conversão Free → Pro**
   - Meta: +15% de conversão com paywall otimizado
   - Métrica: Taxa de conversão antes/depois

2. **Reduzir abandono no onboarding**
   - Meta: 70% dos usuários completam primeiro treino
   - Métrica: Funil de onboarding (etapa por etapa)

3. **Adicionar tracking durante treino**
   - Meta: 60% dos usuários registram pelo menos 1 série
   - Métrica: Usage do workout timer

### Fase 3 (Prioridade: MEDIUM - Backlog)

**Objetivos mensuráveis:**

1. **Otimizar custos de API OpenAI**
   - Meta: Reduzir 30% de chamadas redundantes via cache
   - Métrica: $ gasto mensal com OpenAI

2. **Aumentar cobertura de testes**
   - Meta: Domain 80%, ViewModels 70%, Repos 60%
   - Métrica: Code coverage reports

## Histórias de Usuário

### Como usuário iniciando treino

**História 1: Imagens offline**
- Como usuário que treina na academia (WiFi instável)
- Eu quero ver imagens dos exercícios instantaneamente
- Para que eu não perca tempo esperando carregar ou fique sem referência visual

**Critérios de aceitação:**
- Imagens aparecem em < 1 segundo após abrir treino
- Funciona 100% em modo avião após primeiro download
- Placeholder com ícone do músculo aparece se imagem ainda não cacheada

**História 2: Continuidade offline**
- Como usuário treinando sem internet
- Eu quero continuar meu treino normalmente
- Para que problemas de conexão não interrompam minha sessão

**Critérios de aceitação:**
- Todas as telas do treino funcionam sem internet
- Apenas geração de novo treino com IA requer conexão
- Mensagem clara quando função precisa de internet

**História 3: Erros compreensíveis**
- Como usuário quando algo dá errado
- Eu quero entender claramente o que aconteceu e o que fazer
- Para que eu não fique perdido com mensagens técnicas

**Critérios de aceitação:**
- Linguagem em português coloquial
- Ação clara de recuperação (tentar novamente, ir para configurações, etc)
- Sem termos técnicos (timeout, API error, etc)

### Como usuário Pro

**História 4: Feedback de fallback**
- Como usuário Pro que paga pela IA
- Eu quero saber quando a IA não está disponível e o treino foi gerado localmente
- Para que eu entenda a qualidade do treino que estou recebendo

**Critérios de aceitação:**
- Badge ou mensagem indicando "Treino gerado localmente"
- Explicação breve e positiva (ex: "Geramos um ótimo treino com base no seu perfil")
- Opção de tentar gerar com IA novamente quando conexão voltar

### Como usuário Free

**História 5: Value proposition clara**
- Como usuário Free explorando o app
- Eu quero entender claramente o que ganho com Pro
- Para que eu possa decidir se vale a pena assinar

**Critérios de aceitação:**
- Comparação visual Free vs Pro
- Exemplos concretos de personalização da IA
- Não ser bloqueado de forma agressiva (soft paywall)

**História 6: Onboarding rápido**
- Como novo usuário ansioso para começar
- Eu quero treinar o quanto antes
- Para que eu veja valor no app antes de responder 20 perguntas

**Critérios de aceitação:**
- Gerar primeiro treino com apenas 2-3 perguntas
- Opção "Treinar agora com defaults"
- Coleta progressiva de perfil depois

## Funcionalidades Principais

### F1. Image Caching System (Fase 1)

**O que faz:**
Sistema híbrido de cache de imagens com dois layers (memória + disco) que baixa automaticamente todas as imagens dos exercícios de um treino em background.

**Por que é importante:**
- ExerciseDB é API externa, sujeita a latência e falhas
- Usuários treinam em locais com WiFi instável (academias)
- Download repetido das mesmas imagens desperdiça dados e tempo

**Como funciona:**

1. **Ao gerar treino**: Identifica todas URLs de imagens dos exercícios
2. **Prefetch em background**: Download paralelo (máx 5 concurrent) enquanto usuário lê treino
3. **Progress indicator**: "Preparando treino..." durante primeiros 5-10s
4. **Cache persistente**: Imagens sobrevivem a app kill, disponíveis offline
5. **Fallback inteligente**: Placeholder com ícone do músculo (SF Symbols) se imagem não disponível

**Requisitos funcionais:**

1. `ImageCacheService` deve implementar protocol `ImageCaching`
2. Cache híbrido: URLCache (memória 50MB) + custom disk cache (500MB)
3. Método `prefetchImages(_ urls: [URL])` com concurrency controlada
4. Método `cachedImage(for url: URL)` retorna em < 50ms se hit
5. Método `clearCache()` para Settings (permitir usuário liberar espaço)
6. Thread-safe usando async/await e actors se necessário
7. Registrado no DI container (Swinject) como singleton
8. Configurável via `ImageCacheConfiguration` struct

### F2. Enhanced Error Handling (Fase 1)

**O que faz:**
Infraestrutura padronizada para apresentação de erros com protocolo `ErrorPresenting`, mapeamento de erros técnicos para mensagens user-friendly e componente UI `ErrorToastView`.

**Por que é importante:**
- Erros técnicos confundem usuários ("URLError -1009")
- Inconsistência no tratamento entre ViewModels
- Falta de ações de recuperação claras

**Como funciona:**

1. **ViewModel detecta erro**: Try-catch em operações assíncronas
2. **handleError() chamado**: Implementação do protocol ErrorPresenting
3. **Mapeamento**: ErrorMapper traduz DomainError para ErrorMessage
4. **UI atualizada**: @Published errorMessage aciona toast ou alert
5. **Ação opcional**: Retry, abrir Settings, ou dismiss

**Requisitos funcionais:**

1. Protocol `ErrorPresenting` com default implementation
2. `ErrorMessage` model: title, message, action (Identifiable)
3. `ErrorMapper` mapeia todos cases de `DomainError`
4. `ErrorToastView` SwiftUI component com animação suave
5. Enum `ErrorAction`: retry(closure), openSettings, dismiss
6. Mensagens em português brasileiro coloquial
7. Sem termos técnicos expostos ao usuário
8. Logging técnico em console mantido para debugging

**Cenários cobertos:**
- Network timeout → "Sem conexão. Verifique sua internet."
- API failure → "Serviço temporariamente indisponível. Tente novamente."
- Subscription invalid → "Assinatura expirada. Renove para continuar."
- OpenAI fallback → "Geramos um ótimo treino local para você hoje."

### F3. SwiftData Query Optimization (Fase 1)

**O que faz:**
Otimização de queries SwiftData com índices em campos frequentemente consultados e paginação lazy na tela de histórico.

**Por que é importante:**
- Histórico cresce ilimitadamente (potencial 365+ treinos/ano)
- Queries sem índice são O(n), ficam lentas com mais dados
- Carregar todo histórico de uma vez bloqueia UI

**Como funciona:**

1. **Índices**: Adicionar @Attribute(.indexed) em `completedAt` e `status`
2. **Repository atualizado**: Métodos `fetchHistory(limit:offset:)` e `fetchHistoryCount()`
3. **HistoryView refatorada**: Lazy loading com scroll infinito
4. **Background fetch**: Queries rodam em background ModelContext

**Requisitos funcionais:**

1. Adicionar índices em `SDWorkoutHistoryEntry`: `completedAt`, `status`
2. Método `fetchHistory(limit: Int, offset: Int)` no repository
3. Método `fetchHistoryCount()` para paginação
4. HistoryView com LazyVStack e onAppear trigger
5. Performance target: < 100ms para carregar 20 itens
6. Indicador de loading no final da lista
7. Migration path testado para índices novos

### F4. Progressive Onboarding (Fase 2)

**O que faz:**
Onboarding em etapas que permite usuário treinar após responder apenas 2-3 perguntas críticas, coletando dados opcionais progressivamente.

**Por que é importante:**
- 6 perguntas upfront aumenta abandono
- Usuários querem ver valor antes de investir tempo
- Defaults inteligentes permitem quick start

**Requisitos funcionais:**

1. Tela 1: Objetivo (obrigatório) → hypertrophy, weightLoss, conditioning, etc
2. Tela 2: Estrutura disponível (obrigatório) → fullGym, home, bodyweight
3. CTA: "Gerar meu primeiro treino" → usa defaults para resto
4. Defaults: level = intermediate, method = mixed, frequency = 3x/week
5. Após primeiro treino: prompt "Personalize seu perfil" (opcional)
6. Profile edit disponível em Settings sempre

### F5. Workout Timer & Progress Tracking (Fase 2)

**O que faz:**
Timer de descanso entre séries, checkboxes para marcar séries completas e botão de substituição de exercício.

**Por que é importante:**
- Usuários usam outro app para timing/tracking em paralelo
- Difícil saber onde parou no treino
- Não tem alternativa se exercício não for possível

**Requisitos funcionais:**

1. Timer de descanso configurável (default: sugestão do treino)
2. Haptic feedback ao completar série
3. Checkbox visual em cada série
4. Progress bar geral do treino (ex: 5/10 exercícios)
5. Botão "Não consigo fazer" → sugere alternativa com mesmo músculo
6. Persistência de progresso (sobrevive app kill)

### F6. Optimized Paywall (Fase 2)

**O que faz:**
Paywall otimizado com 3 variantes testáveis (A/B test ready), trial de 7 dias e soft paywall persuasivo.

**Por que é importante:**
- Conversão Free → Pro é métrica crítica de receita
- Paywall atual é genérico (sem otimização)
- Falta trial para reduzir fricção

**Requisitos funcionais:**

1. 3 variantes de layout (AppStorage flag para controle)
2. Trial 7 dias Pro grátis (StoreKit subscription)
3. Feature comparison visual (tabela Free vs Pro)
4. Soft paywall: permite 1-2 treinos IA/semana Free
5. Mensagens persuasivas sem bloqueio agressivo
6. "Já é PRO? Restaurar compra" link visível

### F7. Workout Composition Caching (Fase 3)

**O que faz:**
Cache inteligente de workouts gerados pela IA por 24h, reutilizando se usuário regenera com mesmos inputs.

**Por que é importante:**
- Cada geração custa $ (OpenAI API)
- Usuários às vezes regeneram por indecisão (mesmos inputs)
- 30% das chamadas são potencialmente redundantes

**Requisitos funcionais:**

1. Hash de inputs: profile + checkIn → chave única
2. Cache em SwiftData: `SDCachedWorkout` com expiração
3. TTL de 24h (workouts antigos expiram)
4. Método `getCachedWorkout(for hash:)` no repository
5. Fallback transparente para geração nova se cache miss
6. Settings toggle para desabilitar cache (debug)

### F8. Test Coverage (Fase 3)

**O que faz:**
Aumentar cobertura de testes unitários para targets específicos por camada da arquitetura.

**Por que é importante:**
- Refactorings sem testes causam regressões
- CI/CD confiável requer testes
- Domain layer crítico precisa > 80% coverage

**Requisitos funcionais:**

1. Domain layer: 80%+ coverage (business logic crítica)
2. ViewModels: 70%+ coverage (fluxos principais)
3. Repositories: 60%+ coverage (integrações)
4. Mocks para: OpenAIClient, ExerciseDBService, StoreKitRepository
5. Critical paths testados: workout generation, subscription flow, soreness filtering
6. Async tests com XCTest quando possível
7. CI job falha se coverage < targets

## Experiência do Usuário

### Personas

**Persona 1: João, 28 anos - Usuário Iniciante Free**
- Objetivo: Perder peso, treinar 3x/semana
- Contexto: Treina em academia com WiFi instável
- Frustração: Imagens de exercícios não carregam, fica perdido
- Necessidade: Referência visual confiável, offline support

**Persona 2: Maria, 35 anos - Usuária Pro Avançada**
- Objetivo: Hipertrofia, treina 5x/semana
- Contexto: Paga R$ 19,90/mês pela personalização com IA
- Frustração: Não sabe quando IA está realmente personalizando
- Necessidade: Feedback claro de qualidade do treino, transparência

**Persona 3: Pedro, 22 anos - Novo Usuário Curioso**
- Objetivo: Testar app antes de comprometer
- Contexto: Baixou 5 apps de treino, vê qual prefere
- Frustração: Onboarding longo afasta antes de ver valor
- Necessidade: Quick start, experimentar antes de preencher perfil completo

### Fluxos Principais

**Fluxo 1: Geração e uso de treino offline**

1. **Usuário abre app** → HomeView
2. **Responde questionário diário** → DailyQuestionnaireFlowView (2 perguntas)
3. **Gera treino** → Loading com "Preparando seu treino..."
4. **Background prefetch** → ImageCacheService baixa 10 imagens paralelamente
5. **Treino disponível** → WorkoutPlanView com todas imagens cacheadas
6. **Usuário vai para academia** (perde WiFi) → Treino funciona 100% offline
7. **Abre próximo exercício** → Imagem carrega instantaneamente (< 50ms)

**Pontos de fricção eliminados:**
- ❌ Imagens travando no carregamento
- ❌ Erro genérico "Failed to load"
- ❌ Placeholder feio ou nada aparecer

**Fluxo 2: Erro de rede com recuperação**

1. **Usuário tenta gerar treino** sem internet
2. **Erro capturado** no ViewModel
3. **ErrorMapper traduz** → "Sem conexão. Verifique sua internet e tente novamente."
4. **ErrorToastView aparece** com animação suave (slide from top)
5. **Action button: "Tentar Novamente"** visível
6. **Usuário conecta WiFi** → toca "Tentar Novamente"
7. **Geração funciona** → ErrorToast desaparece automaticamente

**Pontos de fricção eliminados:**
- ❌ "URLError domain:-1009"
- ❌ Alert assustador sem ação clara
- ❌ Usuário não sabe o que fazer

**Fluxo 3: Onboarding progressivo (Fase 2)**

1. **Usuário abre app** primeira vez → Splash
2. **Tela 1: Proposta de valor** → "Treinos personalizados todo dia"
3. **Tela 2: Objetivo** → Cards grandes (Hipertrofia, Emagrecimento, Condicionamento)
4. **Tela 3: Estrutura** → fullGym, Home, Bodyweight
5. **CTA Grande: "Gerar meu primeiro treino"** (usa defaults)
6. **Treino gerado** em 5s → Usuário vê valor imediatamente
7. **Após completar treino** → Toast: "Personalize seu perfil para treinos ainda melhores" (opcional)

**Pontos de fricção eliminados:**
- ❌ 6 perguntas obrigatórias upfront
- ❌ Stepper intimidante (1/6, 2/6...)
- ❌ Abandono antes de ver primeiro treino

### Considerações de UI/UX

**Design de Error Toasts:**
- Posição: Top da tela (não bloqueia conteúdo)
- Animação: Slide in (200ms) com spring
- Duração: 4s auto-dismiss (ou manual dismiss)
- Cores: Vermelho suave (não agressivo)
- Ícone: SF Symbol relevante (wifi.slash para network, exclamationmark.triangle para erro genérico)
- Ação: Button destacado com cor primária do app

**Design de Loading States:**
- Prefetch de imagens: ProgressView com texto "Preparando treino..." (não bloquear usuário)
- Lazy loading de histórico: Spinner pequeno no final da lista
- Geração de treino: Skeleton screens dos exercícios (não tela branca)

### Requisitos de Acessibilidade

1. **VoiceOver**: Todas as ErrorMessage devem ser anunciadas automaticamente
2. **Dynamic Type**: ErrorToastView suporta tamanhos de fonte aumentados
3. **High Contrast**: Error colors mantêm contraste mínimo 4.5:1
4. **Reduced Motion**: Animações de toast respeitam preferência (fade simples)
5. **Keyboard Navigation**: Actions em toasts acessíveis via teclado externo

## Restrições Técnicas de Alto Nível

### Plataforma e Compatibilidade
- **iOS 17+** (SwiftUI, SwiftData, Swift 5.9+)
- **iPhone only** no MVP (iPad support futuro)
- **Dark mode** obrigatório (tema atual do app)

### Performance e Escalabilidade

**Image Caching:**
- Limite disco: 500MB (configurável)
- Limite memória: 50MB URLCache
- Prefetch: máx 5 downloads simultâneos
- Target: < 50ms para cache hit, < 15s para prefetch completo de treino

**SwiftData Queries:**
- Target: < 100ms para carregar 20 itens de histórico
- Índices em: `completedAt`, `status`
- Background thread para queries pesadas
- Paginação: 20 itens por página

### Segurança e Privacidade
- **Keychain**: Chaves de API (OpenAI, ExerciseDB) nunca em código
- **Cache de imagens**: Apenas imagens públicas da ExerciseDB (não dados sensíveis)
- **Logs**: Erros técnicos em console (desenvolvimento), não enviar para servidor no MVP

### Integrações Externas

**ExerciseDB API:**
- Rate limit: Respeitar limites da RapidAPI
- Timeout: 10s por imagem
- Retry: 2 tentativas com exponential backoff
- Fallback: Placeholder se todas tentativas falharem

**OpenAI API:**
- Timeout: 20s para geração de treino
- Fallback: Local composer se timeout ou API error
- User feedback: Indicar quando fallback usado

**StoreKit 2:**
- Subscription validation: Checar ao abrir app
- Restore purchases: Botão visível em Paywall e Settings
- Graceful degradation: Free features sempre funcionam

### Mandatos Técnicos

1. **Architecture**: Manter Clean Architecture (Domain/Data/Presentation)
2. **DI**: Usar Swinject para todas dependências
3. **Async**: Usar async/await (não Combine) para novas APIs
4. **Testing**: XCTest framework, mocks para serviços externos
5. **Code Style**: Seguir Kodeco Swift Style Guide (2 spaces, protocol-oriented)

## Não-Objetivos (Fora de Escopo)

### Fase 1 NÃO inclui:

- ❌ **Video caching**: Apenas images (GIF/JPG). Videos são muito pesados e não estão na ExerciseDB atual
- ❌ **Apple Watch integration**: Requer Watch app target, WatchConnectivity framework
- ❌ **Social/community features**: Requer backend, autenticação de usuários
- ❌ **Refactoring de arquitetura**: Arquitetura atual está boa, apenas adicionar features
- ❌ **Chat com IA durante treino**: Complexidade alta, custo elevado, valor incerto
- ❌ **Analytics detalhados**: Apenas logging básico. Amplitude/Mixpanel em fase futura
- ❌ **Push notifications**: Requer backend, permissões, estratégia de engagement

### Futuro (não deste PRD):

- Backend próprio (ainda usa OpenAI diretamente)
- Sincronização multi-device (iCloud ou backend)
- Export de treinos (PDF, compartilhar)
- Integração com Apple Health (HealthKit)
- Planos de treino de longo prazo (periodização)

### Limitações Aceitáveis:

1. **Cache não é inteligente**: Não prevê quais exercícios usuário fará amanhã (apenas cacheia treino atual)
2. **Sem CDN próprio**: Dependemos da ExerciseDB API para source images
3. **Error tracking básico**: Console logs apenas, sem Crashlytics/Sentry nesta fase
4. **A/B testing manual**: Flags no AppStorage, sem plataforma de experimentation
5. **Offline AI generation**: Não possível. IA requer conexão sempre.

## Questões em Aberto

### 1. Image Caching Strategy

**Questão**: Implementar apenas URLCache ou custom disk cache também?

**Resposta decidida**: Custom cache híbrido (URLCache + Disk)

**Justificativa**:
- URLCache sozinha não persiste entre app kills
- Custom disk dá controle total sobre eviction policy
- Híbrido: melhor performance (memória) + persistência (disco)

**Decisão final**: Implementar `DiskImageCache` + usar URLCache do sistema

---

### 2. Error Tracking Service

**Questão**: Integrar Crashlytics/Sentry nesta fase ou apenas console logs?

**Decisão pendente**: TechSpec vai decidir

**Opções**:
- A) Apenas console logs (simples, sem setup)
- B) Crashlytics (Firebase dependency, analytics grátis)
- C) Sentry (open source, self-hosted option)

**Critério de decisão**: Se setup < 2h, vale a pena. Senão deixar para Fase 3.

---

### 3. Onboarding A/B Test Tracking

**Questão**: Como trackear qual variante de onboarding/paywall funciona melhor?

**Resposta para Fase 2**: AppStorage flag + logging manual

**Implementação**:
```swift
@AppStorage("onboardingVariant") var variant: String = "progressive" // ou "full"
// Log conversions manualmente em Analytics (fase futura)
```

**Plataforma futura**: Considerar Firebase Remote Config ou LaunchDarkly

---

### 4. Cache Eviction Policy

**Questão**: FIFO, LRU, ou LFU para evict quando cache cheio?

**Resposta**: LRU (Least Recently Used)

**Justificativa**:
- Usuários tendem a repetir exercícios semana a semana
- Exercícios recentes têm maior chance de serem usados novamente
- Implementação simples com timestamp de último acesso

---

### 5. Prefetch em Dados Móveis

**Questão**: Prefetch automático em cellular ou apenas WiFi?

**Resposta**: Apenas WiFi por default, com toggle em Settings

**Implementação**:
```swift
@AppStorage("prefetchOnCellular") var allowCellular = false
if Network.isWiFi || allowCellular {
  await imageCacheService.prefetchImages(urls)
}
```

**Settings toggle**: "Baixar imagens em dados móveis" (OFF por padrão)

