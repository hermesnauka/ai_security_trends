package com.kotlinguard.data.cards

sealed class CardDecodeError(message: String) : Exception(message) {
    class MissingRequiredField(val field: String) : CardDecodeError("missing required field: $field")
    class OrphanCurationEntry(val cardId: String, val file: String) :
        CardDecodeError("curation entry '$cardId' in $file has no matching card in its deck's raw YAML")
    class MissingCuratedSeverity(val cardId: String) :
        CardDecodeError("card '$cardId' is on a technical-threat deck but has no curated severity")
    class UnknownReference(val value: String, val field: String, val cardId: String) :
        CardDecodeError("card '$cardId' references unknown $field value '$value' (not in the bundled allowlist)")
}
