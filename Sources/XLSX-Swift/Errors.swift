//
//  Errors.swift
//
//
//  Created by Javier Segura Perez on 6/3/24.
//

import Foundation

public enum XLSXError : Error
{
    case workbookFileNotFound( file:String )
    case invalidFileFormat
}
