//
//  File.swift
//
//
//  Created by Gregor Feigel on 26.05.24.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct Processor: MemberMacro {
    
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        guard declaration.isClass else {
            guard let diagnostic = Diagnostics.diagnose(declaration: declaration) else { throw "Macro only works on class" }
            context.diagnose(diagnostic)
            return []
        }
        
        // let intVariables: [(String, String)] = try getParametersOf(type: "String", from: declaration)
        let input: String = try getParameter(wrapped: "Input", in: declaration).map {   ".init(.input(_\($0)), key: \"\($0)\", node: self)"  }.joined(separator: ",")
        let output: String = try getParameter(wrapped: "Output", in: declaration).map {  ".init(.output(_\($0)), key: \"\($0)\", node: self)" }.joined(separator: ",")
        
        let superInit: DeclSyntax = """
              override init() {
                super.init()
                self.sockets = [\(raw: [input].joined(separator: ","))]
              }
              """
        return [ superInit ]
    }
    
    static func getParameter(wrapped by: String, in decl: some DeclGroupSyntax) throws -> [String] {
        let syntax: [String?] = decl.memberBlock.members.compactMap { member in
            guard let syntax = member.decl.as(VariableDeclSyntax.self),
                  let bindings = syntax.bindings.as(PatternBindingListSyntax.self),
                  let pattern = bindings.first?.as(PatternBindingSyntax.self),
                  let identifier = (pattern.pattern.as(IdentifierPatternSyntax.self))?.identifier.trimmed.text,
                  let wrapper = syntax.attributes.first?.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name
            else { return nil }
            
            if wrapper.text == by { return identifier }
            return nil
        }
        return syntax.map { $0! }
        
    }

    static func generateNewInitialiser(from initialiser: InitializerDeclSyntax) -> InitializerDeclSyntax {
        var newInitialiser = initialiser
        // add parameter
        let newParameterList = FunctionParameterListSyntax {
            newInitialiser.signature.parameterClause.parameters
            "count: Int"
        }
        newInitialiser.signature.parameterClause.parameters = newParameterList
        
        // add statement initialising count
        newInitialiser.body?.statements.append("self.count = count")
        
        return newInitialiser
    }
}

extension Processor: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let decl: DeclSyntax =
              """
              extension \(type.trimmed): QuickViewStudioPlugin {}
              """

            guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else {
              return []
            }

            return [extensionDecl]
    }
    
    
}

extension Processor {
 
    private static func getParametersOf(type: String, from declaration: some DeclGroupSyntax) throws -> [(String, String)] {
         return declaration.memberBlock.members
             .compactMap { member in
                 guard
                    let syntax = member.decl.as(VariableDeclSyntax.self),
                    let bindings = syntax.bindings.as(PatternBindingListSyntax.self),
                    let pattern = bindings.first?.as(PatternBindingSyntax.self),
                    let identifier = (pattern.pattern.as(IdentifierPatternSyntax.self))?.identifier.trimmed.text
                 else {  return ("", "")  }
                 
                 // Track the keys in the object to make sure the requested keys to filter are properly spelled..
                 let declType = extractType(from: pattern)
                 return (identifier, declType!)
//                 if declType == type { return identifier }
//                 return nil
             }
             //.map { $0 }
        }

      /// Extract and transforms an `ExprSyntax` into an equivalent `String` representation.
      ///
      /// - Parameter binding: A `PatternBindingSyntax` to decompose.
      /// - Returns: A `String` representation of the embedded `ExprSyntax`.
      private static func extractType(from binding: PatternBindingSyntax) -> String? {
        guard let initializer = binding.initializer else {
          return nil
        }

        // 3.9 as Float || [3, "Hi"] as [Any] || ["key": "value", "anotherKey": 1] as [String: Any]
        if
          let sequenceSyntax = binding.initializer?.value.as(SequenceExprSyntax.self),
          let castedType = sequenceSyntax.elements.first(where: { $0.kind == .typeExpr })?.description {
          let isOptional = sequenceSyntax.elements
            .first(where: { $0.kind == .unresolvedAsExpr })?
            .as(UnresolvedAsExprSyntax.self)?
            .questionOrExclamationMark != nil

          return isOptional ? "\(castedType)?" : castedType
        }

        if let arraySyntax = initializer.value.as(ArrayExprSyntax.self) {
          // A non homogenous array has to be either explicitly declared or casted.
          // Getting to this point we can assume it's something like `let array = [1, 3, 8]`.
          guard
            let firstElement = arraySyntax.elements.first,
            var type = extractType(from: firstElement.expression)
          else {
            return nil
          }

          type = arraySyntax.elements.contains(where: { $0.expression.is(NilLiteralExprSyntax.self) }) ? "\(type)?" : type
          return "[\(type)]"
        }

        if let dictionarySyntax = initializer.value.as(DictionaryExprSyntax.self) {
          // A non homogenous dictionary has to be either explicitly declared or casted.
          // Getting to this point we can assume it's an array with  homogeneous key, and type.
          guard
            let dictionaryListSyntax = dictionarySyntax.content.as(DictionaryElementListSyntax.self),
            let anyElement = dictionaryListSyntax.first(where: { !$0.value.is(NilLiteralExprSyntax.self) }),
            let keyType = extractType(from: anyElement.key),
            var valueType = extractType(from: anyElement.value)
          else {
            return nil
          }

          valueType = dictionaryListSyntax.contains(where: { $0.value.is(NilLiteralExprSyntax.self) }) ? "\(valueType)?" : valueType
          return "[\(keyType): \(valueType)]"
        }

        return extractType(from: initializer.value)
      }

