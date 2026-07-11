/// D-06/SR-09-equivalent: thrown for any of an unknown top-level/suit/card
/// YAML key, a curation or translation entry whose card_id is absent from
/// the raw deck (AC-19-equivalent), or a technical-threat card missing a
/// curated severity. Ingestion of that deck aborts entirely.
public enum CardDecodeError: Error, Equatable {
    case unrecognizedFields(Set<String>)
    case missingRequiredField(String)
    case missingCuratedSeverity(cardId: String)
    case orphanCurationEntry(cardId: String, file: String)
    case unknownReference(value: String, field: String, cardId: String)
}
