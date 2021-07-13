//
//  File.swift
//  
//
//  Created by Jeshurun Roach on 7/13/21.
//

import Foundation
import SwiftUI

public extension View {
    
    func handleError(_ errorHandler: @escaping (Error) throws -> ()) -> some View {
        modifier(ErrorHandlingViewMod(errorHandler: errorHandler))
    }
    
    func handleError<E: Error>(_ errorHandler: @escaping (E) throws -> ()) -> some View {
        handleError { error in
            guard let typedError = error as? E else { return }
            try errorHandler(typedError)
        }
    }
}


private struct ErrorHandlingEnvironmentKey: EnvironmentKey {
    static var defaultValue: (Error) -> () {
        { error in assertionFailure("Unhandled UI Error: \(error)") }
    }
}

private struct ErrorHandlingViewMod: ViewModifier {
    @Environment(\.errorHandler) var superErrorHandler
    
    var errorHandler: (Error) throws -> ()
    
    func body(content: Content) -> some View {
        content.environment(\.errorHandler) { error in
            do {
                try errorHandler(error)
            } catch {
                superErrorHandler(error)
            }
        }
    }
}

public extension EnvironmentValues {
    var errorHandler: (Error) -> () {
        get { self[ErrorHandlingEnvironmentKey.self] }
        set { self[ErrorHandlingEnvironmentKey.self] = newValue }
    }
}

