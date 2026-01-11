//
//  DependencyResolverKey.swift
//  FitToday
//
//  Created by AI on 04/01/26.
//

import SwiftUI
import Swinject

private struct DependencyResolverKey: EnvironmentKey {
    static let defaultValue: Resolver = Container()
}

extension EnvironmentValues {
    var dependencyResolver: Resolver {
        get { self[DependencyResolverKey.self] }
        set { self[DependencyResolverKey.self] = newValue }
    }
}




