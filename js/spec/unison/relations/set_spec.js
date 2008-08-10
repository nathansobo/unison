require("/specs/spec_helper");


Screw.Unit(function() {
  describe("Unison.Relations.Set", function() {
    var set;

    before(function() {
      set = new Unison.Relations.Set("users");
      console.debug("hi");
    });

    describe("#has_attribute", function() {
      describe("when an Attribute with the same #name and #type has not been added", function() {
        it("adds an Attribute to the #attributes hash, keyed by its #name", function() {
          set.has_attribute("name", "string")
          expect(set.attributes).to(equal, {
            "name": new Unison.Attribute(set, "name", "string")
          });
        });
      });
    });
  });
});