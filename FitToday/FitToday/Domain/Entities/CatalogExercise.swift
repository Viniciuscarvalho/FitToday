//
//  CatalogExercise.swift
//  FitToday
//
//  Exercise model backed by Firestore catalog.
//  Replaces WgerExercise as the app's canonical exercise type.
//

import Foundation

/// Exercise from the Firestore exercise catalog.
struct CatalogExercise: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String?
    let category: Int?
    let muscles: [Int]
    let musclesSecondary: [Int]
    let equipment: [Int]

    init(
        id: String,
        name: String,
        description: String? = nil,
        category: Int? = nil,
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
