Ensembl.Panel.ZMenu = Ensembl.Panel.ZMenu.extend({

  // revert to original Ensembl behaviour 
  populateNoAjax: function (force) {
    var oldest = Ensembl.Panel.ZMenu.ancestor;
    while (oldest.ancestor && typeof oldest.ancestor.prototype.populateNoAjax === 'function') {
      oldest = oldest.ancestor;
    }
    return oldest.prototype.populateNoAjax.apply(this, arguments);
  }
  
}, { template: Ensembl.Panel.ZMenu.template });
