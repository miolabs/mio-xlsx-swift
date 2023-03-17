//
//  File.swift
//  
//
//  Created by Javier Segura Perez on 28/2/23.
//

import Foundation
import ZIPFoundation

var xlsx_queue = DispatchQueue( label: "xlsx_queue" )

final class XLSXData
{
    let data:Data
    var archive:Archive? = nil
    
    init( withData data: Data ) { self.data = data }
        
    func extract( filePath:String ) throws -> Data? {
        if archive == nil {
            if data[0...1] == "PK".data(using: .utf8 ) {
                // Decompress de data
                archive = Archive( data: data, accessMode: .read )
            }
        }
        
        guard let entry = archive?[ filePath ] else { return nil }
        
        let progress = Progress( totalUnitCount: 1)
        var d = Data()
        
        let semp = DispatchSemaphore(value: 0)
        
        xlsx_queue.async {
            do {
                _ = try self.archive?.extract( entry, progress: nil, consumer: { data in
                    d.append( data )
                } )
            }
            catch {
                
            }
            
            if progress.isFinished { semp.signal() }
        }
        
        semp.wait()
        
        return d
    }
    
    public func fileByPath( path: String ) throws -> Data? {
        return try extract(filePath: path )
    }
}
