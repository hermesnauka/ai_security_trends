# frozen_string_literal: true

class ContentHash < Sequel::Model(:content_hashes)
  unrestrict_primary_key
end
