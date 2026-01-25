# Task 14.0: Adicionar Strings de Localização

**Status:** ⬜ Não iniciado
**Dependência:** 8.0, 9.0
**Fase:** 6 - Finalização

---

## Objetivo

Adicionar todas as strings de UI em inglês e português.

---

## Arquivos a Modificar

| Arquivo | Idioma |
|---------|--------|
| `Resources/en.lproj/Localizable.strings` | Inglês |
| `Resources/pt-BR.lproj/Localizable.strings` | Português |

---

## Strings a Adicionar

### Inglês (en)

```swift
// MARK: - Check-In
"checkin.title" = "Check-in";
"checkin.button.submit" = "Submit Check-in";
"checkin.button.camera" = "Camera";
"checkin.button.gallery" = "Gallery";
"checkin.photo.placeholder" = "Add a photo of your workout";
"checkin.photo.change" = "Change photo";
"checkin.sending" = "Sending...";
"checkin.success.title" = "Check-in Done!";
"checkin.success.subtitle" = "Your workout was recorded";
"checkin.error.photo_required" = "Photo is required for check-in";
"checkin.error.workout_short" = "Workout must be at least 30 minutes (current: %d min)";
"checkin.error.no_network" = "No internet connection";
"checkin.error.not_in_group" = "You need to be in a group to check-in";
"checkin.error.upload_failed" = "Upload failed: %@";

// MARK: - Feed
"feed.title" = "Feed";
"feed.empty.title" = "No check-ins yet";
"feed.empty.subtitle" = "Be the first to check-in!";
"feed.duration" = "%d min";

// MARK: - Celebration
"celebration.checkin.title" = "Check-in Done!";
"celebration.checkin.subtitle" = "Your workout was recorded";
"celebration.rankup.title" = "You moved up to #%d!";
"celebration.rankup.subtitle" = "Keep it up!";
"celebration.topthree.title" = "Top 3!";
"celebration.topthree.subtitle" = "You're among the best!";

// MARK: - Group Tabs
"group.tab.feed" = "Feed";
"group.tab.leaderboard" = "Ranking";
```

### Português (pt-BR)

```swift
// MARK: - Check-In
"checkin.title" = "Check-in";
"checkin.button.submit" = "Fazer Check-in";
"checkin.button.camera" = "Câmera";
"checkin.button.gallery" = "Galeria";
"checkin.photo.placeholder" = "Adicione uma foto do seu treino";
"checkin.photo.change" = "Trocar foto";
"checkin.sending" = "Enviando...";
"checkin.success.title" = "Check-in Feito!";
"checkin.success.subtitle" = "Seu treino foi registrado";
"checkin.error.photo_required" = "Foto é obrigatória para fazer check-in";
"checkin.error.workout_short" = "Treino deve ter no mínimo 30 minutos (atual: %d min)";
"checkin.error.no_network" = "Sem conexão com a internet";
"checkin.error.not_in_group" = "Você precisa estar em um grupo para fazer check-in";
"checkin.error.upload_failed" = "Falha no upload: %@";

// MARK: - Feed
"feed.title" = "Feed";
"feed.empty.title" = "Nenhum check-in ainda";
"feed.empty.subtitle" = "Seja o primeiro a fazer check-in!";
"feed.duration" = "%d min";

// MARK: - Celebration
"celebration.checkin.title" = "Check-in Feito!";
"celebration.checkin.subtitle" = "Seu treino foi registrado";
"celebration.rankup.title" = "Você subiu para #%d!";
"celebration.rankup.subtitle" = "Continue assim!";
"celebration.topthree.title" = "Top 3!";
"celebration.topthree.subtitle" = "Você está entre os melhores!";

// MARK: - Group Tabs
"group.tab.feed" = "Feed";
"group.tab.leaderboard" = "Ranking";
```

---

## Uso nas Views

```swift
// Exemplo de uso
Text("checkin.title".localized)
Text("checkin.error.workout_short".localized(with: duration))
```

---

## Critérios de Aceite

- [ ] Todas as strings em ambos idiomas
- [ ] Placeholders %d e %@ funcionam
- [ ] Nenhuma string hardcoded na UI
- [ ] Strings seguem padrão existente

---

## Subtasks

- [ ] 14.1 Adicionar strings EN
- [ ] 14.2 Adicionar strings PT-BR
- [ ] 14.3 Atualizar CheckInError para usar localized strings
- [ ] 14.4 Verificar todas as views usam .localized
