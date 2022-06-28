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
    var blackList: [String] = []
    
    init(filePath: String?) throws {
        blackListFilePath = filePath
        blackList = try readBlackListFile()
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
            guard let yaml = try Yams.load(yaml: fileString) as? [String: Any] else {
                throw CoverageFilterError.filePathError
            }
            guard let blackList = yaml["blackList"] as? [String] else {
                throw CoverageFilterError.filePathError
            }
            return blackList
        } else {
            return []
        }
    }
    
    func isBlocked(_ filePath: String?) -> Bool {
        guard let filePath = filePath else {
            return false
        }

        for str in blackList {
            if filePath.contains(str) {
                return true
            }
        }
        
        return false
    }
    
}
