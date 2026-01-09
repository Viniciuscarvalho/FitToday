//
//  SDCachedWorkout.swift
//  FitToday
//
//  Created by AI on 09/01/26.
//

import Foundation
import SwiftData

/// Modelo SwiftData para cache de composição de treino (F7)
/// TTL padrão de 24h para evitar chamadas redundantes à OpenAI
@Model
final class SDCachedWorkout {
  /// Hash único dos inputs (profile + checkIn + blueprintVersion + seed)
  @Attribute(.unique) var inputsHash: String
  
  /// Payload do treino em JSON
  var workoutPlanJSON: Data
  
  /// Data de criação do cache
  var createdAt: Date
  
  /// Data de expiração (createdAt + TTL)
  var expiresAt: Date
  
  /// Objetivo do usuário (para auditoria)
  var goalRaw: String
  
  /// Estrutura/local (para auditoria)
  var structureRaw: String
  
  /// Foco do dia (para auditoria)
  var focusRaw: String
  
  /// Versão do blueprint (para compatibilidade)
  var blueprintVersion: String
  
  /// Seed de variação
  var variationSeed: UInt64
  
  /// TTL padrão: 24 horas
  static let defaultTTLSeconds: TimeInterval = 24 * 60 * 60
  
  init(
    inputsHash: String,
    workoutPlanJSON: Data,
    createdAt: Date = .init(),
    expiresAt: Date? = nil,
    goalRaw: String,
    structureRaw: String,
    focusRaw: String,
    blueprintVersion: String,
    variationSeed: UInt64
  ) {
    self.inputsHash = inputsHash
    self.workoutPlanJSON = workoutPlanJSON
    self.createdAt = createdAt
    self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(Self.defaultTTLSeconds)
    self.goalRaw = goalRaw
    self.structureRaw = structureRaw
    self.focusRaw = focusRaw
    self.blueprintVersion = blueprintVersion
    self.variationSeed = variationSeed
  }
  
  /// Verifica se o cache expirou
  var isExpired: Bool {
    Date() > expiresAt
  }
  
  /// Tempo restante até expiração (em segundos)
  var timeToLive: TimeInterval {
    max(0, expiresAt.timeIntervalSince(Date()))
  }
}
