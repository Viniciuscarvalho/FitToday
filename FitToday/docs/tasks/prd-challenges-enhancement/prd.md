# PRD: Challenges Enhancement - FitToday

**Versão:** 1.0
**Data:** 2026-01-25
**Status:** Draft
**Autor:** Product Team

---

## 1. Visão Geral

### 1.1 Problema
O FitToday apresenta baixo engajamento recorrente, competição limitada entre usuários e dificuldade em reter usuários no longo prazo. A área de desafios atual possui funcionalidade básica mas não gera motivação social suficiente para manter os usuários ativos.

### 1.2 Solução
Aprimorar a área de desafios com check-in obrigatório com foto pós-treino, feed de atividades do grupo, e celebrações visuais que aumentem o senso de comunidade e competição saudável.

### 1.3 Objetivos Mensuráveis
- **O1:** Aumentar DAU (Daily Active Users) em 25% em 90 dias
- **O2:** Aumentar taxa de conclusão de treinos semanais em 30%
- **O3:** Reduzir churn mensal em 15%
- **O4:** Alcançar 60% de adoção da feature entre usuários em grupos

---

## 2. Usuários e Personas

### 2.1 Usuário Principal
**Todos os usuários (Free e Pro)** que participam de grupos de desafios.

### 2.2 User Stories

| ID | Como... | Quero... | Para... |
|----|---------|----------|---------|
| US1 | Participante de grupo | Fazer check-in com foto após meu treino | Provar minha participação e motivar outros |
| US2 | Membro do grupo | Ver o feed de check-ins dos colegas | Me sentir parte da comunidade e motivado |
| US3 | Competidor | Ver minha posição no leaderboard atualizado | Saber como estou em relação aos outros |
| US4 | Usuário consistente | Manter meu streak visível | Ter orgulho da minha consistência |
| US5 | Vencedor da semana | Receber celebração visual ao liderar | Sentir reconhecimento pelo esforço |

---

## 3. Requisitos Funcionais

### 3.1 Check-in com Foto (Core)

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF01 | Sistema DEVE exigir foto para validar check-in no desafio | P0 |
| RF02 | Sistema DEVE permitir foto da câmera ou galeria | P0 |
| RF03 | Sistema DEVE comprimir imagens para max 1MB | P0 |
| RF04 | Sistema DEVE armazenar fotos no Firebase Storage | P0 |
| RF05 | Sistema DEVE vincular check-in ao treino completado | P0 |
| RF06 | Sistema DEVE validar mínimo 30 minutos de treino para check-in contar | P0 |

### 3.2 Feed de Atividades

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF07 | Sistema DEVE exibir feed cronológico de check-ins do grupo | P0 |
| RF08 | Sistema DEVE mostrar foto, nome, data/hora em cada item | P0 |
| RF09 | Sistema DEVE atualizar feed em tempo real | P1 |
| RF10 | Sistema DEVE permitir scroll infinito com paginação | P1 |

### 3.3 Leaderboard Melhorado

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF11 | Sistema DEVE suportar desafio tipo "Check-ins Semanais" | P0 |
| RF12 | Sistema DEVE suportar desafio tipo "Streak" (dias consecutivos) | P0 |
| RF13 | Sistema DEVE exibir tabs para alternar entre tipos de desafio | P0 |
| RF14 | Sistema DEVE destacar top 3 com badges visuais | P0 |
| RF15 | Sistema DEVE mostrar posição atual do usuário sempre visível | P1 |

### 3.4 Celebrações Visuais

| ID | Requisito | Prioridade |
|----|-----------|------------|
| RF16 | Sistema DEVE exibir animação de confetti ao subir para top 3 | P1 |
| RF17 | Sistema DEVE exibir celebração ao completar check-in | P1 |
| RF18 | Sistema DEVE notificar usuário quando ultrapassado no ranking | P2 |

---

## 4. Requisitos Não-Funcionais

| ID | Requisito | Especificação |
|----|-----------|---------------|
| RNF01 | Performance de upload | Foto deve fazer upload em < 3 segundos em 4G |
| RNF02 | Atualização do leaderboard | Máximo 2 segundos de delay |
| RNF03 | Armazenamento | Fotos retidas por 90 dias, depois arquivadas |
| RNF04 | Privacidade | Fotos visíveis apenas para membros do grupo |
| RNF05 | Acessibilidade | VoiceOver para todos os elementos do feed |

---

## 5. Fora do Escopo (v1)

- Chat/mensagens entre membros
- Desafios entre grupos diferentes
- Premiações reais (físicas ou monetárias)
- Integração com redes sociais (Instagram, TikTok)
- Sistema completo de badges/conquistas
- Desafio de "minutos totais"

---

## 6. Dependências

| Dependência | Status | Impacto |
|-------------|--------|---------|
| Firebase Storage configurado | Pendente | Blocker para upload de fotos |
| Conta Firebase com quota suficiente | Verificar | Blocker para produção |
| Apple Health Integration | Implementado | Necessário para validação de 30min |

---

## 7. Métricas de Sucesso

| Métrica | Baseline | Meta | Prazo |
|---------|----------|------|-------|
| Check-ins com foto/semana | 0 | 500+ | 30 dias |
| Usuários ativos em grupos | Atual | +40% | 60 dias |
| Treinos completados/usuário/semana | 2.1 | 3.0 | 90 dias |
| NPS de usuários em grupos | N/A | > 50 | 90 dias |

---

## 8. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Abuso de fotos fake | Média | Médio | Moderação por denúncia + revisão manual |
| Custo de storage elevado | Baixa | Alto | Compressão agressiva + cleanup automático |
| Baixa adoção | Média | Alto | Onboarding guiado + incentivos iniciais |

---

## 9. Fluxo Principal

```
1. Usuário completa treino (≥30 min)
2. App exibe tela de conclusão com botão "Fazer Check-in"
3. Usuário tira/seleciona foto
4. App faz upload e valida
5. Check-in registrado no desafio
6. Feed do grupo atualizado em tempo real
7. Leaderboard recalculado
8. Celebração visual se subiu de posição
```

---

## 10. Open Questions

1. **Moderação:** Quem revisa denúncias de fotos inadequadas?
2. **Limite de storage:** Qual budget mensal para Firebase Storage?
3. **Onboarding:** Criar tutorial interativo ou tooltip simples?
4. **Notificações:** Push notification para cada check-in do grupo ou apenas resumo diário?
