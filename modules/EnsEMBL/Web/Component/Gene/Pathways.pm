package EnsEMBL::Web::Component::Gene::Pathways;
use strict;
use Data::Dumper;

use base qw(EnsEMBL::Web::Component);

sub content {
  my $self          = shift;
  my $hub           = $self->hub;
  my $gene_id       = $hub->param('g');
  my @pathways      = @{ $self->object->Obj->get_all_DBEntries('KEGG') };
  my $prefix_lookup = {aga => 'AgaP', cqu => 'CpipJ', aag => 'AaeL'};
 
  my $table = $self->new_table(
    [
      { key => 'kegg_id',     title => 'KEGG ID',             align => 'left', sort => 'html' },
      { key => 'description', title => 'Pathway description', align => 'left', sort => 'string' },
    ], 
    [], 
    { 
      class      => 'no_col_toggle',
      data_table => 1, 
      exportable => 0,
    }
  );

  foreach my $pathway (sort {$a->display_id cmp $b->display_id} @pathways) {
    my $kegg_id        = $pathway->display_id;
    my ($kegg_prefix)  = $kegg_id =~ m/^([a-z]+)\d+$/i; # e.g. extract 'aga' from 'aga00010'
    my $species_prefix = $prefix_lookup->{$kegg_prefix};
    
    $table->add_row({
      kegg_id     => qq(<a href="http://www.kegg.jp/pathway/$kegg_id+${species_prefix}_${gene_id}%09orange">$kegg_id</a>),
      description => $pathway->description
    });
  }

  return $table->render;
}

1;