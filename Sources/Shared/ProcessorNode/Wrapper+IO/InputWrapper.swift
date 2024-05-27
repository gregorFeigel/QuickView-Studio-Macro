//
//  InputWrapper.swift
//  QuickView Studio
//
//  Created by Gregor Feigel on 27.05.24.
//

import Foundation
import SwiftUI

public protocol InputType {
    mutating func set(_ value: Any) throws
    func matchType(_ value: Any) -> Bool
}

public enum InputMode {
    case set
    case collect
}

@propertyWrapper
public class Input<T>: InputType, DynamicProperty, ObservableObject, Observable {
    public typealias linkerFunction = (Any) -> T
    var inputMode: InputMode
    public var wrappedValue: T
    var linker: linkerFunction?
 
    public init(wrappedValue: T, _ inputMode: InputMode = .set, linker: linkerFunction? = nil) {
        self.wrappedValue = wrappedValue
        self.inputMode = inputMode
        self.linker = linker
    }
        
    public func set(_ value: Any) throws {
        if let f = linker { self.wrappedValue = f(value) }
        else {
            switch inputMode {
                case .set:
                    if type(of: value) != T.self { throw "type \(type(of: value)) does not match Intput<\(T.self)>" }
                    self.wrappedValue = value as! T
                case .collect:
                    if isCollection(object: wrappedValue) {
                        if var array = wrappedValue as? [Any] {
                            array.append(value)
                            self.wrappedValue = array as! T
                        }
                        else { throw "cannot wrap input as collection" }
                    }
                    else { throw "object is not of type collection" }
            }
        }
    }
    
    public func matchType(_ value: Any) -> Bool {
        if type(of: value) == T.self { return true }
        else if type(of: value) == [Double].self { return true }
        return false
    }
    
    private func isCollection(object: T) -> Bool {
        switch object {
            case _ as any Collection:
                return true
            default:
                return false
        }
    }
}
