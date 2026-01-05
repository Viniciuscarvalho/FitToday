# PRD — FitToday (MVP)

## Visão Geral

O FitToday é um app iOS focado em reduzir fricção: **“Todo dia, dois cliques → um treino possível, seguro e alinhado ao objetivo.”**  
No MVP, o usuário não precisa “pensar” nem escrever texto livre. Ele configura um perfil uma única vez e, diariamente, responde 2 perguntas para receber um treino montado a partir de **blocos pré-curados** (sem “inventar exercícios”).

O produto separa claramente **Free vs Pro**:
- Free: biblioteca de treinos fixos por objetivo/estrutura (sem adaptação diária).
- Pro: questionário diário + treino adaptado + histórico básico + IA ativa (no MVP, arquitetura preparada; entrega pode iniciar com combinação local e evoluir para OpenAI).

## Objetivos

- **Reduzir fricção**: usuário concluir onboarding e gerar um treino diário em < 10s.
- **Entregar treinos seguros e consistentes**: treinos baseados em blocos curados; sem geração “do zero”.
- **Validar loop de engajamento**: abrir app → responder 2 perguntas → treinar → concluir → repetir amanhã.
- **Monetização inicial**: paywall após “Gerar treino” e assinatura **Pro via StoreKit 2**.

Métricas (MVP):
- % usuários que completam onboarding
- % que respondem questionário diário
- Retenção D3 / D7
- Conversão Free → Pro (paywall → assinatura)

## Histórias de Usuário

- Como **novo usuário**, quero configurar meu perfil em poucos passos para receber treinos alinhados ao meu objetivo.
- Como **usuário recorrente**, quero responder 2 perguntas rápidas e ver o treino do dia para treinar sem perder tempo.
- Como **usuário Free**, quero uma biblioteca de treinos básicos para começar sem pagar.
- Como **usuário Free**, quero entender claramente o valor do Pro e poder assinar e restaurar compras.
- Como **usuário Pro**, quero treinos adaptados à minha escolha de foco e respeitando minha dor muscular do dia.

Casos extremos:
- Usuário com **dor forte**: treino deve reduzir volume/intensidade ou sugerir alternativa segura.
- Usuário sem equipamento (peso corporal): treino deve respeitar estrutura/equipamento selecionados.
- Usuário offline: acesso a biblioteca Free e histórico; geração do treino Pro deve ter fallback seguro (blocos locais).

## Funcionalidades Principais

### 1) Onboarding (3 telas) + Setup inicial (questionário 1 vez)

- O que faz: apresenta proposta de valor, explica “como funciona”, e conduz questionário inicial (1 pergunta por tela, stepper).
- Por que é importante: estabelece objetivo, nível, estrutura e restrições para treinos seguros.
- Como funciona: fluxo linear, sem login, salva `UserProfile` localmente.

Requisitos funcionais:
1.1 Exibir 3 telas de onboarding (valor, como funciona, Free vs Pro).
1.2 Questionário inicial estruturado (sem texto livre), com 6 passos:
  - objetivo, estrutura, metodologia, nível, condições de saúde (multi-select), frequência semanal.
1.3 Ao finalizar, salvar `UserProfile` localmente e levar para Home.

### 2) Home — “Treino de Hoje”

- O que faz: tela principal com saudação, data e card “Treino de Hoje”.
- Como funciona: CTA muda conforme estado (sem perfil / não respondeu hoje / treino disponível).

Requisitos funcionais:
2.1 Se não há perfil, CTA direciona para setup.
2.2 Se há perfil, CTA “Responder perguntas” (ou “Ver treino” se já respondeu).
2.3 Acesso rápido a Biblioteca, Histórico e área Pro.

### 3) Questionário Diário (2 perguntas)

- O que faz: captura intenção de treino do dia e dor muscular.
- Como funciona: 2 telas (cards para foco; slider/escala para dor). Deve levar < 10s.

