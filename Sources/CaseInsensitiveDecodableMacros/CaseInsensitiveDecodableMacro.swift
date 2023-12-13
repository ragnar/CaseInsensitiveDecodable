import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum CaseInsensitiveDecodableError: CustomStringConvertible, Error {
    case onlyApplicableToEnum
    case mustInheritFromString

    var description: String {
        return switch self {
            case .onlyApplicableToEnum: "@CaseInsensitiveDecodable can only be applied to enums"
            case .mustInheritFromString: "@CaseInsensitiveDecodable must inherit String"
        }
    }
}

public struct CaseInsensitiveDecodableMacro:  ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw CaseInsensitiveDecodableError.onlyApplicableToEnum
        }

        guard 
            let inheritTypes = enumDecl.inheritanceClause?.inheritedTypes.compactMap({ $0.as(InheritedTypeSyntax.self)?.type.as(IdentifierTypeSyntax.self)?.name.text }),
            inheritTypes.contains("String")
        else {
            throw CaseInsensitiveDecodableError.mustInheritFromString
        }

        var accessLevel: String {
            guard let accessLevel = enumDecl.modifiers.first?.name.text else {
                return ""
            }
            
            return "\(accessLevel) "
        }

        let caseDecl = enumDecl.memberBlock.members .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let initMethod = Self.generateInitialCode(accessLevel: accessLevel, casesDecl: caseDecl)
        let decl: DeclSyntax =
        """
        extension \(type.trimmed): Decodable {
        \(initMethod)
        }
        """

        guard let extensionDecl = decl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [extensionDecl]
    }

    public static func generateInitialCode(accessLevel: String, casesDecl: [EnumCaseDeclSyntax]) -> SyntaxNodeString {
        var initialCode: String =
                        """
                        \(accessLevel)init(from decoder: Decoder) throws {
                            let container = try decoder.singleValueContainer()
                            let rawValue = try container.decode(String.self)

                            switch rawValue.lowercased() {
                        """

        casesDecl.forEach { caseDecl in
            guard let caseName = caseDecl.elements.first?.name.text else {
                return
            }
            initialCode += "case Self.\(caseName).rawValue.lowercased(): self = .\(caseName)\n"
        }

        initialCode += """
                default: throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Encoded payload not of an expected value"))
                """

        initialCode += "\n}\n}"

        return SyntaxNodeString(stringLiteral: initialCode)
    }
}

@main
struct CaseInsensitiveDecodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CaseInsensitiveDecodableMacro.self,
    ]
}
