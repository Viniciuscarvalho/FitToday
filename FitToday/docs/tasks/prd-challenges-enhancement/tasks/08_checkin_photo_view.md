# Task 8.0: Criar CheckInPhotoView

**Status:** ⬜ Não iniciado
**Dependência:** 7.0
**Fase:** 4 - Presentation Layer

---

## Objetivo

Criar UI para captura/seleção de foto e envio do check-in.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Presentation/Features/Groups/CheckInPhotoView.swift` | View principal |
| `Presentation/Features/Groups/PhotoPickerView.swift` | Componente picker |

---

## Implementação

### 8.1 PhotoPickerView

```swift
struct PhotoPickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        VStack(spacing: FitTodaySpacing.md) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(4/3, contentMode: .fill)
                    .frame(height: 250)
                    .cornerRadius(FitTodayRadius.lg)
                    .clipped()

                Button("Trocar foto") {
                    showImagePicker = true
                }
                .fitSecondaryStyle()
            } else {
                // Empty state with camera/gallery buttons
                VStack(spacing: FitTodaySpacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FitTodayColor.textSecondary)

                    Text("Adicione uma foto do seu treino")
                        .font(.subheadline)
                        .foregroundStyle(FitTodayColor.textSecondary)

                    HStack(spacing: FitTodaySpacing.md) {
                        Button("Câmera") {
                            sourceType = .camera
                            showImagePicker = true
                        }
                        .fitSecondaryStyle()

                        Button("Galeria") {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        }
                        .fitSecondaryStyle()
                    }
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(FitTodayColor.cardBackground)
                .cornerRadius(FitTodayRadius.lg)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: sourceType)
        }
    }
}
```

### 8.2 CheckInPhotoView

```swift
struct CheckInPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CheckInViewModel

    let workoutEntry: WorkoutHistoryEntry
    let onSuccess: (CheckIn) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: FitTodaySpacing.lg) {
                // Header info
                WorkoutSummaryHeader(entry: workoutEntry)

                // Photo picker
                PhotoPickerView(selectedImage: $viewModel.selectedImage)

                Spacer()

                // Submit button
                Button("Fazer Check-in") {
                    Task { await viewModel.submitCheckIn() }
                }
                .fitPrimaryStyle()
                .disabled(!viewModel.canSubmit)
            }
            .padding()
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Enviando...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .alert("Erro", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "Erro desconhecido")
            }
            .onChange(of: viewModel.checkInResult) { _, checkIn in
                if let checkIn {
                    onSuccess(checkIn)
                    dismiss()
                }
            }
        }
    }
}
```

---

## Critérios de Aceite

- [ ] Suporta câmera e galeria
- [ ] Preview da foto selecionada
- [ ] Botão desabilitado sem foto
- [ ] Loading overlay durante upload
- [ ] Alert de erro com mensagem
- [ ] Dismiss após sucesso

---

## Subtasks

- [ ] 8.1 Criar `PhotoPickerView.swift`
- [ ] 8.2 Criar `ImagePicker` (UIViewControllerRepresentable)
- [ ] 8.3 Criar `CheckInPhotoView.swift`
- [ ] 8.4 Adicionar WorkoutSummaryHeader
- [ ] 8.5 Testar fluxo completo
