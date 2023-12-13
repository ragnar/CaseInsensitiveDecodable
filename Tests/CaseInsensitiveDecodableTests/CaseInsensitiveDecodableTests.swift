import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(CaseInsensitiveDecodableMacros)
import CaseInsensitiveDecodableMacros

let testMacros: [String: Macro.Type] = [
    "CaseInsensitiveDecodable": CaseInsensitiveDecodableMacro.self,
]
#endif

final class CaseInsensitiveDecodableTests: XCTestCase {
    func testThisMacro() throws {
#if canImport(CaseInsensitiveDecodableMacros)
        assertMacroExpansion(
            """
            @CaseInsensitiveDecodable
            public enum TestEnum: String {
                case first
                case second
            }

            """,
            expandedSource:
            """
            public enum TestEnum: String {
                case first
                case second
            }

            extension TestEnum: Decodable {
                public init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    let rawValue = try container.decode(String.self)

                    switch rawValue.lowercased() {
                    case Self.first.rawValue.lowercased():
                        self = .first
                    case Self.second.rawValue.lowercased():
                        self = .second
                    default:
                        throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Encoded payload not of an expected value"))
                    }
                }
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
