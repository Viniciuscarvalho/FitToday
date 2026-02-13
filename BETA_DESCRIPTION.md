# FitToday - Beta Testing Description

## 📱 O que é FitToday?

FitToday é um aplicativo inteligente de treino e fitness que combina **IA generativa** com **programação personalizada** para criar experiências de treino únicas e adaptadas ao seu perfil, energia e disposição do dia.

---

## 🎯 Funcionalidades Principais

### 1. **Geração de Treinos com IA (OpenAI)**
- ✅ Cria treinos personalizados automaticamente baseado em:
  - Seu objetivo (hipertrofia, emagrecimento, performance, condicionamento, resistência)
  - Estrutura/equipamento disponível (corpo livre, halteres em casa, academia básica, academia completa)
  - Nível de experiência (iniciante, intermediário, avançado)
  - Foco do dia (superior, inferior, corpo inteiro, cardio, core, surprise)
  - Estado atual (energia, dores musculares, lesões)

- **Validação de Diversidade**: Garante que cada treino seja diferente dos 3 anteriores
- **Fallback Local**: Se a IA não responder, usa geração local como backup

### 2. **Check-in Diário Inteligente**
- Responda 3 perguntas rápidas:
  - Qual é seu foco de hoje?
  - Como está sua energia? (1-10)
  - Tem dores musculares? (nenhuma, leve, moderada, forte)

- O app **adapta automaticamente** a intensidade e volume do treino baseado em suas respostas

### 3. **Execução de Treino com Timer**
- ⏱️ Timer inteligente para:
  - Aquecimento
  - Cada série de exercício
  - Descanso entre séries (com visual de contagem regressiva)
  - Atividades guiadas (mobilidade, aeróbio zona 2, intervalos, respiração)

- 🎮 Controles flutuantes:
  - ▶️ Play/Pause
  - ⏭️ Próximo exercício
  - 🔄 Resetar timer

- 📊 Visualização de progresso em tempo real

### 4. **Histórico de Treinos**
- 📋 Todos os treinos completados com:
  - Título, duração, data e hora
  - Avaliação pessoal (muito ruim, ruim, normal, bom, excelente)
  - Sincronização automática com Apple Health/HealthKit
  - Calorias estimadas

- 📈 Estatísticas:
  - Streak de dias consecutivos
  - Total de treinos por semana/mês
  - Tempo total de treino

### 5. **Treinos Salvos Personalizados**
- 💾 Salve seus treinos favoritos para reutilizar
- ✏️ Edite e customize
- 🔄 Duplique e adapte

### 6. **Programas de Treino Pré-configurados**
- 📚 Programas prontos para:
  - Hipertrofia (4-6 semanas)
  - Emagrecimento (4 semanas)
  - Performance (6 semanas)
  - Condicionamento (4 semanas)

### 7. **Treinos do Personal Trainer**
- 📄 Suporte para PDFs e imagens de treinos enviados por seu personal trainer
- 📥 Download automático para offline
- ✅ Marcação de treinos como visualizados
- 🔄 Sincronização automática via Firebase

### 8. **Notificações e Lembretes**
- 🔔 Lembretes para fazer check-in diário
- ⏰ Notificações de treino pendente
- 📲 Push notifications customizáveis

### 9. **Integração Apple Health**
- 🏥 Síncrona automaticamente:
  - Workouts completados
  - Calorias queimadas
  - Duração do exercício

### 10. **Recursos Adicionais**
- 🌙 Modo escuro completo
- 🇧🇷 Interface em Português Brasileiro
- 📱 Design responsivo para todos os iPhones
- ⚡ Funciona offline (com dados sincronizados)
- 🔐 Autenticação segura com Firebase

---

## 🛠️ Stack Técnico

- **iOS 17+** / **macOS 14+**
- **Swift 6.0** com strict concurrency
- **SwiftUI** (interface moderna)
- **Firebase** (auth, Firestore, storage)
- **OpenAI API** (geração de treinos com IA)
- **HealthKit** (integração Apple Health)
- **Live Activities** (widget de treino em tempo real)

---

## 🎮 Como Usar

### Fluxo Básico:
1. **Criar Perfil**: Preencha informações de objetivo, nível, equipamento
2. **Check-in Diário**: Escolha foco, energia e estado de dores
3. **Gerar Treino**: Toque em "Gerar Treino" (IA cria automaticamente)
4. **Executar**: Siga o treino com timer integrado
5. **Avaliar**: Rate seu treino e salve no histórico

### Recursos Extras:
- Salve treinos favoritos para reutilizar
- Browse programas pré-configurados
- Visualize PDFs de treinos do seu personal
- Acompanhe seu progresso no histórico

---

## 🧪 O que Testar

Como beta tester, foque em:

### ✅ Funcionalidade Principal:
- [ ] Criar novo perfil de usuário
- [ ] Completar check-in diário
- [ ] Gerar treino com IA
- [ ] Executar treino com timer
- [ ] Salvar e avaliar treino
- [ ] Visualizar histórico

### ✅ Variação de Treinos:
- [ ] Gere 5+ treinos no mesmo dia
- [ ] **Verifique**: Cada treino tem exercícios **diferentes**
- [ ] **Verifique**: Títulos variam (Full Body Força vs Full Body Power, etc.)
- [ ] **Verifique**: Ordem e músculos alvo mudam

### ✅ Integração IA:
- [ ] Configure sua chave OpenAI API
- [ ] Gere treino com IA
- [ ] **Verifique**: Exercícios existem no catálogo
- [ ] **Verifique**: Respeita equipamento configurado
- [ ] **Verifique**: Fallback local funciona se API falhar

### ✅ Timer e Execução:
- [ ] Play/pause durante o treino
- [ ] Timer conta corretamente
- [ ] Progresso visual atualiza
- [ ] Bottom bar flutuante é responsiva

### ✅ Histórico e Stats:
- [ ] Treinos completados aparecem no histórico
- [ ] Avaliações são salvas
- [ ] Streaks calculam corretamente
- [ ] Apple Health sincroniza (se habilitado)

### ✅ Offline:
- [ ] App funciona sem internet
- [ ] Dados sincronizam quando voltar online

---

## 🐛 Reportar Bugs

Ao encontrar um problema, envie:

1. **Descrição clara** do que você estava fazendo
2. **Passos para reproduzir**
3. **O que aconteceu** vs **o que deveria acontecer**
4. **Screenshots ou vídeo** (se possível)
5. **Seu perfil** (objetivo, nível, equipamento)
6. **Device/iOS version**

### Exemplo:
> "Ao gerar treino com foco 'Upper', todos têm o mesmo exercício (Bench Press) na primeira série. Esperava variação. Device: iPhone 15 Pro, iOS 18.1"

---

## 💡 Feedback Desejado

- ✅ **Variação dos treinos** - Estão suficientemente diferentes?
- ✅ **Usabilidade** - Interface é intuitiva?
- ✅ **Performance** - App é responsivo?
- ✅ **Confiabilidade** - Crashes ou bugs?
- ✅ **Sugestões** - Que feature você gostaria?

---

## 📧 Contato

- Reporte bugs via: [seu email/github issues]
- Feedback geral: [seu email]
- Versão Beta: 1.0.0-beta.1
- Data de Teste: [data]

---

## 🙏 Obrigado!

Sua participação no beta é fundamental para tornar FitToday o melhor app de treino com IA. Cada feedback nos ajuda a melhorar!

**Divirta-se treinando! 💪**
