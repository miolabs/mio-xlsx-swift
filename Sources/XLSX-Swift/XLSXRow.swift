//
//  File.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation


public struct XLSXRow
{
    public var cells: [ XLSXCell ] = []
    public var cellByColumnRef: [ String: XLSXCell ] = [:]
    
    mutating func append( _ cell: XLSXCell ){
        cells.append( cell )
        cellByColumnRef[ cell.columnReference ] = cell
    }
}
