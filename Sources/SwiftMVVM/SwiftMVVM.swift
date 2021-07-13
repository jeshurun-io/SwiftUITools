import Foundation
import SwiftUI
import Combine

public protocol ModeledView: View {
    associatedtype ViewModel: ViewModelType where ViewModel.View == Self
    associatedtype Content: View
    var vm: ViewModel { get }
    var content: Content { get }
}

public extension ModeledView {
    var body: some View {
        vm.view = self
        return content.onAppear(perform: { vm.onAppear() })
            .onDisappear(perform: { vm.onDisappear() })
            .handleError(vm.handle(error:))
            .environmentObject(vm)
    }
}

public protocol ViewModelType: ObservableObject {
    associatedtype View: ModeledView
    var view: View! { get set }
    func onUpdate()
    func onLoad()
    func onAppear()
    func onDisappear()
    func handle(error: Error) throws
}

public extension ViewModelType {
    func onUpdate() {}
    func onLoad() {}
    func onAppear() {}
    func onDisappear() {}
    func handle(error: Error) throws { throw error }
}

open class BaseViewModel<View: ModeledView>: ViewModelType {
    
    public var subscriptions = Set<AnyCancellable>()
    
    public var view: View! {
        didSet {
            onUpdate()
            if oldValue == nil { onLoad() }
        }
    }
    
    public init() {
        
    }
    
    open func onUpdate() {}
    open func onLoad() {}
    open func onAppear() {}
    open func onDisappear() {}
    open func handle(error: Error) throws { throw error }
}
