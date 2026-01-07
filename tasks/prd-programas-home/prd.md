# PRD — FitToday Programas + Home (v1)

## Visão Geral

Evoluir a experiência principal do FitToday para ser mais clara, visual e orientada a “Programas”, reduzindo confusão de navegação na Home e melhorando a descoberta de treinos gratuitos. Além disso, formalizar o uso de IA (OpenAI) como benefício exclusivo do plano Pro, e garantir integração segura com serviços externos (OpenAI e ExerciseDB via RapidAPI) sem commitar chaves no repositório.

Problemas atuais:

1) **Topo com “linha/header”**: a aplicação exibe um topo com uma linha/estilo de header que quebra a estética e passa sensação de layout “inacabado”.
2) **Navegação confusa na Home**: atalhos e múltiplos caminhos tornam a experiência menos direta.
3) **Treinos gratuitos pouco atrativos**: listagem vertical com baixa ênfase visual; deveria ser mais “coleção” (cards).
4) **IA e chaves**: precisa usar OpenAI e RapidAPI sem expor chaves no código; IA deve ser restrita ao Pro com capacidades específicas.
5) **Histórico com pouco contexto**: usuário quer observar treino registrado e sua evolução (duração/calorias) e, quando aplicável, o vínculo com um programa.

## Objetivos

- Tornar a Home mais simples e “fitness app look”: **Hero + Top for You + Week’s Workout**.
- Introduzir a entidade **Program** e substituir **Biblioteca → Programas**.
- Exibir programas/títulos Free em **collection** com imagem de fundo e cards consistentes.
- Aplicar regras de recomendação:
  - Objetivo = emagrecimento → priorizar programas metabólicos
  - Objetivo = força → priorizar programas strength
  - Se treinou ontem → evitar repetir o mesmo tipo hoje
- Definir o uso de IA como **exclusivo do Pro** com:
  - Ajuste fino
  - Personalização diária
  - Reordenação de blocos
  - Linguagem/explicações
- Permitir trocar a sugestão do treino diário **pelo menos 1 vez**; após ver e terminar o treino, o CTA da Home vira **“Próximo treino em breve”**.
- Integrar mídia de exercícios via RapidAPI ExerciseDB `/image` com parâmetros obrigatórios `resolution` e `exerciseId`, com chave em **Keychain** (sem commitar).

Métricas sugeridas:

- CTR na Home (Hero/Top for You/Week’s Workout → detalhe).
- Conversão Free → Programas (abertura e início de treino).
- Taxa de carregamento de mídia (sucesso vs falha).
- Conclusão de treino e repetição semanal.

## Histórias de Usuário

- Como **usuário**, eu quero uma Home objetiva com recomendações relevantes para iniciar um treino rapidamente.
- Como **usuário Free**, eu quero ver programas de treino como cards visuais (collection) para escolher com confiança.
- Como **usuário**, eu quero ver no histórico o treino registrado e, se ele faz parte de um programa, acompanhar evolução (calorias/duração).
- Como **usuário Pro**, eu quero que a IA melhore o treino do dia (personalização, reordenação, explicações) com qualidade de especialista.
- Como **usuário**, eu quero poder trocar a sugestão do treino do dia ao menos uma vez se não gostar.

## Funcionalidades Principais

### 1) Ajuste global do topo/header

Requisitos funcionais:

1.1 Remover a “linha/título” do topo em toda a app.  
1.2 Garantir consistência entre tabs e telas com `NavigationStack`/toolbar.

### 2) Programas (substitui Biblioteca)

Requisitos funcionais:

2.1 Criar entidade **Program** e mapear treinos existentes dentro dela.  
2.2 Criar **3–5 programas iniciais** (metabólico/strength) com imagens de fundo.  
2.3 Renomear Tab “Biblioteca” para “Programas” e ajustar rotas.

### 3) Home reestruturada

Requisitos funcionais:

3.1 Remover atalhos atuais da Home.  
3.2 Quebrar Home em seções:
  - Hero
  - Top for You
  - Week’s Workout
3.3 Implementar cards:
  - **ProgramCard (grande)**: imagem, nome, duração, CTA.
  - **ProgramCard (small)**: horizontal, sem CTA grande; tap abre detalhe.
  - **WorkoutCard**: imagem, tipo, tempo, badge de intensidade.

### 4) Recomendação de programas/treinos

Requisitos funcionais:

4.1 Se objetivo = emagrecimento, priorizar programas metabólicos.  
4.2 Se objetivo = força, priorizar programas strength.  
4.3 Se treinou ontem, evitar repetir o mesmo tipo hoje (priorizar alternância).

### 5) IA apenas no Pro + troca de sugestão do treino

Requisitos funcionais:

5.1 IA só disponível para Pro e apenas para:
  - Ajuste fino
  - Personalização diária
  - Reordenação de blocos
  - Linguagem/explicações
5.2 Se o usuário não gostar da sugestão do treino diário, permitir trocar **pelo menos 1 vez**.  
5.3 Depois de “ver e terminar” o treino, botão da Home vira “Próximo treino em breve”.

### 6) Mídia via RapidAPI ExerciseDB `/image`

Requisitos funcionais:

6.1 Buscar imagem/GIF via RapidAPI `GET /image` com parâmetros obrigatórios:
  - `resolution` (string)
  - `exerciseId` (string)
6.2 A `rapidapi-key` deve ser lida do **Keychain** (sem commitar).  
6.3 Placeholder + cache + logs não sensíveis em caso de falha.

## Experiência do Usuário

- A Home deve parecer “página inicial” de app fitness: visual, com hierarquia clara e CTAs consistentes.
- Cards devem ter boa legibilidade em dark mode e imagens com overlay/gradiente quando necessário.
- Navegação:
  - Home → detalhe do programa/treino
  - Programas → detalhe do programa → lista de treinos/exercícios
  - Histórico → detalhe da sessão → vínculo com programa e evolução

## Restrições Técnicas de Alto Nível

- iOS SwiftUI, arquitetura em camadas (Domain/Data/Presentation).
- DI via Swinject.
- Persistência local via SwiftData (onde aplicável).
- Chaves (OpenAI, RapidAPI) **não podem** estar hardcoded em código versionado.
- IA apenas no Pro (StoreKit entitlement).

## Não-Objetivos (Fora de Escopo)

- Editor completo de periodização/planejamento multi-semanas.
- Download offline de mídia.
- Chat com IA.

## Questões em Aberto

- Qual conjunto de `resolution` suportado pela RapidAPI para `/image` e quais tamanhos a UI deve preferir por contexto (card vs detalhe)?
- Como definir “treinou ontem”: baseado em histórico concluído vs iniciado?



