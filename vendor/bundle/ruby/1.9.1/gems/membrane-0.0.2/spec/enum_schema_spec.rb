require "spec_helper"

describe Membrane::Schema::Enum do
  describe "#validate" do
    let (:int_schema) { Membrane::Schema::Class.new(Integer) }
    let (:str_schema) { Membrane::Schema::Class.new(String) }
    let (:enum_schema) { Membrane::Schema::Enum.new(int_schema, str_schema) }

    it "should return an error if none of the schemas validate" do
      expect_validation_failure(enum_schema, :sym, /doesn't validate/)
    end

    it "should return nil if any of the schemas validate" do
      enum_schema.validate("foo").should be_nil
    end
  end
end