Requisitos funcionais:
3.1 Pergunta 1: foco (corpo inteiro/superior/inferior/cardio/core/surpreenda-me).
3.2 Pergunta 2: dor (nenhuma/leve/moderada/forte; opcionalmente escala 1–10 e seleção de região se alta).
3.3 Ao confirmar “Gerar treino”:
  - Se Free: exibir paywall (Pro).
  - Se Pro: gerar treino.

### 4) Motor de Treino (blocos pré-curados + combinação)

- O que faz: monta treino do dia usando blocos validados.
- Como funciona: seleciona blocos compatíveis com perfil + foco + dor, define ordem/volume/descanso e gera saída consistente.

Requisitos funcionais:
4.1 Treino deve usar apenas exercícios/blocos existentes (sem inventar).
4.2 Ajustar volume e intensidade conforme dor.
4.3 Output mínimo por exercício: nome, séries x reps, descanso, dica curta, imagem estática (MVP).

### 5) Tela do Treino + Execução

- O que faz: apresenta treino e permite navegar pelos exercícios (próximo/pular).
- Como funciona: lista do treino + tela de detalhe do exercício + fluxo de conclusão.

Requisitos funcionais:
5.1 Tela “Treino gerado” com header (nome/duração/intensidade) e lista de exercícios.
5.2 Detalhe do exercício com imagem/descrição/dica e botões “Próximo/Pular”.
5.3 Conclusão do treino com resumo e retorno à Home.

### 6) Histórico (simples)

- O que faz: lista por dia (tipo/status concluído/pulado).
- Como funciona: registra sessão diária ao concluir/pular.

Requisitos funcionais:
6.1 Lista vertical por data.
6.2 Status: concluído/pulado.
6.3 Sem gráficos e métricas avançadas no MVP.

### 7) Biblioteca Free

- O que faz: treinos fixos por objetivo/estrutura.
- Como funciona: catálogo local (blocos/treinos) navegável e “iniciar treino”.

Requisitos funcionais:
7.1 Listar treinos básicos por objetivo e estrutura.
7.2 Iniciar um treino fixo (sem adaptação diária).

### 8) Pro (StoreKit 2)

- O que faz: assinatura Pro, restauração e habilitação de features.
- Como funciona: paywall após tentativa de gerar treino; compra e restore via StoreKit 2; entitlements persistidos.

Requisitos funcionais:
8.1 Paywall com proposta clara e CTA para assinar.
8.2 Fluxo de compra e restore.
8.3 App deve reagir a mudanças de entitlement (expiração/cancelamento).

## Experiência do Usuário

- Navegação principal por **TabBar** com seções:
  - Home
  - Biblioteca
  - Histórico
  - Perfil/Pro
- **Navegação independente por tab** (cada tab mantém seu próprio stack).
- Onboarding curto (máx. 3 telas) e questionário inicial com stepper e cards.
- Questionário diário com cards grandes e CTA único.
- Acessibilidade:
  - Touch targets ≥ 44pt
  - Bom contraste (light/dark)
  - Suporte a Dynamic Type (quando viável)

## Restrições Técnicas de Alto Nível

- iOS com SwiftUI e persistência local (SwiftData).
- **Arquitetura em camadas**: Domain / Data / Presentation (sem módulos separados; organização por diretórios e limites de dependência).
- **DI com Swinject** (injeção via container/assemblies).
- **Router + DeepLinks** para navegação.
- **TabBar com stacks independentes**.
- Sem login no MVP.
- Geração de treino deve ser determinística/segura usando blocos curados; IA (OpenAI) deve ser opcional e controlada por prompt/validação.

## Não-Objetivos (Fora de Escopo)

- Comunidade/social
- Apple Watch / wearables
- Chat aberto com IA
- Periodização avançada (mesociclos)
- Timer complexo / tracking automático
- Métricas e analytics avançadas

## Questões em Aberto

- Quais produtos e preços do Pro (mensal/anual, trials)?
- Qual comportamento exato para “dor forte”: reduzir volume vs sugerir descanso vs trocar grupo?
- Imagens dos exercícios: fonte (assets do app, kit, placeholders)?
- O motor de treino no MVP começa 100% local ou já integra OpenAI com fallback local?



