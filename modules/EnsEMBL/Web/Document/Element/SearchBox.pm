package EnsEMBL::Web::Document::Element::SearchBox;

### Generates small search box (used in top left corner of pages)

use strict;

sub content {
    my $self = shift;
    my $species_defs = $self->species_defs;
    my $search_url = $species_defs->ENSEMBL_WEB_ROOT . "Multi/psychic";
    
    return qq{
      <div id="block-search-form">
        <form id="vb-search" method="get" action="$search_url">
          <input name="site" value="vectorbase" type="hidden">
          <input class="vb-search-keywords" name="q" value="" size="25" type="text" maxlength="128" placeholder="Search VectorBase" title="Enter the terms you wish to search for." />
          <input class="vb-search-submit" value="Go" type="submit" />
        </form>
        <p><a href="/search/site/%2A?as=True">Advanced search</a></p>
      </div>
    };
}

1;
