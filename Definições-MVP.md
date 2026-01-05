🧠 Visão do MVP (1ª versão)

“Todo dia, dois cliques → um treino possível, seguro e alinhado ao seu objetivo.”

⸻

🎯 Proposta de Valor (MVP)
	•	Treinos adaptados diariamente sem fricção
	•	Usuário não precisa “pensar” → só responder
	•	IA não inventa: ela combina blocos validados
	•	Gratuito resolve o básico
	•	Pro resolve o “o que fazer hoje”

⸻

🧩 Escopo do MVP (o que entra e o que fica fora)

✅ ENTRA no MVP
	•	Questionário inicial
	•	Questionário diário (2 perguntas)
	•	Treino gerado (texto + imagens)
	•	Área Free vs Pro
	•	Histórico simples
	•	Arquitetura pronta para escalar

❌ FICA FORA (por enquanto)
	•	Comunidade / social
	•	Wearables (Apple Watch)
	•	Chat aberto com IA
	•	Periodização avançada (mesociclos)
	•	Personal humano

⸻

🧱 Estrutura do MVP

⸻

1️⃣ Onboarding + Setup Inicial (obrigatório)

Questionário Inicial (1 vez)

Inputs estruturados (não texto livre):
	1.	Objetivo principal
	•	Hipertrofia
	•	Condicionamento
	•	Resistência
	•	Emagrecimento
	•	Performance
	2.	Estrutura disponível
	•	Academia completa
	•	Academia básica
	•	Casa (halteres)
	•	Peso corporal
	3.	Metodologia preferida
	•	Tradicional (séries/reps)
	•	Circuito
	•	HIIT
	•	Misto
	4.	Nível
	•	Iniciante
	•	Intermediário
	•	Avançado
	5.	Condições de saúde
	•	Nenhuma
	•	Dor lombar
	•	Joelho
	•	Ombro
	•	(checkbox múltiplo)
	6.	Frequência semanal
	•	2x / 3x / 4x / 5x+

➡️ Output: UserProfile

⸻

2️⃣ Questionário Diário (core do app)

Duas perguntas fixas (UX ultra rápida)

Pergunta 1 – O que você quer treinar hoje?
	•	Corpo inteiro
	•	Superior
	•	Inferior
	•	Cardio
	•	Core
	•	Surpreenda-me

Pergunta 2 – Como está sua dor muscular hoje?
	•	Nenhuma
	•	Leve
	•	Moderada
	•	Forte

➡️ Tempo de resposta: < 10 segundos

⸻

3️⃣ Motor de Treino (coração do MVP)

⚙️ Estratégia REALISTA (importantíssimo)

NÃO gerar treinos 100% do zero com IA.

👉 Use blocos pré-curados + IA só para:
	•	Seleção
	•	Ordem
	•	Volume
	•	Linguagem

⸻

📦 Banco de Blocos (hardcoded / JSON / DB)

Exemplo de bloco:

```
{
  "id": "upper_push_basic",
  "grupo": "superior",
  "nivel": "iniciante",
  "equipamento": ["halteres", "barra"],
  "exercicios": [
    "Supino reto",
    "Desenvolvimento",
    "Tríceps pulley"
  ]
}
```

🤖 Onde entra a OpenAI

Usar a API da OpenAI somente para:
	•	Combinar blocos
	•	Ajustar reps / séries / descanso
	•	Adaptar linguagem ao usuário
	•	Respeitar dor muscular

Prompt controlado (exemplo):

“Monte um treino usando apenas os blocos fornecidos. Não invente exercícios.”

➡️ Resultado: seguro + barato + consistente

⸻

4️⃣ Entrega do Treino (UI simples)

Tela de treino diário
	•	Título: Treino de Hoje
	•	Duração estimada
	•	Lista de exercícios
	•	Séries x reps
	•	Descanso

Cada exercício contém:
	•	Nome
	•	Imagem estática (MVP)
	•	Dica rápida de execução

📌 Vídeo curto → apenas no PRO (fase 2 ou 3)

⸻

5️⃣ Área Gratuita vs Pro (claríssima)

🆓 Free
	•	Treinos fixos (biblioteca)
	•	Sem adaptação diária
	•	Treinos genéricos por objetivo
	•	Sem histórico avançado

⭐ Pro
	•	Questionário diário
	•	Treino personalizado
	•	Ajuste por dor
	•	Histórico básico
	•	IA ativa

➡️ Paywall após o questionário diário

⸻

6️⃣ Histórico (bem simples)
	•	Lista por dia
	•	Tipo de treino
	•	Status:
	•	Concluído
	•	Pulado

📊 Sem métricas complexas no MVP

⸻

🧪 Validação do MVP

Métricas-chave (MVP)
	•	% usuários que completam onboarding
	•	% que respondem o questionário diário
	•	Retenção D3 / D7
	•	Conversão Free → Pro

⸻

🧠 Diferencial claro vs concorrentes

Freeletics / SmartGym
Seu App
Programas longos
Decisão diária
Treinos fixos
Treino adaptativo
Setup complexo
2 perguntas
Curva alta
Ação imediata

🗺️ Roadmap pós-MVP (teaser)

v1.1
	•	Vídeos
	•	Feedback pós-treino

v1.2
	•	Progressão simples
	•	Sugestão automática (“Hoje melhor fazer X”)

v2.0
	•	Apple Watch
	•	Periodização
	•	Coach IA conversacional

