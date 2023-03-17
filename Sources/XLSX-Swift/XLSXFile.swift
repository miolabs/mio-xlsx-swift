// XLSXFile.swift

import Foundation

public final class XLSXFile
{
    var contents: Data
    
    public init() {
        // TODO: Init for writing
        contents = Data()
    }
    
    public init( withData data: Data ) {
        contents = data
    }
    
    deinit {
        print( "NO SHIT ")
    }
    
    var wb:Workbook?
    
    public func parse() throws -> Workbook
    {
        let data = XLSXData(withData: contents )
        
        wb = Workbook( data: data )
                
        try wb!.parse()
        try wb!.sharedStrings.parse()

        for name in wb!.sheetNames {
            let sh = Sheet( workbook: wb! )
            try sh.parse( name: name )
            wb!.sheets.append( sh )
        }
             
        return wb!

    }
}
