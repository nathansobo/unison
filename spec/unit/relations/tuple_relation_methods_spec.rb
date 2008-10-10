require File.expand_path("#{File.dirname(__FILE__)}/../../unison_spec_helper")

module Unison
  module Relations
    describe TupleRelationMethods do
      attr_reader :object_with_module
      before do
        @object_with_module = Object.new
        object_with_module.extend(TupleRelationMethods)
      end

      describe "#target_class" do
        attr_reader :expected_target_class, :models_module, :original_models_module
        before do
          publicize object_with_module, :target_class
          stub(object_with_module).class_name {"Foo"}
          @models_module = Module.new
          @models_module.const_set("Foo", Class.new)
          @original_models_module = Unison.models_module
          Unison.models_module = models_module
        end
        
        after do
          Unison.models_module = original_models_module
        end

        it "looks up the #class_name in Unison.models_module" do
          object_with_module.target_class.should == models_module.const_get("Foo")
        end
      end
    end
  end
end