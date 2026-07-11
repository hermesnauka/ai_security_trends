# frozen_string_literal: true

class Framework < Sequel::Model(:frameworks)
  unrestrict_primary_key

  one_to_many :threats, key: :framework_code

  def validate
    super
    errors.add(:code, "is required") if code.nil? || code.empty?
    errors.add(:name, "is required") if name.nil? || name.empty?
  end
end
