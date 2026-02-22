//
//  CMSTrainerMapper.swift
//  FitToday
//
//  Maps CMS trainer DTOs to domain models.
//

import Foundation

enum CMSTrainerMapper {

    static func toDomain(_ dto: CMSTrainer) -> PersonalTrainer {
        PersonalTrainer(
            id: dto.id,
            displayName: dto.displayName,
            email: dto.email ?? "",
            photoURL: dto.photoURL.flatMap { URL(string: $0) },
            specializations: dto.specializations ?? [],
            bio: dto.bio,
            isActive: dto.isActive ?? true,
            inviteCode: dto.inviteCode,
            maxStudents: dto.maxStudents ?? 30,
            currentStudentCount: dto.currentStudentCount ?? 0
        )
    }
}