      /// Transforms an `ExprSyntax` into an equivalent `String` representation.
      ///
      /// Example: BooleanLiteralExprSyntax => Bool
      /// - Parameter expression: An `ExprSyntax` value.
      /// - Returns: A `String` representation. `nil` if not applicable.
      private static func extractType(from expression: ExprSyntax) -> String? {
        if expression.is(BooleanLiteralExprSyntax.self) {
          return "Bool"
        }

        if expression.is(StringLiteralExprSyntax.self) {
          return "String"
        }

        if expression.is(IntegerLiteralExprSyntax.self) {
          return "Int"
        }

        // Non casted FloatLiteralExprSyntax are inferred as `Double` by the compiler.
        if expression.is(FloatLiteralExprSyntax.self) {
          return "Double"
        }

        if expression.is(NilLiteralExprSyntax.self) {
          return "nil"
        }

        return nil
      }

      private static func getAccessLevel(of node: AttributeSyntax) -> AccessLevel {
        let accessLevel: AccessLevel = switch node
          .arguments?.as(LabeledExprListSyntax.self)?
          .first(where: { $0.label?.tokenKind == .identifier("accessLevel") })?
          .expression.as(MemberAccessExprSyntax.self)?
          .declName.baseName {
          case let .some(token): token.text == "public" ? .public : .internal
          case .none: .public
        }

        return accessLevel
      }

      private static func getAccessLevel(of declaration: some DeclGroupSyntax) -> AccessLevel {
        return declaration.modifiers.contains(
          where: { ($0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open)) }
        ) ? .public : .internal
      }

      private static func getKeysToExclude(from node: AttributeSyntax) -> [String] {
        return node
          .arguments?.as(LabeledExprListSyntax.self)?
          .first(where: { $0.label?.tokenKind == .identifier("exclude") })?
          .expression.as(ArrayExprSyntax.self)?
          .elements
          .compactMap({
            $0.expression.as(StringLiteralExprSyntax.self)?
              .segments.as(StringLiteralSegmentListSyntax.self)?
              .first?.as(StringSegmentSyntax.self)?
              .content
              .text
          }) ?? []
      }

      private static func getDefaultValues(from node: AttributeSyntax) -> [String: String] {
        return node
          .arguments?.as(LabeledExprListSyntax.self)?
          .first(where: { $0.label?.tokenKind == .identifier("defaultValues") })?
          .expression.as(DictionaryExprSyntax.self)?
          .content.as(DictionaryElementListSyntax.self)?
          .reduce(into: [String: String](), { partialResult, element in
            guard let key = element.key.as(StringLiteralExprSyntax.self)?.segments.first?.as(StringSegmentSyntax.self)?.content.text else {
              return
            }

            partialResult[key] = "\(element.value)"
          }) ?? [:]
      }
  
  }

public enum AccessLevel: String, Equatable, Comparable {
  /// Creates an internal initialiser.
  case `internal` = "internal"

  /// Creates an public initialiser.
  case `public` = "public"

  public static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool {
    lhs == .internal && rhs == .public
  }
}

enum SError: Error, CustomStringConvertible {
   case invalidAccessLevel
   case invalidAccessLevelHierarchy
   case invalidType
   case cannotInferType(variable: String)
   case excludingNonInitialisedProperty(named: String)
   case inexistentKey(named: String)

   var description: String {
     switch self {
       case .invalidAccessLevel:
         return "Invalid access level. Macro only works with open, public or internal."

       case .invalidAccessLevelHierarchy:
         return "The requested access level is higher than the object's access level."

       case .invalidType:
         return "This macro only works with `struct` and `class`."

       case let .cannotInferType(variable):
         return "Could not infer the type for \(variable). Please specify it explicitly."

       case let .excludingNonInitialisedProperty(name):
         return "Property \(name) was excluded without being initialised."
         
       case let .inexistentKey(name):
         return "\(name) is not a property."
     }
   }
 }
