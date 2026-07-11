# frozen_string_literal: true

module CardDecodeError
  class Base < StandardError; end

  class UnrecognizedFields < Base
    def initialize(fields, context)
      super("unrecognized field(s) in #{context}: #{fields.join(', ')}")
    end
  end

  class MissingRequiredField < Base
    def initialize(field)
      super("missing required field: #{field}")
    end
  end

  class MissingCuratedSeverity < Base
    attr_reader :card_id

    def initialize(card_id)
      @card_id = card_id
      super("card '#{card_id}' is on a technical-threat deck but has no curated severity")
    end
  end

  class OrphanCurationEntry < Base
    attr_reader :card_id, :file

    def initialize(card_id, file)
      @card_id = card_id
      @file = file
      super("curation entry '#{card_id}' in #{file} has no matching card in its deck's raw YAML")
    end
  end

  class UnknownReference < Base
    attr_reader :value, :field, :card_id

    def initialize(value, field, card_id)
      @value = value
      @field = field
      @card_id = card_id
      super("card '#{card_id}' references unknown #{field} value '#{value}' (not in the bundled allowlist)")
    end
  end
end
