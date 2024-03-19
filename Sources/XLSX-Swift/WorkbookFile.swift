// WorkbookFile.swift

import Foundation
import ZIPFoundation
import DYXML

var wb_file_queue = DispatchQueue( label: "wb_file_queue" )

class WorkbookFile
{
    var archive:Archive?
    
    public init( ) {
        archive = Archive( accessMode: .create )
    }
    
    public init( data: Data ) throws {
        if data[0...1] != "PK".data(using: .utf8 ) {
            throw XLSXError.invalidFileFormat
        }
        
        archive = Archive( data: data, accessMode: .read )
    }
    
    func read( path:String ) throws -> Data? {
        
        guard let entry = archive?[ path ] else { return nil }
        
        let progress = Progress( totalUnitCount: 1 )
        var d = Data()
        
        let semp = DispatchSemaphore( value: 0 )
        
        wb_file_queue.async {
            _ = try? self.archive?.extract( entry, progress: progress, consumer: { data in
                d.append( data )
            } )
                        
            if progress.isFinished { semp.signal() }
        }
        
        semp.wait()
        return d
    }
    
    func write( wb:Workbook ) throws {
        try add_content_types()
        try add_rels( wb: wb )
        try add_workbook( wb:wb )
        try add_workbook_rels( wb: wb )
//        try add_app_xml()
//        try add_core_xml()
//        try add_shared_strings_xml()
//        try add_styles_xml()
//        try add_theme_xml()
        for sh in wb.sheets {
            try add_sheet_xml( sheet: sh )
        }
    }
    
    func data() -> Data? {
        return archive?.data
    }
}

extension WorkbookFile
{
    func add_data( path:String, data:Data ) throws {
        try archive?.addEntry(with: path, type: .file, uncompressedSize: UInt32(data.count), compressionMethod: .deflate, provider: { position, size in
            return data
        } )
    }
    
    func add_content_types() throws {
        let xml = document {
            node( "Types", attributes: [("xmlns", "http://schemas.openxmlformats.org/package/2006/content-types")] ) {
                node( "Default", attributes: [ ("Extension", "rels"), ("ContentType", "application/vnd.openxmlformats-package.relationships+xml") ] ) {}
                node( "Override", attributes: [ ("PartName", "/workbook.xml"), ("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml") ] ) {}
                node( "Override", attributes: [ ("PartName", "/sheet1.xml"), ("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml") ] ) {}
            }
        }
        
        try add_data( path: "[Content_Types].xml", data: xml.string.data(using: .utf8)! )
    }

//    func add_core_xml() throws {
//        let xml = document {
//            node( "cp:coreProperties", attributes: [
//                            ("xmlns:cp", "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"),
//                            ("xmlns:dc", "http://purl.org/dc/elements/1.1/"),
//                            ("xmlns:dcterms", "http://purl.org/dc/terms/"),
//                            ("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
//                        ] ) { }
//        }
//                
//        try add_data( path: "/docProps/core.xml", data: xml.string.data(using: .utf8)! )
//    }
//
//    func add_app_xml() throws {
//        let xml = document {
//            node( "Properties", attributes: [
//                            ("xmlns", "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"),
//                            ("xmlns:vt", "http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes")
//                        ] ) { }
//        }
//                
//        try add_data( path: "/docProps/app.xml", data: xml.string.data(using: .utf8)! )
//    }
    
    func add_rels( wb:Workbook ) throws {
        let xml = document {
            node( "Relationships", attributes: [("xmlns","http://schemas.openxmlformats.org/package/2006/relationships")] ) {
                node( "Relationship", attributes: [
                        ("Id", "rId1"),
                        ("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"),
                        ("Target", "workbook.xml")
                ] ) {}
            }
        }
        
        try add_data( path: "/_rels/.rels", data: xml.string.data(using: .utf8)! )
    }
        
