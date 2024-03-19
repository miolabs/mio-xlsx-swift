//
//  Row.swift
//
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation
import MIOCore

public class Row
{
    public var rowIndex:UInt32
    public var cells: [ Cell ] = []
    public var cellByColumnRef: [ String: Cell ] = [:]
    
    init( rowIndex: UInt32 ) { self.rowIndex = rowIndex }
    
    func append( _ cell: Cell ) {        
        cells.append( cell )
        cellByColumnRef[ cell.reference ] = cell
    }
    
    func cell( byColumnRef ref: String ) -> Cell? {
        return cellByColumnRef[ ref ]
    }
    
    func cell( index: UInt16 ) -> Cell {
        
        if index > cells.count - 1 {
            for i in 0...index { cells.append( Cell( row: rowIndex, column: i ) ) }
        }
                
        return cells[ Int( index ) ]
    }
    
    func cellsNormalized( count: UInt16 ) -> [Cell] {        
        _ = cell( index:  count )
        return cells
    }

}
