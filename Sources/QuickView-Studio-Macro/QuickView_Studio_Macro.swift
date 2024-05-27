
// Generates the code needed to compile class into dylib for QuickView Studio
/// - Checks for conformance of QuickViewStudioPlugin
/// - adds builder method
@attached(peer, names: suffixed(QuickViewStudioPluginBuilder), named(createPlugin))
@attached(member, names: arbitrary)
public macro QuickViewPlugin() = #externalMacro( module: "QuickView_Studio_MacroMacros", type: "QuickViewPlugin")



// Generates the code needed to create a NodeProcessor class QuickView Studio
/// - Checks for conformance of QuickViewStudioPlugin, NodeProcessor
/// - adds builder method
@attached(extension, conformances: QuickViewStudioPlugin)
@attached(member, names: arbitrary)
public macro Processor() = #externalMacro( module: "QuickView_Studio_MacroMacros", type: "Processor")

