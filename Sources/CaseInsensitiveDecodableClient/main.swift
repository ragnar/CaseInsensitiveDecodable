import Foundation
import CaseInsensitiveDecodable

@CaseInsensitiveDecodable
enum TestingEnum: String {
    case first = "a"
    case second = "b"
}

do {
    let three = try JSONEncoder().encode("B")

    let decoded = try JSONDecoder().decode(TestingEnum.self, from: three)
    print("decoded", decoded)

} catch {
    print("error", error.localizedDescription)
}
