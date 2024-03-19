//
//  Cell.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation
import MIOCore

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
        self.row = MIOCoreUInt32Value( reference.trimmingCharacters( in: .letters ) )!
        self.reference = reference
        self.styleIndex = styleIndex
        self.type = type
        self.value = value
    }
    
    init( row:UInt32, column:UInt16, type: ValueType = .inlineString, value: Any? = nil ) {
        self.row = row
        self.col = column
        self.reference = "\(Cell.reference(byColumnIndex: column))\(row + 1)"
        self.styleIndex = Attributes.styleIndex.rawValue
        self.type = type
        self.value = value
    }
    
    static let reference_letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static func reference( byColumnIndex colIndex:UInt16 ) -> String {
        let letters_count:UInt16 = MCUInt16Value( reference_letters.count )!
                
        if colIndex < letters_count {
            let index = reference_letters.index( reference_letters.startIndex, offsetBy: Int( colIndex ) )
            return String( reference_letters[ index ] )
        }

        let times = (colIndex / letters_count) | 0
        let m = colIndex % letters_count

        var colRef:String = ""
        for _ in [0..<times] { colRef += "A" }

        let index = reference_letters.index( reference_letters.startIndex, offsetBy: Int( m ) )
        colRef += String( reference_letters[ index ] )
        return colRef
    }

    static func index( byColumnReference reference:String ) -> UInt16
    {
        let letters_count:UInt16 = MCUInt16Value( reference_letters.count )!
        
        let ref = reference.trimmingCharacters( in: .decimalDigits )
        if ref.count == 1 {
            let range: Range<String.Index> = reference_letters.range(of: ref)!
            let index: Int = reference_letters.distance( from: reference_letters.startIndex, to: range.lowerBound )
            return MCUInt16Value( index )!
        }
        
        let l = String( ref[ ref.index(before: ref.endIndex) ] )
        let range: Range<String.Index> = reference_letters.range(of: l)!
        let index: Int = reference_letters.distance( from: reference_letters.startIndex, to: range.lowerBound )
                
        let m = ( MCUInt16Value( ref.count - 1 )! ) * letters_count
        return m + MCUInt16Value( index )!
    }
    
}
