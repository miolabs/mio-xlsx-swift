//
//  Cell.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation

public class Cell
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
    
    public var col:UInt16
    public var row:UInt32
    
    public var reference:String
    public var styleIndex:String
    public var type:ValueType
    public var value:Any? = nil
            
    init( reference: String, styleIndex: String, type: ValueType, value: Any? = nil ) {
        self.col = Cell.index( byColumnReference: reference )
        self.row = UInt32( reference.trimmingCharacters( in: .letters ) )!
        self.reference = reference
        self.styleIndex = styleIndex
        self.type = type
        self.value = value
    }
    
    init( row:UInt32, column:UInt16, type: ValueType = .inlineString, value: Any? = nil ) {
        self.row = row
        self.col = column
        self.reference = "\(Cell.reference(byColumnIndex: column))\(row + 1)"
        self.styleIndex = "0"
        self.type = type
        self.value = value
    }
    
    static let reference_letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static func reference( byColumnIndex colIndex:UInt16 ) -> String {
        // Excel column references are bijective base-26: A..Z, AA..AZ, BA..ZZ, AAA...
        var n = Int( colIndex ) + 1
        var colRef = ""
        while n > 0 {
            let m = ( n - 1 ) % 26
            let index = reference_letters.index( reference_letters.startIndex, offsetBy: m )
            colRef = String( reference_letters[ index ] ) + colRef
            n = ( n - 1 ) / 26
        }
        return colRef
    }

    static func index( byColumnReference reference:String ) -> UInt16
    {
        let ref = reference.trimmingCharacters( in: .decimalDigits )
        var n = 0
        for l in ref {
            let range: Range<String.Index> = reference_letters.range( of: String( l ) )!
            let index: Int = reference_letters.distance( from: reference_letters.startIndex, to: range.lowerBound )
            n = n * 26 + index + 1
        }
        return UInt16( n - 1 )
    }
    
}
