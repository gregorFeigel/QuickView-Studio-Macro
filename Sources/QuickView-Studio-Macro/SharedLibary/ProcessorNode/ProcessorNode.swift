//
//  File.swift
//  QuickView Studio
//
//  Created by Gregor Feigel on 23.05.24.
//

import Foundation
import SwiftUI

// The base class for all processor nodes
open class ProcessorNode: Identifiable {
   
    public init() {
        self.position = .zero
        self.sockets = []
    }
    
    public let id: UUID = UUID()
    
    @Published var position: CGPoint = .zero
    
    public var sockets: [Socket]
    
    open func process(_ context: PipeLineContext) async throws {}
    
    open func nodeBody(context: PipeLineContext) -> any View { EmptyView() }
}

// add Hashable conformance
extension ProcessorNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// add Equatable conformance
extension ProcessorNode: Equatable {
    public static func == (lhs: ProcessorNode, rhs: ProcessorNode) -> Bool {
        rhs.id == lhs.id
    }
}

// add observable conformance
extension ProcessorNode: ObservableObject, Observable { }

// Sockets
extension ProcessorNode {
    func socketFor(key: String) throws -> Socket {
        guard let socket = sockets.first(where: { $0.key == key })
        else { throw "no sock named \(key)" }
        return socket
    }
}


