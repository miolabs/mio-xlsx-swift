//
//  File.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation

public struct XLSXCell
{
    enum Attributes : String
    {
        case reference = "r"
        case styleIndex = "s"
        case type =  "t"
    }
    
    public enum ValueType : String
    {
        case number       = "n"
        case boolean      = "b"
        case date         = "d"         // date in ISO8601 format
        case error        = "e"
        case inlineString = "inlineStr" // - string that doesn't use the shared string table
        case sharedString = "s"         // - shared string
        case formula      = "str"       // formula string
    }
    
    public var columnReference:String
    public var rowReference:Int
    public var reference:String
    public var styleIndex:String
    public var type:ValueType
    public var value:Any? = nil
            
    init( reference: String, styleIndex: String, type: ValueType, value: Any? = nil) {
        self.columnReference = reference.trimmingCharacters( in: .decimalDigits )
        self.rowReference = Int( reference.trimmingCharacters( in: .letters ) )!
        self.reference = reference
        self.styleIndex = styleIndex
        self.type = type
        self.value = value
    }
    
}
