//
//  PersonalWorkout.swift
//  FitToday
//
//  Treino enviado pelo Personal Trainer via CMS.
//

import Foundation

/// Treino enviado pelo Personal Trainer via CMS.
public struct PersonalWorkout: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let trainerId: String
    public let userId: String
    public let title: String
    public let description: String?
    public let fileURL: String
    public let fileType: FileType
    public let createdAt: Date
    public var viewedAt: Date?

    /// Tipo de arquivo do treino.
    public enum FileType: String, Codable, Sendable, CaseIterable {
        case pdf
        case image

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .image: return "photo.fill"
            }
        }
    }

    /// Indica se o treino ainda não foi visualizado.
    public var isNew: Bool {
        viewedAt == nil
    }

    /// URL convertida para uso no app.
    public var fileURLValue: URL? {
        URL(string: fileURL)
    }

    /// Data formatada para exibição.
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: createdAt)
    }

    /// Data relativa (ex: "há 2 dias").
    public var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    public init(
        id: String,
        trainerId: String,
        userId: String,
        title: String,
        description: String? = nil,
        fileURL: String,
        fileType: FileType,
        createdAt: Date,
        viewedAt: Date? = nil
    ) {
        self.id = id
        self.trainerId = trainerId
        self.userId = userId
        self.title = title
        self.description = description
        self.fileURL = fileURL
        self.fileType = fileType
        self.createdAt = createdAt
        self.viewedAt = viewedAt
    }
}

// MARK: - Fixtures for Testing

#if DEBUG
extension PersonalWorkout {
    static func fixture(
        id: String = UUID().uuidString,
        trainerId: String = "trainer123",
        userId: String = "user456",
        title: String = "Treino A - Peito e Tríceps",
        description: String? = "Treino focado em hipertrofia",
        fileURL: String = "https://firebasestorage.googleapis.com/example.pdf",
        fileType: FileType = .pdf,
        createdAt: Date = Date(),
        viewedAt: Date? = nil
    ) -> PersonalWorkout {
        PersonalWorkout(
            id: id,
            trainerId: trainerId,
            userId: userId,
            title: title,
            description: description,
            fileURL: fileURL,
            fileType: fileType,
            createdAt: createdAt,
            viewedAt: viewedAt
        )
    }
}
#endif
