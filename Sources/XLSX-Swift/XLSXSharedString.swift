//
//  File.swift
//  
//
//  Created by Javier Segura Perez on 1/3/23.
//

import Foundation

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
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "t" {
            current_str = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if current_str != nil {
            current_str! += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {            
            
            sharedStrings.append( current_str! )
            current_str = nil
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
