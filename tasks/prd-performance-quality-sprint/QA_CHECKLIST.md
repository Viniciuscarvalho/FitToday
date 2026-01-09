# QA Checklist — Workout Composition & Caching

## Cobertura Mínima por Componente

| Componente | Target | Status |
|------------|--------|--------|
| `WorkoutBlueprintEngine` | 80%+ | ✅ |
| `WorkoutPromptAssembler` | 75%+ | ✅ |
| `WorkoutPlanQualityGate` | 75%+ | ✅ |
| `WorkoutCompositionCacheRepository` | 80%+ | ✅ |
| `BlueprintDiversityChecker` | 70%+ | ✅ |
| `OpenAIResponseValidator` | 75%+ | ✅ |

## Testes Unitários Obrigatórios

### Blueprint Engine
- [x] Determinismo: mesmos inputs → mesmo blueprint
- [x] Diferenciação: inputs diferentes → blueprints diferentes
- [x] Objetivo Hipertrofia: RPE alto, descanso longo, reps baixas
- [x] Objetivo Emagrecimento: circuitos, descanso curto, aeróbico
- [x] Objetivo Endurance: reps altas, aeróbico zona 2
- [x] Estrutura Bodyweight: apenas peso corporal permitido
- [x] Estrutura FullGym: todos equipamentos permitidos
- [x] DOMS alto: recovery mode, intensidade baixa
- [x] Níveis: beginner < intermediate < advanced em volume
- [x] Versão atual no blueprint

### Prompt Assembly
- [x] Determinismo: mesmos inputs → mesmo prompt/cacheKey
- [x] Conteúdo do blueprint no prompt
- [x] Constraints de equipamento no prompt
- [x] Perfil do usuário no prompt
- [x] Instruções anti-repetição no prompt
- [x] Metadata correta

### Quality Gate
- [x] Plano válido passa
- [x] Plano com valores fora do range é normalizado
- [x] Plano com equipamento incompatível falha
- [x] Normalizer ajusta sets/reps/descanso
- [x] Normalizer reordena fases
- [x] Diversidade: primeiro plano sempre passa
- [x] Diversidade: planos idênticos falham
- [x] Diversidade: planos diferentes passam
- [x] Feedback gerado para falhas

### Cache Repository
- [x] Hash estável para mesmos inputs
- [x] Hash diferente para inputs diferentes
- [x] Seed de variação determinística
- [x] Cache miss retorna nil
- [x] Cache hit retorna entry
- [x] Save atualiza entry existente
- [x] Cache válido não expira
- [x] Cache expirado retorna nil
- [x] TTL padrão é 24h
- [x] Cleanup remove apenas expirados
- [x] Clear all remove tudo
- [x] Stats retorna contagens corretas
- [x] Toggle DEBUG desabilita cache
- [x] Metadata preservada no cache

### Response Validation
- [x] JSON válido parseia corretamente
- [x] JSON inválido lança erro
- [x] Fases vazias lança erro
- [x] Extração de JSON de markdown
- [x] Extração de JSON puro

## Smoke Tests (Integração)

### Fluxo Completo
- [x] Hipertrofia + FullGym: blueprint → prompt → validate → cache
- [x] Emagrecimento + Bodyweight: blueprint → prompt → validate → cache
- [x] Recovery Mode: DOMS alto → intensidade baixa
- [x] Determinismo em todos os objetivos
- [x] Diversidade entre objetivos diferentes
- [x] Diversidade entre focos diferentes
- [x] Cache hit evita regeneração
- [x] Versão diferente no cache não retorna hit

## Checklist de QA Manual (Device)

### Pré-requisitos
- [ ] App instalado em device/simulador
- [ ] Perfil configurado com objetivo específico
- [ ] Sem treinos no histórico (para testar primeiro treino)

### Cenários de Teste

#### 1. Primeiro Treino do Dia
1. Abrir app → Home
2. Iniciar questionário diário
3. Selecionar foco (ex: Upper)
4. Selecionar nível de dor (ex: Nenhum)
5. Gerar treino
6. **Verificar:** Treino gerado em < 10s
7. **Verificar:** Treino corresponde ao objetivo do perfil
8. **Verificar:** Exercícios usam equipamento correto

#### 2. Regenerar com Mesmos Inputs
1. Completar cenário 1
2. Voltar à Home (sem completar treino)
3. Refazer questionário com MESMOS inputs
4. **Verificar:** Treino gerado MUITO mais rápido (cache hit)
5. **Verificar:** Treino é IDÊNTICO ao anterior

#### 3. Regenerar com Inputs Diferentes
1. Completar cenário 1
2. Refazer questionário com inputs DIFERENTES
3. **Verificar:** Novo treino gerado
4. **Verificar:** Treino é DIFERENTE do anterior
5. **Verificar:** Treino respeita novos inputs

#### 4. Recovery Mode (DOMS Alto)
1. No questionário, selecionar "Dor Forte"
2. Marcar áreas com dor
3. Gerar treino
4. **Verificar:** Treino indica "Recuperação" ou intensidade baixa
5. **Verificar:** Menos séries/exercícios que normal
6. **Verificar:** Descanso maior entre séries

#### 5. Mudança de Objetivo no Perfil
1. Gerar treino com objetivo atual
2. Ir em Perfil → Editar Objetivo
3. Mudar objetivo (ex: Hipertrofia → Emagrecimento)
4. Gerar novo treino
5. **Verificar:** Treino reflete novo objetivo
6. **Verificar:** Estrutura diferente (circuitos vs força)

#### 6. Cache Expiration (24h)
1. Gerar treino e anotar hora
2. Esperar 24h+ (ou ajustar relógio do device)
3. Refazer questionário com mesmos inputs
4. **Verificar:** Novo treino gerado (não do cache)
5. **Verificar:** Pode ser diferente do anterior (diversidade)

#### 7. Offline Mode
1. Desabilitar conexão (modo avião)
2. Tentar gerar treino
3. **Verificar:** Fallback local funciona
4. **Verificar:** Treino gerado sem rede

### Métricas de Sucesso

| Métrica | Target | Método |
|---------|--------|--------|
| Tempo de geração (cache miss) | < 10s | Cronômetro |
| Tempo de geração (cache hit) | < 1s | Cronômetro |
| Taxa de cache hit | > 30% | Logs DEBUG |
| Diversidade entre sessões | > 50% exercícios diferentes | Comparação manual |
| Aderência ao objetivo | 100% | Verificação manual |

## Critérios de Aprovação

### Bloqueadores (Must Fix)
- Treino não gerado em 30s
- Crash durante geração
- Equipamento incompatível no treino
- Cache retornando treino expirado
- Treinos idênticos em dias consecutivos

### Não-Bloqueadores (Should Fix)
- Cache miss inesperado
- Treino com menos exercícios que esperado
- Feedback de diversidade não exibido

---

**Última atualização:** 09/01/2026
**Responsável:** AI Assistant