    func add_workbook( wb:Workbook ) throws {
        
        let xml = document {
            node( "workbook", attributes: [
                                ("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main"),
                                ("xmlns:r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
                            ] ) {
                node( "sheets" ) {
                    for sh in wb.sheets {
                        node( "sheet", attributes: [ ("name", sh.name), ("sheetId", sh.id), ("r:id", "rId\(sh.id)") ] ) {}
                    }
                }
            }
        }
        
        try add_data( path: "/workbook.xml", data: xml.string.data(using: .utf8)! )
    }
    
    
    func add_workbook_rels( wb:Workbook ) throws {
        let xml = document {
            node( "Relationships", attributes: [ ("xmlns","http://schemas.openxmlformats.org/package/2006/relationships") ] ) {
                for sh in wb.sheets {
                    node( "Relationship", attributes: [
                                            ("Id", "rId\(sh.id)"),
                                            ("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"),
                                            ("Target", "sheet\(sh.id).xml"),
                    ] ) {}
                }
            }
        }
        
        try add_data( path: "/_rels/workbook.xml.rels", data: xml.string.data(using: .utf8)! )
    }
    
//    func add_shared_strings_xml() throws {
//        let xml = document {
//            node( "sst", attributes: [
//                            ("uniqueCount", "2"),
//                            ("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
//                        ] ) { 
//            
//                node( "si" ) {
//                    node( "t", value: "TEST" )
//                }
//            }
//        }
//                
//        try add_data( path: "xl/sharedStrings.xml", data: xml.string.data(using: .utf8)! )
//    }
//    
//    func add_styles_xml() throws {
//        let xml = document {
//            node( "styleSheet", attributes: [
//                            ("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
//                        ] ) { }
//        }
//                
//        try add_data( path: "/xl/styles.xml", data: xml.string.data(using: .utf8)! )
//    }
//
//    func add_theme_xml() throws {
//        let xml = document {
//            node( "a:theme", attributes: [
//                            ("xmlns:a", "http://schemas.openxmlformats.org/drawingml/2006/main"),
//                            ("xmlns:r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships"),
//                            ("name", "Blank")
//                        ] ) {
//                            node( "a:themeElements" ) {}
//            }
//        }
//                
//        try add_data( path: "/xl/theme/theme1.xml", data: xml.string.data(using: .utf8)! )
//    }
    
    func add_sheet_xml( sheet:Sheet ) throws {
                
        let xml = document {
            node( "worksheet", attributes: [
                ("xmlns", "http://schemas.openxmlformats.org/officeDocument/2006/relationships" ),
                ("xmlns:r", "http://schemas.openxmlformats.org/spreadsheetml/2006/main" )
            ] ) {
//                node( "dimension", attributes: [("ref", sheet.dimension)] ) {}
//                node( "sheetFormatPr", attributes: [
//                    ("defaultColWidth", "16.3333"),
//                    ("defaultRowHeight", "19.9"),
//                    ("customHeight", "1"),
//                    ("outlineLevelRow", "0"),
//                    ("outlineLevelCol", "0")
//                ] ) {}
//                node( "cols" ) {
//                    node( "col", attributes: [
//                        ("min","1"),
//                        ("max","\(sheet.maxCellIndex + 1)"),
//                        ("width","16.3516"),
//                        ("style","1"),
//                        ("customWidth","1")
//                    ] ) {}
//                    node( "col", attributes: [
//                        ("min","\(sheet.maxCellIndex + 2)"),
//                        ("max","16384"),
//                        ("width","16.3516"),
//                        ("style","1"),
//                        ("customWidth","1")
//                    ] ) {}
//                }
                node( "sheetData" ) {
                    let max_cell_index = sheet.maxCellIndex
                    for r in sheet.rows {
                        node( "row", attributes: [ 
                                        ( "r", "\(r.rowIndex + 1)" ),
                                        ( "ht","27.65" ),
                                        ( "customHeight", "1" ) ] ) {
                            for c in r.cellsNormalized( count: max_cell_index ) {
                                if let v = c.value as? String {
                                    node( "c", attributes: [ 
                                                ( "r", c.reference ),
                                                ( "t", c.type.rawValue ),
                                                ( "s", c.styleIndex) ] ) {
                                        node( "v", value: v )
                                    }
                                }
                                else {
                                    node( "c", attributes: [ 
                                                ( "r", c.reference ),
                                                ( "s", c.styleIndex ) ] ){ }
                                }
                            }
                        }
                    }
                }
            }
        }

        try add_data( path: "/sheet\(sheet.id).xml", data: xml.string.data(using: .utf8)! )
    }
}
