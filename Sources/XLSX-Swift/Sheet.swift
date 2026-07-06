//
//  Sheet.swift
//  
//
//  Created by Javier Segura Perez on 28/2/23.
//

import Foundation

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
        let row = UInt32( reference.trimmingCharacters( in: .letters ) ) ?? 0
        
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
        if Int( index ) >= rows.count {
            // Fill with the missing rows
            for i in rows.count...Int( index ) { rows.append( Row( rowIndex: UInt32( i ) ) ) }
        }

        return rows[ Int( index ) ]
    }
    
    var dimension:String {
        let c = Cell.reference( byColumnIndex: maxCellIndex )
        return "A1:\(c)\(rows.count)"
    }
    
    var maxCellIndex:UInt16 {
        var max:UInt16 = 0
        for r in rows {
            if r.cells.count > max {
                max = UInt16( r.cells.count )
            }
        }
        return max
    }
}
