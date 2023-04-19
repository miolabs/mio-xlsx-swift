//
//  File.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

final class XLSXSharedString : NSObject, XMLParserDelegate
{
    public var sharedStrings: [String] = []
    
    var data:XLSXData?
    
    public init( data: XLSXData ) {
        self.data = data
        super.init()
    }
    
    deinit {
        print( "NOOO ")
    }
        
    func parse( ) throws {
        
        guard let d = try data!.fileByPath(path: "xl/sharedStrings.xml" ) else { return }
        
        parse_strings( data: d )
    }
    
    var parser : XMLParser?
    func parse_strings( data:Data ) {
        parser = XMLParser( data: data )
        parser?.delegate = self
        parser?.parse()
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
            sharedStrings.append( current_str! )
            current_str = nil
        
        default: break
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // Decoder sheet file
        print("SHARED STRING END")
        
    }
    
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print( parseError )
        
        
    }
}
