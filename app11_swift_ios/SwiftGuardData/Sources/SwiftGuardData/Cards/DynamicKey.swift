/// A `CodingKey` that can represent any string key at all — used only to
/// enumerate `container.allKeys` for the unknown-key check in D-06; never
/// used to actually decode a value (that always goes through a second,
/// strictly-typed keyed container).
struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
