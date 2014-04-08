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
  
  my $table = EnsEMBL::Web::Document::Table->new([], [], { 
    class => 'no_col_toggle data_table ss autocenter',
  });
  
  $table->code = 'biosamples'; # is this sufficent?
  
  $table->add_columns(   
    { key => 'biosample_group',  title => 'Group',       width => '10%' },  
    { key => 'meta_key',         title => 'Property',    width => '20%' },  
    { key => 'meta_val',         title => 'Value',       width => '40%' },
    { key => 'sample_count',     title => 'Samples',     width => '10%' },
    { key => 'individual_count', title => 'Individuals', width => '10%' },
    { key => 'checkbox',         title => '',            width => '10%' },  
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
       
    $table->add_row({ 
      biosample_group  => $row->{biosample_group},
      meta_key         => $row->{meta_key},
      meta_val         => $row->{meta_val},
      sample_count     => $row->{sample_count},
      individual_count => $row->{individual_count},
      checkbox         => $checkbox || '--',
    });
  }
 
  # Selected individuals
  
  my $fs            = $self->add_fieldset('Selected individuals');
  my $variations    = $self->species_defs->databases->{'DATABASE_VARIATION'};
  my @strains       = (@{$variations->{'DEFAULT_STRAINS'}}, @{$variations->{'DISPLAY_STRAINS'}});
  my %seen;
   
  foreach my $i (sort @strains) {
    if (!$seen{$i}++) {
      
      my $groups = $individual_groups{$i};
      my $class  = $groups ? join(' ', map {"ins_group_$_"} @$groups ) : undef;
      
      $fs->add_field({ 
        type    => 'CheckBox', 
        label   => $i,
        name    => sprintf( $checkbox_name_template, $i ),
        value   => $checkbox_on_value, 
        raw     => 1,
        checked => $self->get($i) eq $checkbox_on_value ? 1 : 0,
        class   => $class,
      });
      
      $self->{'labels'}{$i} ||= $i;
    }
  }  
  
  # Individuals metadata
    
  $self->add_fieldset('Individual metadata')->append_child('div', { 
    inner_HTML => sprintf (
      qq{
        <div id="IndividualSelector" class="js_panel">
          <input type="hidden" class="subpanel_type" value="IndividualSelector" />
          %s
        </div>
      },
      $table->render,
    )
  });
}

1;
