//
//  CatalogExercise.swift
//  FitToday
//
//  Exercise model backed by Firestore catalog.
//  The app's canonical exercise type backed by Firestore catalog.
//

import Foundation

/// Exercise from the Firestore exercise catalog.
struct CatalogExercise: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let muscles: [Int]
    let musclesSecondary: [Int]
    let equipment: [Int]

    init(
        id: String,
        name: String,
        description: String? = nil,
        category: String? = nil,
        muscles: [Int] = [],
        musclesSecondary: [Int] = [],
        equipment: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.muscles = muscles
        self.musclesSecondary = musclesSecondary
        self.equipment = equipment
    }
}
