//
//  File.swift
//  
//
//  Created by Jeshurun Roach on 7/13/21.
//

import Foundation
import SwiftUI

public struct DependencyFactory {
    public let container: DependencyContainer
    fileprivate init(container: DependencyContainer) {
        self.container = container
    }
}


@dynamicMemberLookup
public class DependencyContainer: ObservableObject {
    
    public init(_ buildBlock: (inout Builder) -> () = { _ in }) {
        var builder = Builder()
        buildBlock(&builder)
        self.store = builder.store
    }
    
    private var store: [PartialKeyPath<DependencyFactory>: Any] = [:]
    
    public subscript<D>(dynamicMember keyPath: KeyPath<DependencyFactory, D>) -> D {
        get {
            if let anyDependency = store[keyPath] {
                guard let dependency = anyDependency as? D else {
                    if let _ = anyDependency as? RecursiveDependencyMarker {
                        fatalError("Dependeny Cycle Detected!")
                    } else {
                        fatalError("Dependency Type Mismatch!")
                    }
                }
                return dependency
            } else {
                store[keyPath] = RecursiveDependencyMarker()
                let dependency = factory[keyPath: keyPath]
                store[keyPath] = dependency
                return dependency
            }
        }
        set {
            if store[keyPath] != nil {
                assertionFailure("Value for \(keyPath) already initialized!")
            }
            store[keyPath] = newValue
        }
    }
}

// MARK: - Private Helpers

private extension DependencyContainer {
    private struct RecursiveDependencyMarker { }
    
    private var factory: DependencyFactory {
        DependencyFactory(container: self)
    }
}


// MARK: - Builder

extension DependencyContainer {
    @dynamicMemberLookup
    public struct Builder {
        fileprivate var store: [PartialKeyPath<DependencyFactory>: Any] = [:]
        public subscript<D>(dynamicMember keyPath: KeyPath<DependencyFactory, D>) -> D? {
            get { store[keyPath] as? D }
            set { store[keyPath] = newValue }
        }
    }
}


// MARK: - SwiftUI

private struct DependencyEnvironmentKey: EnvironmentKey {
    static var defaultValue: DependencyContainer { DependencyContainer() }
}

extension EnvironmentValues {
    public var di: DependencyContainer {
        get { self[DependencyEnvironmentKey.self] }
        set { self[DependencyEnvironmentKey.self] = newValue }
    }
}

extension View {
    public func initialize(dependencies: DependencyContainer) -> some View {
        environment(\.di, dependencies)
    }
}
