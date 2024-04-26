//
//  SheetParser.swift
//
//
//  Created by Javier Segura Perez on 6/3/24.
//

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

class SheetParser : NSObject, XMLParserDelegate
{
    let file:WorkbookFile
    let shared_strings:[String]
    
    init( file: WorkbookFile, sharedStrings:[String] ){
        self.file = file
        self.shared_strings = sharedStrings
    }
    
    var sh:Sheet!
    
    func parse( id:String, name:String ) throws -> Sheet {
        let path = "xl/worksheets/sheet\(id).xml"
        guard let d = try file.read( path: path ) else {
            throw XLSXError.workbookFileNotFound( file: path )
        }
        
        sh = Sheet( id: id, name: name )
        
        let parser = XMLParser( data: d )
        parser.delegate = self
        parser.parse()
        return sh
    }
    
    var current_row_index:UInt32 = 0
    var current_row: Row?
    var current_cell:Cell?
    var current_cell_value:String?
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "row" {
            current_row = Row( rowIndex: current_row_index )
            current_row_index += 1
        }
        else if elementName == "c" {
            let r = attributeDict[ Cell.Attributes.reference.rawValue ]!
            let s = attributeDict[ Cell.Attributes.styleIndex.rawValue ]
            let t_value = attributeDict[ Cell.Attributes.type.rawValue ]
            
            let t:Cell.ValueType? = t_value != nil ? Cell.ValueType(rawValue: t_value! ) : nil
            if t == nil  && t_value != nil {
                print( "\(t_value!) Not supported" )
            }
                        
            current_cell = Cell( reference: r, styleIndex: s ?? "", type: t ?? Cell.ValueType.number )
        }
        else if elementName == "v" { current_cell_value = "" }
    }
    
    public func parser( _ parser: XMLParser, foundCharacters string: String ) {
        if current_cell_value != nil { current_cell_value! += string }
    }
    
    public func parser( _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String? ) {
        if elementName == "v" {
            
            switch current_cell!.type {
            case .sharedString:
                let index = Int( current_cell_value!.trimmingCharacters(in: .whitespacesAndNewlines ) )!
                current_cell!.value = shared_strings[ index ]
                
            case .inlineString: current_cell!.value = current_cell_value!
            case .number: current_cell!.value = current_cell_value!
            case .formula: current_cell!.value = current_cell_value!
            default: break
            }
                                    
            current_cell_value = nil
        }
        else if elementName == "c" {
            current_row?.append( current_cell! )
            current_cell = nil
        }
        else if elementName == "row" {
            sh.rows.append( current_row! )
            current_row = nil
        }
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
                
    }
}
