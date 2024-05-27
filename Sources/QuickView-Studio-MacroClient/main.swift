import QuickView_Studio_Macro

@QuickViewPlugin
class SomeModel: CodePlugin {
    let name: String = ""
    let description: String = ""
    let version: Version = .init(major: 0, minor: 0, patch: 1)
    let author: String = ""
    let organisation: String = ""
    let type: PluginType = .code
    
    func exec() async throws -> Any { return "" }
}
 
@Processor
class SomeNodeProcessor: ProcessorNode {
    @Input var myVar: Int = 0
    @Input var myVar2: Int = 0
    @Output var firstOutput: Double = 0    
}

let someModel = SomeModel()
let someNodeProcessor = SomeNodeProcessor()
 
dump(someModel)
dump(someNodeProcessor)

