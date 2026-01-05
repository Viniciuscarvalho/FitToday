//
//  HistoryViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation
import Combine

struct HistorySection: Identifiable, Hashable {
    let id: Date
    let date: Date
    let entries: [WorkoutHistoryEntry]

    var title: String {
        Self.formatter.string(from: date).capitalized
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter
    }()
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var sections: [HistorySection] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let listUseCase: ListWorkoutHistoryUseCase

    init(repository: WorkoutHistoryRepository) {
        self.listUseCase = ListWorkoutHistoryUseCase(repository: repository)
    }

    func loadHistory() {
        Task {
            await fetchHistory()
        }
    }

    func refresh() async {
        await fetchHistory()
    }

    private func fetchHistory() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let entries = try await listUseCase.execute()
            sections = Self.group(entries)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func group(_ entries: [WorkoutHistoryEntry]) -> [HistorySection] {
        let grouped = Dictionary(grouping: entries) { entry -> Date in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: entry.date)
            return calendar.date(from: components) ?? entry.date
        }
        return grouped
            .map { HistorySection(id: $0.key, date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }
}

