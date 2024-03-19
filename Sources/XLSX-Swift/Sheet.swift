//
//  Sheet.swift
//  
//
//  Created by Javier Segura Perez on 28/2/23.
//

import Foundation
import MIOCore

#if canImport(FoundationXML)
import FoundationXML
#endif

public final class Sheet : NSObject
{
    public var id:String
    public var name:String
    public var rows:[ Row ] = []
    
    init( id:String, name: String ) {
        self.id = id
        self.name = name
    }
    
    public subscript( reference:String ) -> Any? {
        let row = MIOCoreUInt32Value( reference.trimmingCharacters( in: .letters ), 0 )!
        
        let r = get_row( row - 1)
        let c = r.cell( byColumnRef: reference )
        
        return c?.value
    }
    
    public func write( value: Any?, row: UInt32, col: UInt16, format: CellFormat? = nil) {
        let row = get_row( row )
        let cell = row.cell( index: col )
        
        cell.value = value
    }
        
    func get_row( _ index:UInt32 ) -> Row
    {
        if index > rows.count - 1 {
            // Fill with rows
            for i in 0...index { rows.append( Row( rowIndex: i ) ) }
        }
                
        return rows[ MIOCoreIntValue( index )! ]
    }
    
    var dimension:String {
        let c = Cell.reference( byColumnIndex: maxCellIndex )
        return "A1:\(c)\(rows.count)"
    }
    
    var maxCellIndex:UInt16 {
        var max:UInt16 = 0
        for r in rows {
            if r.cells.count > max {
                max = MCUInt16Value( r.cells.count )!
            }
        }
        return max
    }
}
