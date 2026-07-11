# frozen_string_literal: true

class CodeSample < Sequel::Model(:code_samples)
  many_to_one :mitigation, key: :mitigation_slug
end
