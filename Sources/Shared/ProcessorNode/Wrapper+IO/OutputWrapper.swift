//
//  OutputWrapper.swift
//  QuickView Studio
//
//  Created by Gregor Feigel on 27.05.24.
//

import Foundation

public protocol OutputType {
    var value: Any { get }
    var id: String { get }
}

@propertyWrapper
public class Output<T>: OutputType {
    public init(wrappedValue: T, _ name: String = #function) {
        self.wrappedValue = wrappedValue
        self.id = name
    }
    
    public var value: Any { wrappedValue }
    public var wrappedValue: T
    public let id: String
}
