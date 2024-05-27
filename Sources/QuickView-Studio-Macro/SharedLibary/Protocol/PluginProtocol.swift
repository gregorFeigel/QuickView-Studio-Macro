//
//  File.swift
//  
//
//  Created by Gregor Feigel on 26.05.24.
//

import Foundation
import SwiftUI

public struct Version: Codable, Comparable, Hashable {
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    public let major: Int
    public let minor: Int
    public let patch: Int
}

extension Version {
    var str: String { return "V\(major).\(minor).\(patch)" }
}

extension Version {
    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}


public protocol PluginTypeProtocol {}

@available(macOS 14.0, *)
public protocol DataVisualisation: QuickViewStudioPlugin, Observable, ObservableObject {
    // func view() -> Self.Body
    var view: AnyView { get }
}

public protocol CodePlugin: QuickViewStudioPlugin {
    func exec() async throws -> Any
}

public enum PluginType: String, Equatable, Hashable, Codable {
    case dataVisualisation = "dataVisualisation"
    case dataProcessing = "dataProcessing"
    case code = "code"
    case videoExporter = "videoExporter"
    case dataImporter = "dataImporter"
    case machineLearning = "machineLearning"
    case statisticalAnalysis = "statisticalAnalysis"
    case geospatialAnalysis = "geospatialAnalysis"
    case other = "other"

    var shortDescription: String {
        switch self {
        case .dataVisualisation:
            return "DataV"
        case .dataProcessing:
            return "DataP"
        case .code:
            return "Code "
        case .videoExporter:
            return "Video"
        case .dataImporter:
            return "DataI"
        case .machineLearning:
            return "Machi"
        case .statisticalAnalysis:
            return "StatA"
        case .geospatialAnalysis:
            return "GeoSp"
        case .other:
            return "Other"
        }
    }
    
    var protocolType: Any.Type {
        switch self {
            case .dataVisualisation:
                break
            case .dataProcessing:
                break
            case .code:
                return CodePlugin.self
            case .videoExporter:
                break
            case .dataImporter:
                break
            case .machineLearning:
                break
            case .statisticalAnalysis:
                break
            case .geospatialAnalysis:
                break
            case .other:
                break
        }
        return CodePlugin.self
    }
    
}

public enum PluginSource: Hashable {
    case localPackage(URL)
    case file(URL)
    case gitHub(URL)
    case dylib(URL)
    case other
}

public protocol QuickViewStudioPlugin {
    var name: String { get }
    var description: String { get }
    var version: Version { get }
    var author: String   { get }
    var organisation: String { get }
    var type: PluginType { get }
}

extension String: Error {}

// MARK: - Plugin Handler

final class PluginHandler {
    
    var plugins: [QuickViewStudioPlugin] = []
    
    
    
}

// MARK: - Shard Code
@available(macOS 10.15.0, *)
open class PluginBuilder<T> {
    
    public init() {}
    
    open func build() -> T {
        fatalError("You have to override this method.")
    }
}

func load<T: Any>(url: URL) throws -> T {

    typealias InitFunction = @convention(c) () -> UnsafeMutableRawPointer
    
    let openRes = dlopen(url.path, RTLD_NOW|RTLD_LOCAL)
    if openRes != nil {
        defer { dlclose(openRes) }

        let symbolName = "createPlugin"
        let sym = dlsym(openRes, symbolName)

        if sym != nil {
            let f: InitFunction = unsafeBitCast(sym, to: InitFunction.self)
            let pluginPointer = f()
            let builder = Unmanaged<PluginBuilder<T>>.fromOpaque(pluginPointer).takeRetainedValue()
            let t: T = builder.build() // !!
            return t
        }
        else {
            throw "error loading lib: symbol \(symbolName) not found, path: \(url)"
        }
    }
    else {
        if let err = dlerror() {
            throw "error opening lib: \(String(format: "%s", err)), path: \(url)"
        }
        else {
            throw "error opening lib: unknown error, path: \(url)"
        }
    }
}

func load<T>(url: URL, type: T.Type) throws -> T {

    typealias InitFunction = @convention(c) () -> UnsafeMutableRawPointer
    
    let openRes = dlopen(url.path, RTLD_NOW|RTLD_LOCAL)
    if openRes != nil {
        defer { dlclose(openRes) }

        let symbolName = "createPlugin"
        let sym = dlsym(openRes, symbolName)

        if sym != nil {
            let f: InitFunction = unsafeBitCast(sym, to: InitFunction.self)
            let pluginPointer = f()
            let builder = Unmanaged<PluginBuilder<T>>.fromOpaque(pluginPointer).takeRetainedValue()
            let t: T = builder.build() // !!
            return t
        }
        else {
            throw "error loading lib: symbol \(symbolName) not found, path: \(url)"
        }
    }
    else {
        if let err = dlerror() {
            throw "error opening lib: \(String(format: "%s", err)), path: \(url)"
        }
        else {
            throw "error opening lib: unknown error, path: \(url)"
        }
    }
}
