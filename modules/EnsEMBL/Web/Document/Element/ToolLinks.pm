package EnsEMBL::Web::Document::Element::ToolLinks;

### Generates links to site tools - BLAST, help, login, etc (currently in masthead)

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub logins    :lvalue { $_[0]{'logins'};   }
sub blast     :lvalue { $_[0]{'blast'};   }
sub biomart   :lvalue { $_[0]{'biomart'};   }

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $species = $hub->species;
  $species = !$species || $species eq 'Multi' || $species eq 'common' ? 'Multi' : $species;
  my @links;

  push @links, qq{<a class="constant" href="/about">About</a>};
  push @links,   '<a class="constant" href="/navigation/downloads">Downloads</a>';
  push @links,   '<a class="constant" href="/navigation/tools">Tools </a>';
  push @links,   '<a class="constant" href="/navigation/data">Data</a>';
  push @links,   '<a class="constant" href="/navigation/help">Help</a>';
  push @links,   '<a class="constant" href="/navigation/community">Community</a>';
  push @links,   '<a class="constant" href="/contact">Contact us</a>';
  push @links,   '<a class="constant" href="/ensembl_tools.html">Browser Tools</a>';
  push @links,   '<a class="constant" href="/info/index.html">Browser Docs</a>';

  my $last  = pop @links;
  my $tools = join '', map "<li>$_</li>", @links;

  return qq{
    <ul class="tools">$tools<li class="last">$last</li></ul>
    <div class="more">
      <a href="#">More...</a>
    </div>
  };
}

sub init {
    my $self         = shift;
    my $species_defs = $self->species_defs;
    $self->logins    = $species_defs->ENSEMBL_LOGINS;
    $self->blast     = $species_defs->ENSEMBL_BLAST_ENABLED;
    $self->biomart   = $species_defs->ENSEMBL_MART_ENABLED;
}

1;

  
