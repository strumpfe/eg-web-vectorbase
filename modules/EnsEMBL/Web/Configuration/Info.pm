package EnsEMBL::Web::Configuration::Info;

use strict;

sub modify_tree {
  my $self  = shift;
  my $species_defs   = $self->hub->species_defs;

  my $sample_data  = $species_defs->SAMPLE_DATA;
  $self->delete_node('Gene') unless $sample_data->{'GENE_PARAM'};
  $self->delete_node('Transcript') unless $sample_data->{'TRANSCRIPT_PARAM'};
  
  $self->delete_node('WhatsNew');
}

1;