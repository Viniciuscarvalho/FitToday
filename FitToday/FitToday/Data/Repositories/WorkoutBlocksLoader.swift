//
//  WorkoutBlocksLoader.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import Foundation

struct WorkoutBlocksLoader: Sendable {
    private let fileName: String
    private let bundle: Bundle

    init(fileName: String = "WorkoutBlocksSeed", bundle: Bundle = .main) {
        self.fileName = fileName
        self.bundle = bundle
    }

    func loadBlocks() throws -> [WorkoutBlock] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw DomainError.repositoryFailure(reason: "seed \(fileName).json não encontrado no bundle.")
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dtos = try decoder.decode([WorkoutBlockDTO].self, from: data)
        return dtos.compactMap { $0.toDomain() }
    }
}

private struct WorkoutBlockDTO: Codable {
    let id: String
    let group: String
    let level: String
    let compatibleStructures: [String]
    let equipmentOptions: [String]
    let suggestedSets: [Int]
    let suggestedReps: [Int]
    let restInterval: TimeInterval
    let exercises: [WorkoutExerciseDTO]

    func toDomain() -> WorkoutBlock? {
        guard
            let focus = DailyFocus(rawValue: group),
            let level = TrainingLevel(rawValue: level)
        else { return nil }

        let structures = compatibleStructures.compactMap(TrainingStructure.init(rawValue:))
        let equipments = equipmentOptions.compactMap(EquipmentType.init(rawValue:))

        let exercisesDomain = exercises.compactMap { $0.toDomain() }
        guard !exercisesDomain.isEmpty else { return nil }

        let setsRange = IntRange(suggestedSets.first ?? 3, suggestedSets.last ?? 3)
        let repsRange = IntRange(suggestedReps.first ?? 8, suggestedReps.last ?? 12)

        return WorkoutBlock(
            id: id,
            group: focus,
            level: level,
            compatibleStructures: structures,
            equipmentOptions: equipments,
            exercises: exercisesDomain,
            suggestedSets: setsRange,
            suggestedReps: repsRange,
            restInterval: restInterval
        )
    }
}

private struct WorkoutExerciseDTO: Codable {
    let id: String
    let name: String
    let mainMuscle: String
    let equipment: String
    let instructions: [String]
    let media: WorkoutMediaDTO?

    func toDomain() -> WorkoutExercise? {
        guard
            let muscle = MuscleGroup(rawValue: mainMuscle),
            let equipment = EquipmentType(rawValue: equipment)
        else { return nil }

        return WorkoutExercise(
            id: id,
            name: name,
            mainMuscle: muscle,
            equipment: equipment,
            instructions: instructions,
            media: media?.toDomain()
        )
    }
}

private struct WorkoutMediaDTO: Codable {
    let imageURL: String?
    let gifURL: String?
    let source: String?

    func toDomain() -> ExerciseMedia {
        ExerciseMedia(
            imageURL: imageURL.flatMap(URL.init(string:)),
            gifURL: gifURL.flatMap(URL.init(string:)),
            source: source
        )
    }
}

