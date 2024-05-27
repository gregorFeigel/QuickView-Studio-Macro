//
//  PipelineContext.swift
//  QuickView Studio
//
//  Created by Gregor Feigel on 27.05.24.
//

import Foundation
import SwiftUI

// MARK: - Base Node
public enum ConsoleMessageType {
    case print
    case info
    case error
    case warning
}

public struct ConsoleMessage: Identifiable {
    public let id: UUID = UUID()
    public let msg: String
    public let date: Date
    public let originator: String
    public let type: ConsoleMessageType
}

public class PipeLineContext: Observable, ObservableObject {
    public init() {}
    
    public var isCancelled: Bool = false
    public var hasChanged: Bool = false
    @Published public var consoleLog: [ConsoleMessage] = []
    
    public func info(originator: String = "Unkown", _ message: String...) {
           let concatenatedMessage = message.joined(separator: " ")
           let consoleMessage = ConsoleMessage(
               msg: concatenatedMessage,
               date: Date(),
               originator: originator,
               type: .info)
            self.consoleLog.append(consoleMessage)
    }
    
    public func error(_ error: Error, originator: String = "Unkown") {
        let consoleMessage = ConsoleMessage(
            msg: error.localizedDescription + " \(error)",
            date: Date(),
            originator: originator,
            type: .error)
         self.consoleLog.append(consoleMessage)
    }
    
    public func print(_ message: String) {}
    
    public func warning(_ message: String) {}
    
    public func changed() { hasChanged.toggle(); self.objectWillChange.send(); print("context has changed") }
}
