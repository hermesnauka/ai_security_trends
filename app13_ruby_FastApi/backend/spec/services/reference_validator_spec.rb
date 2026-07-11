# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ReferenceValidator do
  subject(:validator) { described_class.new(seeds_root: SEEDS_ROOT) }

  it "accepts a known OWASP ref" do
    expect { validator.assert_owasp_refs_valid!(["A03:2021"], "TEST") }.not_to raise_error
  end

  it "accepts a known MITRE ATLAS ref" do
    expect { validator.assert_mitre_refs_valid!(["AML.T0051"], "TEST") }.not_to raise_error
  end

  it "rejects an unknown OWASP ref" do
    expect { validator.assert_owasp_refs_valid!(["A99:2099"], "TEST") }
      .to raise_error(CardDecodeError::UnknownReference) do |error|
        expect(error.value).to eq("A99:2099")
        expect(error.field).to eq("owasp_refs")
        expect(error.card_id).to eq("TEST")
      end
  end

  it "rejects an unknown MITRE ref" do
    expect { validator.assert_mitre_refs_valid!(["AML.T9999"], "TEST") }
      .to raise_error(CardDecodeError::UnknownReference)
  end

  it "never raises for an empty refs list" do
    expect { validator.assert_owasp_refs_valid!([], "TEST") }.not_to raise_error
    expect { validator.assert_mitre_refs_valid!([], "TEST") }.not_to raise_error
  end
end
