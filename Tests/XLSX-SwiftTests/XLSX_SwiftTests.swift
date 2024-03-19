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
                        
        try wb.save( toFileURL: bundleURL().appendingPathComponent("output.xlsx" ) )
    }

}
