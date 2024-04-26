//
//  WorkbookParser.swift
//
//
//  Created by Javier Segura Perez on 6/3/24.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

class WorkbookParser : NSObject, XMLParserDelegate
{
    var sheets:[String:String] = [:]
    
    let file:WorkbookFile
    init ( file: WorkbookFile ) {
        self.file = file
    }
    
    func parse( ) throws -> [String:String] {
        guard let d = try file.read( path: "xl/workbook.xml" ) else {
            throw XLSXError.workbookFileNotFound( file: "xl/workbook.xml" )
        }
        parse_workbook( data: d )
        return sheets
    }
        
    func parse_workbook( data:Data ) {
        let parser = XMLParser( data: data )
        parser.delegate = self
        parser.parse()
    }
                     
    public func parser( _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:] ) {
        
        if elementName == "sheet" {
            let id = attributeDict["sheetId"]!
            let name = attributeDict["name"]!
            sheets[ id ] = name
        }
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        // Decoder sheet file
        print( "END WB")
    }
    
    public func parser( _ parser: XMLParser, parseErrorOccurred parseError: Error ) {
        print( parseError )
    }
}
