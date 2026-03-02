# Task 15.0: Localization for All New Keys (EN + PT-BR) (S)

<critical>Read the prd.md and techspec.md files in this folder. If you do not read these files, your task will be invalidated.</critical>

## Overview

Add all new localization keys introduced by the FitOrb feature to both EN and PT-BR Localizable.strings.

<requirements>
- All new strings localized in both languages
- No hardcoded strings in code
- Follow existing key naming convention (fitorb.* prefix)
</requirements>

## Subtasks

- [ ] 15.1 Add to `Resources/en.lproj/Localizable.strings`:
  ```
  // Chat persistence
  "fitorb.clear_chat" = "Clear Chat";
  "fitorb.clear_chat_confirm" = "Are you sure you want to clear the chat history?";
  "fitorb.clear_chat_confirm_button" = "Clear";

  // Typing
  "fitorb.typing" = "Typing...";

  // Message limits
  "fitorb.limit_reached" = "Message Limit Reached";
  "fitorb.limit_message" = "You've reached the limit of %d messages per day. Upgrade to Pro for unlimited access.";
  "fitorb.messages_remaining" = "%d messages remaining today";

  // Contextual quick actions
  "fitorb.quick.suggest_workout_today" = "Suggest today's workout";
  "fitorb.quick.recovery_tips" = "Recovery tips";
  "fitorb.quick.daily_motivation" = "Daily motivation";
  "fitorb.quick.morning_warmup" = "Morning warm-up";
  "fitorb.quick.evening_stretch" = "Evening stretch";

  // Error cases
  "fitorb.error.no_connection" = "No internet connection. Try again later.";
  "fitorb.error.service_unavailable" = "FitOrb is temporarily unavailable.";
  "fitorb.error.configure_api_key" = "Configure your OpenAI API key in Settings to use FitOrb.";
  "fitorb.error.empty_response" = "FitOrb couldn't generate a response. Try again.";
  ```
- [ ] 15.2 Add to `Resources/pt-BR.lproj/Localizable.strings`:
  ```
  // Persistencia de chat
  "fitorb.clear_chat" = "Limpar Chat";
  "fitorb.clear_chat_confirm" = "Tem certeza que deseja limpar o historico de conversa?";
  "fitorb.clear_chat_confirm_button" = "Limpar";

  // Digitando
  "fitorb.typing" = "Digitando...";

  // Limites de mensagens
  "fitorb.limit_reached" = "Limite de Mensagens Atingido";
  "fitorb.limit_message" = "Voce atingiu o limite de %d mensagens por dia. Desbloqueie o Pro para acesso ilimitado.";
  "fitorb.messages_remaining" = "%d mensagens restantes hoje";

  // Quick actions contextuais
  "fitorb.quick.suggest_workout_today" = "Sugerir treino de hoje";
  "fitorb.quick.recovery_tips" = "Dicas de recuperacao";
  "fitorb.quick.daily_motivation" = "Motivacao do dia";
  "fitorb.quick.morning_warmup" = "Aquecimento matinal";
  "fitorb.quick.evening_stretch" = "Alongamento noturno";

  // Erros
  "fitorb.error.no_connection" = "Sem conexao com a internet. Tente novamente.";
  "fitorb.error.service_unavailable" = "FitOrb esta temporariamente indisponivel.";
  "fitorb.error.configure_api_key" = "Configure sua chave da OpenAI em Configuracoes para usar o FitOrb.";
  "fitorb.error.empty_response" = "FitOrb nao conseguiu gerar uma resposta. Tente novamente.";
  ```
- [ ] 15.3 Verify no hardcoded strings remain in AIChatView or AIChatViewModel

## Implementation Details

- **Key format**: `fitorb.category.name` (consistent with existing keys)
- **Format strings**: Use `%d` for integers (message count)

## Success Criteria

- All new keys present in both language files
- No untranslated strings in feature code
- Project builds

## Relevant Files
- `Resources/en.lproj/Localizable.strings`
- `Resources/pt-BR.lproj/Localizable.strings`

## Dependencies
- Tasks 1-14 (all feature work complete to know all needed keys)

## status: pending

<task_context>
<domain>presentation</domain>
<type>implementation</type>
<scope>configuration</scope>
<complexity>low</complexity>
<dependencies>tasks_1-14</dependencies>
</task_context>
