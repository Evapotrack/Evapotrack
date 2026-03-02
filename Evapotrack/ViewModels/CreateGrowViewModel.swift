// CreateGrowViewModel.swift
// Evapotrack
//
// Form state and validation for creating a new Grow.
// Grows are immutable after creation.

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class CreateGrowViewModel {

    // MARK: - Form State

    var growName = ""
    var validationError: String?
    var showSaveConfirmation = false

    // MARK: - Dependencies

    private var growService: GrowService?

    func configure(modelContext: ModelContext) {
        guard growService == nil else { return }
        self.growService = GrowService(modelContext: modelContext)
    }

    // MARK: - Actions

    func validate() -> Bool {
        validationError = nil

        let nameResult = ValidationService.validateGrowName(growName)
        if !nameResult.isValid {
            validationError = nameResult.errorMessage
            return false
        }

        // Prevent duplicate grow names (case-insensitive)
        if let service = growService {
            let trimmed = growName.trimmingCharacters(in: .whitespaces).lowercased()
            let existingGrows = service.fetchAll()
            if existingGrows.contains(where: { $0.growName.trimmingCharacters(in: .whitespaces).lowercased() == trimmed }) {
                validationError = "A grow with this name already exists."
                return false
            }
        }

        return true
    }

    func save() -> Bool {
        guard validate() else { return false }
        guard let service = growService else {
            validationError = "Unable to save. Please try again."
            return false
        }

        let grow = Grow(
            growName: growName.trimmingCharacters(in: .whitespaces)
        )

        service.addGrow(grow)
        showSaveConfirmation = true
        return true
    }
}
