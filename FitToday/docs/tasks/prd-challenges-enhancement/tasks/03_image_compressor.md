# Task 3.0: Criar Image Compressor Service

**Status:** ⬜ Não iniciado
**Dependência:** Nenhuma
**Fase:** 1 - Infraestrutura

---

## Objetivo

Criar serviço para compressão de imagens antes do upload.

---

## Arquivos a Criar

| Arquivo | Descrição |
|---------|-----------|
| `Data/Services/ImageCompressor.swift` | Compressão JPEG com limite de tamanho |

---

## Implementação

### 3.1 Criar Protocol

```swift
protocol ImageCompressing: Sendable {
    func compress(data: Data, maxBytes: Int, quality: CGFloat) throws -> Data
}
```

### 3.2 Criar Implementação

```swift
struct ImageCompressor: ImageCompressing {
    enum CompressionError: Error {
        case invalidImage
        case compressionFailed
    }

    func compress(data: Data, maxBytes: Int, quality: CGFloat) throws -> Data {
        guard let image = UIImage(data: data) else {
            throw CompressionError.invalidImage
        }

        var currentQuality = quality
        var compressed = image.jpegData(compressionQuality: currentQuality)

        // Reduce quality until under maxBytes
        while let data = compressed, data.count > maxBytes, currentQuality > 0.1 {
            currentQuality -= 0.1
            compressed = image.jpegData(compressionQuality: currentQuality)
        }

        guard let result = compressed else {
            throw CompressionError.compressionFailed
        }

        return result
    }
}
```

---

## Especificações

| Parâmetro | Valor |
|-----------|-------|
| Max size | 500KB (500_000 bytes) |
| Initial quality | 0.7 |
| Min quality | 0.1 |
| Format | JPEG |

---

## Critérios de Aceite

- [ ] Output sempre ≤ 500KB
- [ ] Mantém aspect ratio original
- [ ] Lança erro se imagem inválida
- [ ] Struct é Sendable

---

## Subtasks

- [ ] 3.1 Criar arquivo `ImageCompressor.swift`
- [ ] 3.2 Implementar protocol `ImageCompressing`
- [ ] 3.3 Implementar struct `ImageCompressor`
- [ ] 3.4 Escrever teste unitário para verificar limite de 500KB
