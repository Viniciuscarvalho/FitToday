//
//  TopForYouSection.swift
//  FitToday
//
//  Created by AI on 15/01/26.
//

import SwiftUI

// 💡 Learn: Seção "Top pra Você" com programas recomendados
// Componente extraído para manter a view principal < 100 linhas
struct TopForYouSection: View {
    let programs: [Program]
    let onProgramTap: (Program) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FitTodaySpacing.md) {
            SectionHeader(
                title: "home.section.top_for_you".localized,
                actionTitle: "common.see_all".localized,
                action: nil  // TODO: Adicionar navegação para lista completa
            )
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FitTodaySpacing.md) {
                    ForEach(programs) { program in
                        ProgramCardSmall(program: program) {
                            onProgramTap(program)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
