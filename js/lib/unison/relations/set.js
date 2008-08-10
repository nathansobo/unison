Unison.Relations.Set = function() {
  this.attributes = {};
}

$.extend(Unison.Relations.Set.prototype, {
  has_attribute: function(name, type) {
    this.attributes[name] = new Unison.Attribute  
  }
});