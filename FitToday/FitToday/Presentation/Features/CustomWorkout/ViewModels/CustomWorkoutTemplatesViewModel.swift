//
//  CustomWorkoutTemplatesViewModel.swift
//  FitToday
//
//  Created by Claude on 28/01/26.
//

import Foundation

/// ViewModel for managing the list of custom workout templates
@Observable
@MainActor
final class CustomWorkoutTemplatesViewModel {
    // MARK: - State

    var templates: [CustomWorkoutTemplate] = []
    var isLoading = false
    var error: Error?
    var showCreateSheet = false
    var templateToEdit: CustomWorkoutTemplate?
    var templateToDelete: CustomWorkoutTemplate?
    var selectedTemplate: CustomWorkoutTemplate?

    // MARK: - Dependencies

    private let repository: CustomWorkoutRepository

    // MARK: - Initialization

    init(repository: CustomWorkoutRepository) {
        self.repository = repository
    }

    // MARK: - Actions

    func loadTemplates() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            templates = try await repository.listTemplates()
        } catch {
            self.error = error
        }
    }

    func deleteTemplate(_ template: CustomWorkoutTemplate) async {
        do {
            try await repository.deleteTemplate(id: template.id)
            templates.removeAll { $0.id == template.id }
        } catch {
            self.error = error
        }
    }

    func confirmDelete(_ template: CustomWorkoutTemplate) {
        templateToDelete = template
    }

    func cancelDelete() {
        templateToDelete = nil
    }

    func performDelete() async {
        guard let template = templateToDelete else { return }
        await deleteTemplate(template)
        templateToDelete = nil
    }

    func editTemplate(_ template: CustomWorkoutTemplate) {
        templateToEdit = template
    }

    func selectTemplate(_ template: CustomWorkoutTemplate) {
        selectedTemplate = template
    }
}
