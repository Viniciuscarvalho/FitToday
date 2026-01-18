//
//  View+ErrorAlert.swift
//  FitToday
//
//  Created by Claude on 17/01/26.
//

import SwiftUI

extension View {
    /// View modifier to show error alerts
    func showErrorAlert(errorMessage: Binding<ErrorMessage?>) -> some View {
        self.alert(
            errorMessage.wrappedValue?.title ?? "Erro",
            isPresented: Binding(
                get: { errorMessage.wrappedValue != nil },
                set: { if !$0 { errorMessage.wrappedValue = nil } }
            ),
            presenting: errorMessage.wrappedValue
        ) { _ in
            Button("OK") {
                errorMessage.wrappedValue = nil
            }
        } message: { error in
            Text(error.message)
        }
    }
}
