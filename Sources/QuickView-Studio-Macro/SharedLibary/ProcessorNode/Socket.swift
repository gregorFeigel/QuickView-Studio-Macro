//
//  Node.swift
//  Node-Linking
//
//  Created by Beau Nouvelle on 23/7/21.
//

import Foundation
import SwiftUI

public class AnyInput: InputType {
    public func set(_ value: Any) throws {  }
    
    public func matchType(_ value: Any) -> Bool { false }
    
    public var id: String = ""
}

public class AnyOutput: OutputType {
    public var value: Any = ""
    public var id: String = ""
}

public enum SocketType {
    case input(InputType)
    case output(OutputType)
    
    public static var input: SocketType { return.input(AnyInput()) }
    public static var output: SocketType { return.output(AnyOutput()) }
}

public final class Socket: Identifiable {
    public init(id: UUID = UUID(), position: CGPoint = .zero, _ type: SocketType, key: String = "", node: ProcessorNode) {
        self.id = id
        self.position = position
        self.type = type
        self.key = key
        self.node = node
    }
    
    public var id = UUID()
    var position: CGPoint = .zero
    let type: SocketType
    let key: String
    let node: ProcessorNode
}

extension SocketType: Equatable {
    public static func == (lhs: SocketType, rhs: SocketType) -> Bool {
        switch (lhs, rhs) {
            case (.input(_), .input(_)):
                return true
            case (.output(_), .output(_)):
                return true
            default:
                return false
        }
    }
}
