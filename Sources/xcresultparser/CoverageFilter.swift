//
//  CoverageFilter.swift
//  XcresultparserLib
//
//  Created by LinFan on 2022/6/27.
//

import Foundation
import Yams

enum CoverageFilterError: Error {
    case filePathError
}

class CoverageFilter {
    var blackListFilePath: String?
    var blackListRegex: String?
    var blackList: [String]
    
    init(filePath: String?, regex: String?) throws {
        blackListFilePath = filePath
        blackListRegex = regex
        let b = try readBlackListFile()
        blackList = b
    }
    
    func readBlackListFile() throws -> [String] {
        if let blackListFilePath = blackListFilePath, blackListFilePath.count > 0 {
            let fileUrl = URL.init(fileURLWithPath: blackListFilePath)
            guard let fileData = FileManager.default.contents(atPath: fileUrl.path) else {
                throw CoverageFilterError.filePathError
            }
            guard let fileString = String(data: fileData, encoding: .utf8) else {
                throw CoverageFilterError.filePathError
            }
            guard let yaml = try Yams.load(yaml: fileString) as? [String: String] else {
                throw CoverageFilterError.filePathError
            }
            return []
        } else {
            return []
        }
    }
    
    func isBlocked(_ filePath: String?) -> Bool {
        guard let filePath = filePath else {
            return false
        }

        if let blackListFilePath = blackListFilePath, blackListFilePath.count > 0 {
            let fileUrl = URL.init(fileURLWithPath: blackListFilePath)
            
        } else {
            return false
        }
        
        if let blackListRegex = blackListRegex {
            
        } else {
            return false
        }
        return false
    }
    
}