Visão geral do Fluxo (MVP)

Splash
 └─ Onboarding
     └─ Questionário Inicial
         └─ Home (Treino de Hoje)
             ├─ Questionário Diário (2 perguntas)
             │    └─ Treino Gerado
             ├─ Biblioteca (Free)
             ├─ Histórico
             └─ Perfil / Pro

📱 TELAS DO MVP (UX detalhado)

⸻

1️⃣ Splash + Entry Point

Objetivo
	•	Branding rápido
	•	Transição suave

UX
	•	Logo simples
	•	Fundo limpo
	•	1–2s máximo

📌 Sem login no MVP
→ reduz abandono inicial (SmartGym faz isso bem)

⸻

2️⃣ Onboarding (3 telas no máximo)

Tela 1 – Proposta de valor

Headline

“Treinos que se adaptam a você, todos os dias”

Bullets curtos
	•	Baseado no seu objetivo
	•	Ajustado pela sua dor muscular
	•	Sem perder tempo pensando

CTA: Começar

⸻

Tela 2 – Como funciona

Visual em 3 passos (estilo Freeletics):
	1.	Responda 2 perguntas
	2.	Receba o treino
	3.	Treine no seu ritmo

CTA: Continuar

⸻

Tela 3 – Free vs Pro (soft sell)
	•	Coluna Free
	•	Coluna Pro (destacada)

CTA: Configurar meu perfil

⸻

3️⃣ Questionário Inicial (Setup)

UX geral
	•	Stepper (1/6, 2/6…)
	•	Uma pergunta por tela
	•	Opções em cards clicáveis

⸻

Exemplo de tela

Pergunta

Qual é seu objetivo principal?

Cards:
	•	Hipertrofia
	•	Emagrecimento
	•	Condicionamento
	•	Performance
	•	Resistência

📌 Mesmo padrão para:
	•	Estrutura
	•	Metodologia
	•	Nível
	•	Saúde
	•	Frequência

➡️ Última tela:
“Perfil criado 🎉”

CTA: Ir para o treino

⸻

4️⃣ Home – Treino de Hoje (tela principal)

🔥 Tela mais importante do app

Inspiração
	•	Home do Freeletics
	•	Clareza do SmartGym

⸻

Layout

Header
	•	“Bom dia, Vinicius”
	•	Data
	•	Objetivo atual (badge)

⸻

Card Principal (Hero)

Treino de Hoje
⏱ 45 min
🎯 Hipertrofia

CTA primário:
➡️ Responder perguntas

📌 Se já respondeu:
➡️ Ver treino

⸻

Cards secundários
	•	Biblioteca de treinos
	•	Histórico
	•	Upgrade Pro (se free)

⸻

5️⃣ Questionário Diário (core loop)

Tela 1 – O que treinar hoje?

Cards grandes:
	•	Superior
	•	Inferior
	•	Corpo inteiro
	•	Cardio
	•	Surpreenda-me 🎲

➡️ Tap único

⸻

Tela 2 – Dor muscular

Slider de 1 a 10, caso seja 7, abrir um grupo para perguntar qual parte do corpo está doendo, pois isso vai ser determinante para montagem do treino.

➡️ CTA: Gerar treino

⏱ Tempo total: < 10 segundos

⸻

6️⃣ Paywall (somente se Free)

Quando aparece
	•	Após clicar em “Gerar treino”

UX (estilo Freeletics)
	•	Sem agressividade
	•	Valor claro

Headline

“Treino personalizado para você”

Bullets:
	•	Ajuste por dor
	•	IA personalizada
	•	Evolução contínua

CTA:
	•	Assinar Pro
	•	“Ver treinos básicos” (secondary)

⸻

7️⃣ Treino Gerado (Pro)

Layout inspirado no SmartGym

Header
	•	Nome do treino
	•	Duração
	•	Intensidade

⸻

Lista de exercícios
Cada item:
	•	Nome
	•	Séries x reps
	•	Descanso
	•	Thumbnail (imagem)

Tap → detalhe do exercício

⸻

Footer
CTA fixo:
➡️ Iniciar treino

⸻

8️⃣ Execução do Exercício (simples)

MVP
	•	Sem timer complexo
	•	Sem tracking automático

Conteúdo:
	•	Imagem
	•	Descrição curta
	•	Dica de execução

Botões:
	•	Próximo
	•	Pular

📌 Timer → v2.0

⸻

9️⃣ Final do Treino

Tela de conclusão
	•	🎉 “Treino concluído”
	•	Duração
	•	CTA emocional:
“Bom trabalho!”

Botões:
	•	Concluir
	•	Voltar para Home

📌 Feedback → futuro

⸻

🔟 Biblioteca de Treinos (Free)

UX

Lista simples por:
	•	Objetivo
	•	Estrutura

Cada treino:
	•	Nome
	•	Duração
	•	Badge “Básico”

CTA:
➡️ Iniciar treino

📌 Sem adaptação

⸻

1️⃣1️⃣ Histórico

MVP

Lista vertical:
	•	Data
	•	Tipo de treino
	•	Status

Sem gráficos ainda

⸻

1️⃣2️⃣ Perfil / Configurações
	•	Objetivo atual
	•	Frequência
	•	Gerenciar assinatura
	•	Restaurar compra

🔁 Core Loop de Engajamento (UX)

```
Abrir app
 → Home
   → 2 perguntas
     → Treino possível hoje
       → Conclusão
         → Amanhã repetir
```