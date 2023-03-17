//
//  XLSXSheet.swift
//  
//
//  Created by Javier Segura Perez on 28/2/23.
//

import Foundation

public final class Sheet : NSObject, XMLParserDelegate
{
    let wb: Workbook
    
    public init ( workbook: Workbook ) {
        self.wb = workbook
    }
    
    func parse( name:String ) throws {
        
//        guard let d = try wb.data.fileByPath(path: "xl/worksheets/\(name.lowercased()).xml" ) else { return }
        guard let d = try wb.data.fileByPath(path: "xl/worksheets/sheet1.xml" ) else { return }
        parse_sheet( data: d )
    }

    var parser : XMLParser?
    func parse_sheet( data:Data ) {
        parser = XMLParser( data: data )
        parser?.delegate = self
        parser?.parse()
    }
    
    public var rows:[ XLSXRow ] = []
    
    var current_row: XLSXRow?
    var current_cell:XLSXCell?
    var current_cell_value:String?
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "row" {
            current_row = XLSXRow()
        }
        else if elementName == "c" {
            let r = attributeDict[ XLSXCell.Attributes.reference.rawValue ]!
            let s = attributeDict[ XLSXCell.Attributes.styleIndex.rawValue ]!
            let t_value = attributeDict[ XLSXCell.Attributes.type.rawValue ]
            
            let t:XLSXCell.ValueType? = t_value != nil ? XLSXCell.ValueType(rawValue: t_value! ) : nil
            if t == nil  && t_value != nil {
                print( "\(t_value!) Not supported" )
            }
                        
            current_cell = XLSXCell( reference: r, styleIndex: s, type: t ?? XLSXCell.ValueType.number )
        }
        else if elementName == "v" {
            current_cell_value = ""
        }
    }
    
    public func parser( _ parser: XMLParser, foundCharacters string: String ) {
        if current_cell_value != nil { current_cell_value! += string }
    }
    
    public func parser( _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String? ) {
        if elementName == "v" {
            
            switch current_cell!.type {
            case .sharedString:
                let index = Int( current_cell_value!.trimmingCharacters(in: .whitespacesAndNewlines ) )!
                current_cell!.value = wb.sharedStrings.sharedStrings[ index ]
                
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
            rows.append( current_row! )
            current_row = nil
        }
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
                
    }
}
