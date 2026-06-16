// Standard-library `Mockable` conformances. Defaults are the "empty"/zero value for
// each type, chosen to be predictable rather than realistic.

extension Int: Mockable { public static var mock: Int { 0 } }
extension Int8: Mockable { public static var mock: Int8 { 0 } }
extension Int16: Mockable { public static var mock: Int16 { 0 } }
extension Int32: Mockable { public static var mock: Int32 { 0 } }
extension Int64: Mockable { public static var mock: Int64 { 0 } }
extension UInt: Mockable { public static var mock: UInt { 0 } }
extension UInt8: Mockable { public static var mock: UInt8 { 0 } }
extension UInt16: Mockable { public static var mock: UInt16 { 0 } }
extension UInt32: Mockable { public static var mock: UInt32 { 0 } }
extension UInt64: Mockable { public static var mock: UInt64 { 0 } }
extension Double: Mockable { public static var mock: Double { 0 } }
extension Float: Mockable { public static var mock: Float { 0 } }

extension Bool: Mockable { public static var mock: Bool { false } }
extension String: Mockable { public static var mock: String { "" } }
extension Character: Mockable { public static var mock: Character { " " } }

// `nil` covers any optional property regardless of its wrapped type.
extension Optional: Mockable { public static var mock: Wrapped? { nil } }

extension Array: Mockable { public static var mock: [Element] { [] } }
extension ContiguousArray: Mockable { public static var mock: ContiguousArray<Element> { [] } }
extension Set: Mockable { public static var mock: Set<Element> { [] } }
extension Dictionary: Mockable { public static var mock: [Key: Value] { [:] } }
