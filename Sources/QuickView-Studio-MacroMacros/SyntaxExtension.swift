//
//  File.swift
//  
//
//  Created by Gregor Feigel on 27.05.24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension DeclGroupSyntax {
    /// Declaration name
    /// example: struct User will return "User"
    var name: String? {
        asProtocol(NamedDeclSyntax.self)?.name.text
    }
    
    var isClass: Bool {
        self.as(ClassDeclSyntax.self) != nil
    }
}
