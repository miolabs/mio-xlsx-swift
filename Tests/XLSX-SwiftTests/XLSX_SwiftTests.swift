import XCTest
@testable import XLSX_Swift

enum TestError : Error
{
    case invalidPath
    case readTestDataFail
}

final class XLSX_SwiftTests: XCTestCase {
    
    func isXcodeTestEnvironment() -> Bool {
        let arg0 = ProcessInfo.processInfo.arguments[0]
        // Use arg0.hasSuffix("/usr/bin/xctest") for command line environment
        return arg0.hasSuffix("/Xcode/Agents/xctest")
    }
    
    func bundleURL( ) throws -> URL {
        let testBundle = Bundle( for: type( of: self ) )
        var resource_url: URL
        
        if isXcodeTestEnvironment() { // test via Xcode
            resource_url = testBundle.bundleURL
                .appendingPathComponent( "Contents", isDirectory: true )
                .appendingPathComponent( "Resources", isDirectory: true )
                .appendingPathComponent( "XLSX-Swift_XLSX-SwiftTests.bundle", isDirectory: true )
                .appendingPathComponent( "Contents", isDirectory: true )
                .appendingPathComponent( "Resources", isDirectory: true )
        }
        else {
            guard let packagePath = ProcessInfo.processInfo.environment["PWD"] else { throw TestError.invalidPath }
            let packageUrl = URL(fileURLWithPath: packagePath)
            resource_url = packageUrl
                .appendingPathComponent(".build", isDirectory: true)
                .appendingPathComponent("TestResources", isDirectory: true)
        }
        
        return resource_url
    }
    
    func loadTestData() throws -> Data {
        let resource_url = try bundleURL()
        
        let data = FileManager.default.contents( atPath: resource_url.appendingPathComponent("test.xlsx").path() )
        if data == nil { throw TestError.readTestDataFail }
        
        return data!
    }
    
    func testWorkbookFromData() throws {
        let data = try loadTestData()
        
        let wb = try Workbook(data: data)
        XCTAssertNotNil( wb )
    }
    
    func testWorkbookSheet() throws {
        let data = try loadTestData()
        
        let wb = try Workbook(data: data)
        XCTAssertNotNil( wb )
        
        let sh = wb.sheets.first
        XCTAssertNotNil( sh )
    }

    func testSheetName() throws {
        let data = try loadTestData()
        
        let wb = try Workbook(data: data)
        XCTAssertNotNil( wb )
        
        let sh = wb.sheets.first
        XCTAssertNotNil( sh )
        
        XCTAssert( sh!.name == "Sheet 1" )
    }
    
    func testContent() throws {
        let data = try loadTestData()
        
        let wb = try Workbook(data: data)
        XCTAssertNotNil( wb )
        
        let sh = wb.sheets.first
        XCTAssertNotNil( sh )
                
        XCTAssert( sh!.rows.count > 1 )
        let r0 = sh!.rows[0]
        
        XCTAssert( r0.cells.count > 0 )
        let c0 = r0.cells[0]
        
        XCTAssert( c0.value as? String == "Table 1" )
                
        let r1 = sh!.rows[1]
        
        XCTAssert( r1.cells.count > 0 )
        let c1 = r1.cells[0]
        
        XCTAssert( c1.value as? String == "HI" )
    }
    
    func testSheetSubscript() throws {
        
        let data = try loadTestData()
        
        let wb = try Workbook(data: data)
        XCTAssertNotNil( wb )
        
        let sh = wb.sheets.first
        XCTAssertNotNil( sh )
        
        let v1 = sh![ "A1" ]
        XCTAssert( v1 as? String == "Table 1" )
        
        let v2 = sh![ "A2" ]
        XCTAssert( v2 as? String == "HI" )
    }
    
    func testCreateWorkbook() throws {

        let wb = Workbook( )
        let sh = wb.addWorksheet()

        sh.write( value: "TEST", row: 1, col: 1 )
        sh.write( value: 42, row: 2, col: 0 )
        sh.write( value: 3.14, row: 2, col: 1 )

        let sh2 = wb.addWorksheet( withName: "Second" )
        sh2.write( value: "Another sheet", row: 0, col: 0 )

        try wb.save( toFileURL: bundleURL().appendingPathComponent("output.xlsx" ) )
    }

    func testWriteReadRoundTrip() throws {

        let wb = Workbook( )
        let sh = wb.addWorksheet( withName: "My Sheet" )

        sh.write( value: "TEST", row: 1, col: 1 )
        sh.write( value: "Hello", row: 0, col: 0 )
        sh.write( value: 42, row: 2, col: 2 )
        sh.write( value: 3.14, row: 3, col: 0 )

        let data = try wb.save()
        XCTAssertNotNil( data )

        let wb2 = try Workbook( data: data! )
        let sh2 = wb2.sheets.first
        XCTAssertNotNil( sh2 )
        XCTAssert( sh2!.name == "My Sheet" )

        XCTAssert( sh2![ "A1" ] as? String == "Hello" )
        XCTAssert( sh2![ "B2" ] as? String == "TEST" )
        XCTAssert( sh2![ "C3" ] as? String == "42" )
        XCTAssert( sh2![ "A4" ] as? String == "3.14" )
    }

    func testColumnReferences() throws {
        XCTAssert( Cell.reference( byColumnIndex: 0 ) == "A" )
        XCTAssert( Cell.reference( byColumnIndex: 25 ) == "Z" )
        XCTAssert( Cell.reference( byColumnIndex: 26 ) == "AA" )
        XCTAssert( Cell.reference( byColumnIndex: 27 ) == "AB" )
        XCTAssert( Cell.reference( byColumnIndex: 51 ) == "AZ" )
        XCTAssert( Cell.reference( byColumnIndex: 52 ) == "BA" )
        XCTAssert( Cell.reference( byColumnIndex: 701 ) == "ZZ" )
        XCTAssert( Cell.reference( byColumnIndex: 702 ) == "AAA" )

        for i in [ 0, 25, 26, 27, 51, 52, 701, 702 ] {
            let index = UInt16( i )
            XCTAssert( Cell.index( byColumnReference: Cell.reference( byColumnIndex: index ) ) == index )
        }
    }

}
