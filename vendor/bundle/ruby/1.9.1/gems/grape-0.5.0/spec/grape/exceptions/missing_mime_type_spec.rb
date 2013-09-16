# encoding: utf-8
require 'spec_helper'
describe Grape::Exceptions::MissingMimeType do
  describe "#message" do

    let(:error) do
      described_class.new("new_json")
    end

    it "contains the problem in the message" do
      error.message.should include(
        "missing mime type for new_json"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "or add your own with content_type :new_json, 'application/new_json' "
      )
    end
  end


end
