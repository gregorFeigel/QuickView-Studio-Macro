//
//  PipelineContext.swift
//  QuickView Studio
//
//  Created by Gregor Feigel on 27.05.24.
//

import Foundation
import SwiftUI

// MARK: - Base Node
enum ConsoleMessageType {
    case print
    case info
    case error
    case warning
}

struct ConsoleMessage: Identifiable {
    let id: UUID = UUID()
    let msg: String
    let date: Date
    let originator: String
    let type: ConsoleMessageType
}

public class PipeLineContext: Observable, ObservableObject {
    var isCancelled: Bool = false
    var hasChanged: Bool = false
    @Published var consoleLog: [ConsoleMessage] = []
    
    func info(originator: String = "Unkown", _ message: String...) {
           let concatenatedMessage = message.joined(separator: " ")
           let consoleMessage = ConsoleMessage(
               msg: concatenatedMessage,
               date: Date(),
               originator: originator,
               type: .info)
            self.consoleLog.append(consoleMessage)
    }
    
    func error(_ error: Error, originator: String = "Unkown") {
        let consoleMessage = ConsoleMessage(
            msg: error.localizedDescription + " \(error)",
            date: Date(),
            originator: originator,
            type: .error)
         self.consoleLog.append(consoleMessage)
    }
    
    func print(_ message: String) {}
    
    func warning(_ message: String) {}
    
    func changed() { hasChanged.toggle(); self.objectWillChange.send(); print("context has changed") }
}
