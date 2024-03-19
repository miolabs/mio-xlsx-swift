//
//  SharedStringParser.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

final class SharedStringParser : NSObject, XMLParserDelegate
{
    let file:WorkbookFile
    var strings: [String] = []

    init( file: WorkbookFile ) {
        self.file = file
    }
    
    func parse( ) throws -> [String] {
        guard let d = try file.read( path: "xl/sharedStrings.xml" ) else {
            throw XLSXError.workbookFileNotFound( file: "xl/sharedStrings.xml" )
        }

        let parser = XMLParser( data: d )
        parser.delegate = self
        parser.parse()
        return strings
    }
             
    var current_str:String? = nil
    var append_str = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
            
        case "si": current_str = ""
        case "t": append_str = true
        
        default:break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if current_str != nil && append_str == true {
            current_str! += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        
        case "t": append_str = false
        case "si":
            strings.append( current_str! )
            current_str = nil
        
        default: break
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // Decoder sheet file
        print("SHARED STRING END")
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error ) {
        print( parseError )
        
        
    }
}

