//
//  main.swift
//  xcresultparser
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import ArgumentParser
import XcresultparserLib

private let marketingVersion = "1.1.5"

struct xcresultparser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "xcresultparser \(marketingVersion)\nInterpret binary .xcresult files and print summary in different formats: txt, xml, html or colored cli output."
    )
    
    @Option(name: .shortAndLong, help: "The output format. It can be either 'txt', 'cli', 'html', 'md' or 'xml'. In case of 'xml' JUnit format for test results and generic format (Sonarqube) for coverage data is used.")
    var outputFormat: String?
    
    @Option(name: .shortAndLong, help: "The name of the project root. If present paths and urls are relative to the specified directory.")
    var projectRoot: String?
    
    @Option(name: [.customShort("t"), .customLong("coverage-targets")], help: "Specify which targets to calculate coverage from")
    var coverageTargets: [String] = []

    @Option(name: .shortAndLong, help: "The fields in the summary. Default is all: errors|warnings|analyzerWarnings|tests|failed|skipped")
    var summaryFields: String?
    
    @Option(name: .shortAndLong, help: "The blackList file path. A yaml file of paths, key value is 'blackList' ")
    var blackListFile: String?
    
    @Option(name: .shortAndLong, help: "File paths regex to filter files")
    var regexForBlackList: String?
    
    @Flag(name: .shortAndLong, help: "Whether to print coverage data.")
    var coverage: Int
    
    @Flag(name: .shortAndLong, help: "Whether to print test results.")
    var noTestResult: Int

    @Flag(name: .shortAndLong, help: "Whether to only print failed tests.")
    var failedTestsOnly: Int
    
    @Flag(name: .shortAndLong, help: "Quiet. Don't print status output.")
    var quiet: Int

    @Flag(name: .shortAndLong, help: "Show version number.")
    var version: Int
    
    @Argument(help: "The path to the .xcresult file.")
    var xcresultFile: [String]
    
    mutating func run() throws {
        guard version != 1 else {
            print(marketingVersion)
            return
        }
        guard xcresultFile.count > 0 else {
            throw ParseError.argumentError
        }
        let mergeXML = XMLElement(name: "coverage")
        mergeXML.addAttribute(XMLNode.attribute(withName: "version", stringValue:"1") as! XMLNode)
        for xcresult in xcresultFile {
            if format == .xml {
                if coverage == 1 {
                    let addXML = try outputSonarXML(for: xcresult)
                    mergeXML.addChild(addXML)
                } else {
                    try outputJUnitXML(for: xcresult)
                }
            } else {
                try outputDescription(for: xcresult)
            }
        }
        writeToStdOut((mergeXML.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])))
    }
    
    private func outputSonarXML(for xcresult: String) throws -> XMLElement {
        guard let converter = CoverageConverter(with: URL(fileURLWithPath: xcresult), projectRoot: projectRoot ?? "") else {
            throw ParseError.argumentError
        }
        let (rslt, rawXML) = try converter.xmlString(quiet: quiet == 1)
        writeToStdOut(rslt)
        return rawXML
    }
    
    private func outputJUnitXML(for xcresult: String) throws {
        guard let junitXML = JunitXML(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            format: .sonar
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOut(junitXML.xmlString)
    }
    
    private func outputDescription(for xcresult: String) throws {
        guard let resultParser = XCResultFormatter(
            with: URL(fileURLWithPath: xcresult),
            formatter: outputFormatter,
            coverageTargets: coverageTargets,
            failedTestsOnly: (failedTestsOnly == 1),
            summaryFields: summaryFields ?? "errors|warnings|analyzerWarnings|tests|failed|skipped"
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOutLn(resultParser.documentPrefix(title: "XCResults"))
        if noTestResult == 0 {
            writeToStdOutLn(resultParser.summary)
            writeToStdOutLn(resultParser.divider)
            writeToStdOutLn(resultParser.testDetails)
        }
        if coverage == 1 {
            writeToStdOutLn(resultParser.coverageDetails)
        }
        writeToStdOutLn(resultParser.documentSuffix)
    }
    
    private var format: OutputFormat {
        return OutputFormat(string: outputFormat)
    }
    
    private var outputFormatter: XCResultFormatting {
        switch format {
        case .cli:
            return CLIResultFormatter()
        case .html:
            return HTMLResultFormatter()
        case .txt:
            return TextResultFormatter()
        case .xml:
            // outputFormatter is not used in case of .xml
            return TextResultFormatter()
        case .md:
            return MDResultFormatter()
        }
    }
}

enum ParseError: Error {
    case argumentError
}

xcresultparser.main()

