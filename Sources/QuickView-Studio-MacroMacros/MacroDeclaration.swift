//
//  File.swift
//  
//
//  Created by Gregor Feigel on 26.05.24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct QuickView_Studio_MacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        QuickViewPlugin.self,
        Processor.self
    ]
}

