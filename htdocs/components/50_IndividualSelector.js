Ensembl.Panel.IndividualSelector = Ensembl.Panel.extend({
  
  constructor: function (id, params) {
    this.base.apply(this, arguments);
  },
  
  init: function () {
    this.base.apply(this, arguments);
    var panel = this;

    $('input[type=checkbox].ins_group', panel.el).click( function() {
      panel.updateSelection(this.name, this.checked);
    });
  },
  
  updateSelection: function(groupName, groupChecked) {
    var panel = this;

    // update the specified group
    $('input[type=checkbox].' + groupName).each(function(){ 
      this.checked = groupChecked; 
    }); 
    
    // re-tick individuals in each selected group
    $('input[type=checkbox].ins_group:checked', panel.el).each(function(){
        var groupName = this.name;
        $('input[type=checkbox].' + groupName).each(function(){ 
          this.checked = true; 
        }); 
    });
    
    // check total        
    var total = $('input[type=checkbox].ins_individual:checked').length;
    
    if (total > 100) {
      alert(
        'Selecting large groups of individuals may cause this view to become unresponsive or fail - 100 individuals is the suggested maximum.' +
        '\n\nYou have selected ' + total + ' individuals.'
      );
    }
  }
});
  