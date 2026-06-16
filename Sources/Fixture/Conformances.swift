// Empty/zero defaults, chosen to be predictable rather than realistic.

extension Int: Fixture { public static var fixture: Int { 0 } }
extension Int8: Fixture { public static var fixture: Int8 { 0 } }
extension Int16: Fixture { public static var fixture: Int16 { 0 } }
extension Int32: Fixture { public static var fixture: Int32 { 0 } }
extension Int64: Fixture { public static var fixture: Int64 { 0 } }
extension UInt: Fixture { public static var fixture: UInt { 0 } }
extension UInt8: Fixture { public static var fixture: UInt8 { 0 } }
extension UInt16: Fixture { public static var fixture: UInt16 { 0 } }
extension UInt32: Fixture { public static var fixture: UInt32 { 0 } }
extension UInt64: Fixture { public static var fixture: UInt64 { 0 } }
extension Double: Fixture { public static var fixture: Double { 0 } }
extension Float: Fixture { public static var fixture: Float { 0 } }

extension Bool: Fixture { public static var fixture: Bool { false } }
extension String: Fixture { public static var fixture: String { "" } }
extension Character: Fixture { public static var fixture: Character { " " } }

extension Optional: Fixture { public static var fixture: Wrapped? { nil } }

extension Array: Fixture { public static var fixture: [Element] { [] } }
extension ContiguousArray: Fixture { public static var fixture: ContiguousArray<Element> { [] } }
extension Set: Fixture { public static var fixture: Set<Element> { [] } }
extension Dictionary: Fixture { public static var fixture: [Key: Value] { [:] } }
