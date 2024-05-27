import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension String: Error {}

struct QuickViewPlugin {}

// MARK: - Member Macro
extension QuickViewPlugin: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard declaration.isClass else {
            guard let diagnostic = Diagnostics.diagnose(declaration: declaration) else { throw "Macro only works on class" }
            context.diagnose(diagnostic)
            return []
        }
        return []
    }
}

// MARK: - Peer Macro
extension QuickViewPlugin: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let decl = declaration.as(ClassDeclSyntax.self)
        else { throw "Macro only works on class" }
        
 
        guard let type = decl.inheritanceClause?.inheritedTypes.as(InheritedTypeListSyntax.self)?.first?.as(InheritedTypeSyntax.self)?.type.as(IdentifierTypeSyntax.self)?.name
        else { throw "Unable to access Protocols" }
        
        let pluginCode: DeclSyntax = """
            @available(macOS 12.0, *)
            public final class \(raw: decl.name.text)QuickViewStudioPluginBuilder: PluginBuilder<\(raw: type)> {
                 public override func build() -> \(raw: type) {
                     \(raw: decl.name.text)()
                 }
            }
            
             @available(macOS 12.0, *)
             @_cdecl("createPlugin")
             public func createPlugin() -> UnsafeMutableRawPointer {
                 return Unmanaged.passRetained(\(raw: decl.name.text)QuickViewStudioPluginBuilder()).toOpaque()
             }
            """
        
        return [pluginCode]
    }
}

