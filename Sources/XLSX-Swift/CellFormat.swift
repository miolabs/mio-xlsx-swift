//
//  CellFormat.swift
//
//
//  Created by Javier Segura Perez on 5/3/24.
//

import Foundation

/// Excel number format of a cell (a format code such as "yyyy-mm-dd").
/// Cells written with one get their own style in styles.xml; all other
/// cells keep the default style.
public final class CellFormat : Hashable, Sendable
{
    public let code: String

    public init( code: String ) { self.code = code }

    public static let date     = CellFormat( code: "yyyy-mm-dd" )
    public static let dateTime = CellFormat( code: "yyyy-mm-dd hh:mm:ss" )

    public static func == ( lhs: CellFormat, rhs: CellFormat ) -> Bool { lhs.code == rhs.code }
    public func hash( into hasher: inout Hasher ) { hasher.combine( code ) }
}
