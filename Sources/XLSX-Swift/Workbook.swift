//
//  Workbook.swift
//  
//
//  Created by Javier Segura Perez on 28/2/23.
//

import Foundation
import ZIPFoundation

#if canImport(FoundationXML)
import FoundationXML
#endif

public final class Workbook : NSObject
{
    public var sheets:[Sheet] = []
    var sheet_info:[String:String]
    
    var shared_strings:[String]
                    
    public override init ( ) {
        sheet_info = [:]
        shared_strings = []
    }
    
    public init ( data: Data ) throws 
    {
        let file = try WorkbookFile( data: data )
        sheet_info = try WorkbookParser( file: file ).parse()
        shared_strings = try SharedStringParser( file: file ).parse()
        for (id, name) in sheet_info {
            sheets.append( try SheetParser( file: file, sharedStrings: shared_strings ).parse( id: id, name: name ) )
        }
    }
    
    public func addWorksheet( withName name:String? = nil ) -> Sheet
    {
        let id = "\(sheets.count + 1)"
        let n = name ?? "sheet\(sheets.count + 1)"
        let sh = Sheet( id: id, name: n )
        sheets.append( sh )
        sheet_info[ id ] = n
        return sh
    }
    
    @discardableResult
    public func save() throws -> Data? {
        let f = WorkbookFile()
        try f.write( wb: self )
        return f.data()
    }
    
    public func save( toFilePath path:String ) throws {
        try save( toFileURL: URL( fileURLWithPath: path ) )
    }
    
    public func save( toFileURL url:URL ) throws {
        let data = try save()
        try data?.write( to: url )
    }
}
