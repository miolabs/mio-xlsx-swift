// WorkbookFile.swift

import Foundation
import ZIPFoundation
import DYXML

var wb_file_queue = DispatchQueue( label: "wb_file_queue" )

class WorkbookFile
{
    var archive:Archive?
    /// Number formats used by the workbook's cells, in first-use order:
    /// format i is cell style i + 1 (style 0 is the default)
    var formats:[ CellFormat ] = []
    
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
        formats = cell_formats( wb: wb )
        try add_content_types( wb: wb )
        try add_rels( wb: wb )
        try add_workbook( wb:wb )
        try add_workbook_rels( wb: wb )
//        try add_app_xml()
//        try add_core_xml()
//        try add_shared_strings_xml()
        try add_styles_xml()
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
        try archive?.addEntry(with: path, type: .file, uncompressedSize: Int64(data.count), compressionMethod: .deflate, provider: { (position:Int64, size:Int) in
            let start = Int( position )
            return data.subdata( in: start..<(start + size) )
        } )
    }

    func add_content_types( wb:Workbook ) throws {
        let xml = document {
            node( "Types", attributes: [("xmlns", "http://schemas.openxmlformats.org/package/2006/content-types")] ) {
                node( "Default", attributes: [ ("Extension", "rels"), ("ContentType", "application/vnd.openxmlformats-package.relationships+xml") ] ) {}
                node( "Default", attributes: [ ("Extension", "xml"), ("ContentType", "application/xml") ] ) {}
                node( "Override", attributes: [ ("PartName", "/xl/workbook.xml"), ("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml") ] ) {}
                node( "Override", attributes: [ ("PartName", "/xl/styles.xml"), ("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml") ] ) {}
                for sh in wb.sheets {
                    node( "Override", attributes: [ ("PartName", "/xl/worksheets/sheet\(sh.id).xml"), ("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml") ] ) {}
                }
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
                        ("Target", "xl/workbook.xml")
                ] ) {}
            }
        }

        try add_data( path: "_rels/.rels", data: xml.string.data(using: .utf8)! )
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
        
        try add_data( path: "xl/workbook.xml", data: xml.string.data(using: .utf8)! )
    }
    
    
    func add_workbook_rels( wb:Workbook ) throws {
        let xml = document {
            node( "Relationships", attributes: [ ("xmlns","http://schemas.openxmlformats.org/package/2006/relationships") ] ) {
                for sh in wb.sheets {
                    node( "Relationship", attributes: [
                                            ("Id", "rId\(sh.id)"),
                                            ("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"),
                                            ("Target", "worksheets/sheet\(sh.id).xml"),
                    ] ) {}
                }
                node( "Relationship", attributes: [
                                        ("Id", "rIdStyles"),
                                        ("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"),
                                        ("Target", "styles.xml"),
                ] ) {}
            }
        }

        try add_data( path: "xl/_rels/workbook.xml.rels", data: xml.string.data(using: .utf8)! )
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
    /// Minimal stylesheet: the default style plus one style per number
    /// format the cells use (custom format ids start at 164)
    func add_styles_xml() throws {
        let xml = document {
            node( "styleSheet", attributes: [
                            ("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
                        ] ) {
                if !formats.isEmpty {
                    node( "numFmts", attributes: [ ("count", "\(formats.count)") ] ) {
                        for (i, f) in formats.enumerated() {
                            node( "numFmt", attributes: [ ("numFmtId", "\(164 + i)"), ("formatCode", f.code) ] ) {}
                        }
                    }
                }
                node( "fonts", attributes: [ ("count", "1") ] ) {
                    node( "font" ) {
                        node( "sz", attributes: [ ("val", "11") ] ) {}
                        node( "name", attributes: [ ("val", "Calibri") ] ) {}
                    }
                }
                node( "fills", attributes: [ ("count", "2") ] ) {
                    node( "fill" ) { node( "patternFill", attributes: [ ("patternType", "none") ] ) {} }
                    node( "fill" ) { node( "patternFill", attributes: [ ("patternType", "gray125") ] ) {} }
                }
                node( "borders", attributes: [ ("count", "1") ] ) {
                    node( "border" ) {
                        node( "left" ) {}
                        node( "right" ) {}
                        node( "top" ) {}
                        node( "bottom" ) {}
                        node( "diagonal" ) {}
                    }
                }
                node( "cellStyleXfs", attributes: [ ("count", "1") ] ) {
                    node( "xf", attributes: [ ("numFmtId", "0"), ("fontId", "0"), ("fillId", "0"), ("borderId", "0") ] ) {}
                }
                node( "cellXfs", attributes: [ ("count", "\(formats.count + 1)") ] ) {
                    node( "xf", attributes: [ ("numFmtId", "0"), ("fontId", "0"), ("fillId", "0"), ("borderId", "0"), ("xfId", "0") ] ) {}
                    for i in formats.indices {
                        node( "xf", attributes: [ ("numFmtId", "\(164 + i)"), ("fontId", "0"), ("fillId", "0"), ("borderId", "0"), ("xfId", "0"), ("applyNumberFormat", "1") ] ) {}
                    }
                }
                node( "cellStyles", attributes: [ ("count", "1") ] ) {
                    node( "cellStyle", attributes: [ ("name", "Normal"), ("xfId", "0"), ("builtinId", "0") ] ) {}
                }
            }
        }

        try add_data( path: "xl/styles.xml", data: xml.string.data(using: .utf8)! )
    }

    func cell_formats( wb:Workbook ) -> [ CellFormat ] {
        var seen = Set<CellFormat>()
        var list:[ CellFormat ] = []
        for sh in wb.sheets {
            for r in sh.rows {
                for c in r.cells {
                    if let f = c.format, seen.insert( f ).inserted { list.append( f ) }
                }
            }
        }
        return list
    }

    /// Excel serial date (1900 date system): days since 1899-12-30 plus the
    /// fraction of the day, from the wall-clock components alone — no time
    /// zone is involved. nil without year, month and day.
    static func excel_serial( _ comps:DateComponents ) -> Double? {
        guard let year = comps.year, let month = comps.month, let day = comps.day else { return nil }
        var utc = Calendar( identifier: .gregorian )
        utc.timeZone = TimeZone( identifier: "UTC" )!
        let wallClock = DateComponents( year: year, month: month, day: day,
                                        hour: comps.hour ?? 0, minute: comps.minute ?? 0,
                                        second: comps.second ?? 0, nanosecond: comps.nanosecond ?? 0 )
        guard let date  = utc.date( from: wallClock ),
              let epoch = utc.date( from: DateComponents( year: 1899, month: 12, day: 30 ) )
        else { return nil }
        return date.timeIntervalSince( epoch ) / 86_400
    }

    /// r, the value type and — for formatted cells — the style index
    func cell_attributes( _ c:Cell, type:Cell.ValueType? = nil ) -> [ XMLAttribute ] {
        var attributes:[ XMLAttribute ] = [ ( "r", c.reference ) ]
        if let type { attributes.append( ( "t", type.rawValue ) ) }
        if let f = c.format, let i = formats.firstIndex( of: f ) {
            attributes.append( ( "s", "\(i + 1)" ) )
        }
        return attributes
    }
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
    
    func is_numeric_value( _ v:Any ) -> Bool {
        switch v {
        case is Int, is Int8, is Int16, is Int32, is Int64,
             is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
             is Float, is Double, is Decimal: return true
        default: return false
        }
    }

    func add_sheet_xml( sheet:Sheet ) throws {

        let xml = document {
            node( "worksheet", attributes: [
                ("xmlns", "http://schemas.openxmlformats.org/spreadsheetml/2006/main" ),
                ("xmlns:r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships" )
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
                if !sheet.columnWidths.isEmpty {
                    node( "cols" ) {
                        for (col, width) in sheet.columnWidths.sorted( by: { $0.key < $1.key } ) {
                            node( "col", attributes: [
                                ("min", "\(col + 1)"),
                                ("max", "\(col + 1)"),
                                ("width", "\(width)"),
                                ("customWidth", "1")
                            ] ) {}
                        }
                    }
                }
                node( "sheetData" ) {
                    for r in sheet.rows {
                        node( "row", attributes: [ ( "r", "\(r.rowIndex + 1)" ) ] ) {
                            for c in r.cells {
                                if let v = c.value as? String {
                                    node( "c", attributes: cell_attributes( c, type: .inlineString ) ) {
                                        node( "is" ) { node( "t", value: v ) }
                                    }
                                }
                                else if let v = c.value as? Bool {
                                    node( "c", attributes: cell_attributes( c, type: .boolean ) ) {
                                        node( "v", value: v ? "1" : "0" )
                                    }
                                }
                                else if let v = c.value as? DateComponents, let serial = WorkbookFile.excel_serial( v ) {
                                    // A date is a number; its format makes it show as one
                                    node( "c", attributes: cell_attributes( c ) ) {
                                        node( "v", value: "\(serial)" )
                                    }
                                }
                                else if let v = c.value, is_numeric_value( v ) {
                                    node( "c", attributes: cell_attributes( c ) ) {
                                        node( "v", value: "\(v)" )
                                    }
                                }
                                else if let v = c.value {
                                    node( "c", attributes: cell_attributes( c, type: .inlineString ) ) {
                                        node( "is" ) { node( "t", value: "\(v)" ) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        try add_data( path: "xl/worksheets/sheet\(sheet.id).xml", data: xml.string.data(using: .utf8)! )
    }
}
