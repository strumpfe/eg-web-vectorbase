# $Id: PopulationImage.pm,v 1.3 2013-11-29 08:53:21 nl2 Exp $

package EnsEMBL::Web::ViewConfig::Transcript::PopulationImage;

use strict;

use EnsEMBL::Web::Constants;

use previous qw(init);

sub init {
  my $self = shift;
  my $summary = $self->get_individual_metadata_summary;
  my $defaults;
  
  $defaults->{"ins_group" . $_->{metadata_keyval_id}} = 'off' for @$summary;
  
  $self->PREV::init;
  $self->set_defaults($defaults);
}

sub form {
  my $self       = shift;
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'};
  my %options    = EnsEMBL::Web::Constants::VARIATION_OPTIONS;
  my %validation = %{$options{'variation'}};
  my %class      = %{$options{'class'}};
  my %type       = %{$options{'type'}};

## VB - selected individuals and metadata
  $self->add_individual_selector({
    checkbox_name_template  => 'opt_pop_%s',
    checkbox_on_value       => 'on',
  });
##

  # Add source selection
  $self->add_fieldset('Variation source');
  
  foreach (sort keys %{$self->hub->table_info('variation', 'source')->{'counts'}}) {
    my $name = 'opt_' . lc $_;
    $name    =~ s/\s+/_/g;
    
    $self->add_form_element({
      type  => 'CheckBox', 
      label => $_,
      name  => $name,
      value => 'on',
      raw   => 1
    });
  }
  
  # Add class selection
  $self->add_fieldset('Variation class');
  
  foreach (keys %class) {
    $self->add_form_element({
      type  => 'CheckBox',
      label => $class{$_}[1],
      name  => lc $_,
      value => 'on',
      raw   => 1
    });
  }
  
  # Add type selection
  $self->add_fieldset('Consequence type');
  
  foreach (keys %type) {
    $self->add_form_element({
      type  => 'CheckBox',
      label => $type{$_}[1],
      name  => lc $_,
      value => 'on',
      raw   => 1
    });
  }

  # Add selection
  $self->add_fieldset('Consequence options');
  
  $self->add_form_element({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Type of consequences to display',
    name   => 'consequence_format',
    values => [
      { value => 'label',   name => 'Sequence Ontology terms' },
      { value => 'display', name => 'Old Ensembl terms'       },
    ]
  });  
  
  # Add context selection
  $self->add_fieldset('Intron Context');

  $self->add_form_element({
    type   => 'DropDown',
    select => 'select',
    name   => 'context',
    label  => 'Intron Context',
    values => [
      { value => '20',   name => '20bp'         },
      { value => '50',   name => '50bp'         },
      { value => '100',  name => '100bp'        },
      { value => '200',  name => '200bp'        },
      { value => '500',  name => '500bp'        },
      { value => '1000', name => '1000bp'       },
      { value => '2000', name => '2000bp'       },
      { value => '5000', name => '5000bp'       },
      { value => 'FULL', name => 'Full Introns' }
    ]
  });

}

1;
