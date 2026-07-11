-- Mirrors app13_ruby_FastApi's CardDecodeError hierarchy. Plain tables with an
-- `is_card_decode_error` marker rather than a class hierarchy — Lua has no
-- built-in exception types, `error()` can raise any value.

local CardDecodeError = {}

local function make_error(kind, fields)
  fields = fields or {}
  fields.is_card_decode_error = true
  fields.kind = kind
  return fields
end

function CardDecodeError.unrecognized_fields(scope, extra_keys)
  return make_error("UnrecognizedFields", {
    message = string.format("unrecognized key(s) in %s: %s", scope, table.concat(extra_keys, ", "))
  })
end

function CardDecodeError.missing_required_field(field_name)
  return make_error("MissingRequiredField", {
    message = "missing required field: " .. field_name
  })
end

function CardDecodeError.missing_curated_severity(card_id)
  return make_error("MissingCuratedSeverity", {
    card_id = card_id,
    message = "card " .. card_id .. " has a curation entry but no valid severity"
  })
end

function CardDecodeError.orphan_curation_entry(card_id, curation_file_name)
  return make_error("OrphanCurationEntry", {
    card_id = card_id,
    curation_file_name = curation_file_name,
    message = string.format("curation file %s references unknown card_id %s", curation_file_name, card_id)
  })
end

function CardDecodeError.unknown_reference(value, field, card_id)
  return make_error("UnknownReference", {
    value = value,
    field = field,
    card_id = card_id,
    message = string.format("card %s has unknown %s value: %s", card_id, field, value)
  })
end

return CardDecodeError
