//
//  XLSXWorkbook.swift
//  
//
//  Created by Javier Segura Perez on 28/2/23.
//

import Foundation
import ZIPFoundation

#if canImport(FoundationXML)
import FoundationXML
#endif

public final class Workbook : NSObject, XMLParserDelegate
{
    public var sheets: [Sheet] = []
    
    var sharedStrings:XLSXSharedString
    var sheetNames:[String] = []
        
    let data: XLSXData
    init ( data: XLSXData ) {
        self.data = data
        self.sharedStrings = XLSXSharedString( data: data )
    }
    
    deinit {
        print( "NO SHIT" )
    }
            
    func parse( ) throws {
                                        
        guard let d = try data.fileByPath( path: "xl/workbook.xml" ) else { return }
        
        parse_workbook( data: d )
    }
    
    var parser : XMLParser?
    func parse_workbook( data:Data ) {
        parser = XMLParser( data: data )
        parser?.delegate = self
        parser?.parse()
    }
                     
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "sheet" {
            let name = attributeDict["name"]
            if name != nil {
                sheetNames.append( name! )
            }
        }
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        // Decoder sheet file
        print( "END WB")
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print( parseError )
    }
}
