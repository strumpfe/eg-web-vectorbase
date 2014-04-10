=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

# $Id: ViewConfig.pm,v 1.132.2.1 2013-12-04 14:20:15 hr5 Exp $

package EnsEMBL::Web::ViewConfig;

use strict;

use EnsEMBL::Web::DBSQL::SampleMetaAdaptor;
use EnsEMBL::Web::Document::Table;

sub get_individual_metadata_summary {
  my $self = shift;
  
  if (!$self->{_individual_metadata_summary}) {
    my $sma = EnsEMBL::Web::DBSQL::SampleMetaAdaptor->new($self->hub);
    $self->{_individual_metadata_summary} = $sma->get_summary($self->hub->species);
  }
  
  return $self->{_individual_metadata_summary};
}

sub get_metadata_individuals {
  my ($self, $metadata_keyval_id) = @_;
  
  my $sma = EnsEMBL::Web::DBSQL::SampleMetaAdaptor->new($self->hub);     
  
  return $sma->get_individuals($self->hub->species, $metadata_keyval_id);
}

sub add_individual_selector {
  my ($self, $config) = @_;
  my $checkbox_name_template = $config->{checkbox_name_template} || '%s';
  my $checkbox_on_value      = $config->{checkbox_on_value} || 'on';  
  my $hub                    = $self->hub;
  my $species                = $hub->species;   
  my $summary                = $self->get_individual_metadata_summary;
  
  my $meta_table = EnsEMBL::Web::Document::Table->new([], [], { 
    data_table => 'no_col_toggle',
    exportable => 0,
  });
  
  $meta_table->code = 'individual_selector_meta';
  
  $meta_table->add_columns(   
    { key => 'biosample_group',  title => 'Group',       width => '10%' },  
    { key => 'meta_key',         title => 'Property',    width => '20%' },  
    { key => 'meta_val',         title => 'Value',       width => '40%' },
    { key => 'sample_count',     title => 'Samples',     width => '10%', sort => 'numeric' },
    { key => 'individual_count', title => 'Individuals', width => '10%', sort => 'numeric' },
    { key => 'checkbox',         title => '',            width => '2%'  },  
  );
  
  my %individual_groups;
      
  foreach my $row (@$summary) {
    my $checkbox;
    
    if ($row->{individual_count} <= 100) {
      my $group       = $row->{metadata_keyval_id};
      my $individuals = $self->get_metadata_individuals($row->{metadata_keyval_id});
      
      foreach my $i (@$individuals) {
        $individual_groups{$i} ||= [];
        push @{$individual_groups{$i}}, $group;
      }     
      
      $checkbox = sprintf (
        qq{<input type="checkbox" class="ins_group" name="ins_group_%s" value="on"%s />}, 
        $group,
        $self->get("ins_group_$group") eq 'on' ? ' checked' : ''
      )
    }
       
    $meta_table->add_row({ 
      biosample_group  => $row->{biosample_group},
      meta_key         => $row->{meta_key},
      meta_val         => $row->{meta_val},
      sample_count     => $row->{sample_count},
      individual_count => $row->{individual_count},
      checkbox         => $checkbox || '--',
    });
  }
 
  # Selected individuals
  
  my $variations = $self->species_defs->databases->{'DATABASE_VARIATION'};
  my @strains    = (@{$variations->{'DEFAULT_STRAINS'}}, @{$variations->{'DISPLAY_STRAINS'}});
  my %seen;

  my $individual_table = EnsEMBL::Web::Document::Table->new([], [], { 
    data_table => 'no_col_toggle',
    exportable => 0,
  });
  
  $individual_table->code = 'individual_selector_individual';
  
  $individual_table->add_columns(   
    { key => 'individual',  title => 'Individual',  width => '20%' },  
    { key => 'description', title => 'Description', width => '70%' },  
    { key => 'checkbox',    title => '',            width => '2%'  },  
  );

  foreach my $i (sort @strains) {
    if (!$seen{$i}++) {
      
      my $groups      = $individual_groups{$i};
      my $class       = $groups ? join(' ', map {"ins_group_$_"} @$groups ) : undef;
      
      my $checkbox = sprintf (
        qq{<input type="checkbox" class="%s" name="%s" value="%s"%s />}, 
        $class,
        sprintf( $checkbox_name_template, $i ),
        $checkbox_on_value,
        $self->get($i) eq $checkbox_on_value ? ' checked' : ''
      );
      
      $individual_table->add_row({ 
        individual => $i,
        description => $variations->{'DISPLAY_STRAIN_DESCRIPTION'}->{$i},
        checkbox   => $checkbox,
      });

    }
  }  

  # render
  
  $self->add_fieldset('Selected individuals')->append_child('div', { 
    inner_HTML => sprintf (
      qq{
        <div id="IndividualSelector" class="js_panel">
          <input type="hidden" class="subpanel_type" value="IndividualSelector" />
          <div style="text-align:right;margin-bottom:5px;"><a href="#" class="button">Select / deselect all</a></div>
          %s
        </div>
      },
      $individual_table->render,
    )
  });
  
  $self->add_fieldset('Individual metadata')->append_child('div', { 
    inner_HTML => sprintf (
      qq{
        <div id="IndividualMetaSelector" class="js_panel">
          <input type="hidden" class="subpanel_type" value="IndividualMetaSelector" />
          %s
        </div>
      },
      $meta_table->render,
    )
  });
}

1;
