//
//  HistoryViewModel.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

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

// 💡 Learn: @Observable permite observação granular - apenas propriedades acessadas disparam updates
@MainActor
@Observable final class HistoryViewModel: ErrorPresenting {
    private(set) var sections: [HistorySection] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = true
    private(set) var insights: HistoryInsights?
    var errorMessage: ErrorMessage? // ErrorPresenting protocol

    private let repository: WorkoutHistoryRepository
    private let pageSize = 20 // Carregar 20 itens por vez
    private var currentOffset = 0
    private var allLoadedEntries: [WorkoutHistoryEntry] = []
    private let insightsUseCase = ComputeHistoryInsightsUseCase()

    init(repository: WorkoutHistoryRepository) {
        self.repository = repository
    }

    func loadHistory() {
        Task {
            await fetchInitialPage()
        }
    }

    func refresh() async {
        // Reset pagination state
        currentOffset = 0
        allLoadedEntries = []
        hasMorePages = true
        await fetchInitialPage()
    }
    
    func loadMoreIfNeeded() {
        guard !isLoadingMore && hasMorePages && !isLoading else { return }
        Task {
            await fetchNextPage()
        }
    }

    private func fetchInitialPage() async {
        isLoading = true
        defer { isLoading = false }
        
        currentOffset = 0
        allLoadedEntries = []
        
        do {
            let entries = try await repository.listEntries(limit: pageSize, offset: currentOffset)
            allLoadedEntries = entries
            sections = Self.group(entries)
            insights = insightsUseCase.execute(entries: allLoadedEntries)
            
            // Verificar se há mais páginas
            hasMorePages = entries.count == pageSize
            currentOffset = entries.count
        } catch {
            handleError(error) // ErrorPresenting protocol
        }
    }
    
    private func fetchNextPage() async {
        guard hasMorePages else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let entries = try await repository.listEntries(limit: pageSize, offset: currentOffset)
            
            // Append às entradas existentes
            allLoadedEntries.append(contentsOf: entries)
            sections = Self.group(allLoadedEntries)
            insights = insightsUseCase.execute(entries: allLoadedEntries)
            
            // Atualizar estado de paginação
            hasMorePages = entries.count == pageSize
            currentOffset += entries.count
        } catch {
            handleError(error) // ErrorPresenting protocol
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

