package EnsEMBL::Web::Configuration::Search;
use strict;

sub modify_tree {
  my $self = shift;
  $self->delete_node('Results');
}
1;
