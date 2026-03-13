//
//  XPLevel.swift
//  FitToday
//

import Foundation

enum XPLevel: String, Sendable, Codable {
    case iniciante = "Iniciante"
    case guerreiro = "Guerreiro"
    case tita = "Titã"
    case lenda = "Lenda"
    case imortal = "Imortal"

    init(level: Int) {
        switch level {
        case 1...4: self = .iniciante
        case 5...9: self = .guerreiro
        case 10...14: self = .tita
        case 15...19: self = .lenda
        default: self = .imortal
        }
    }

    var icon: String {
        switch self {
        case .iniciante: return "star"
        case .guerreiro: return "shield.fill"
        case .tita: return "bolt.fill"
        case .lenda: return "crown.fill"
        case .imortal: return "flame.fill"
        }
    }
}
