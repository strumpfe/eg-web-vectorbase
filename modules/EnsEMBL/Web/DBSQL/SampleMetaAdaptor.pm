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

package EnsEMBL::Web::DBSQL::SampleMetaAdaptor;

### A simple adaptor for Gareth's BioSamples metadata db

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;

sub new {
  my ($class, $hub) = @_;

    my $self = {
    'NAME' => $hub->species_defs->multidb->{'DATABASE_SAMPLE_META'}{'NAME'},
    'HOST' => $hub->species_defs->multidb->{'DATABASE_SAMPLE_META'}{'HOST'},
    'PORT' => $hub->species_defs->multidb->{'DATABASE_SAMPLE_META'}{'PORT'},
    'USER' => $hub->species_defs->multidb->{'DATABASE_SAMPLE_META'}{'USER'},
    'PASS' => $hub->species_defs->multidb->{'DATABASE_SAMPLE_META'}{'PASS'},
  };
  bless $self, $class;
  return $self;
}

sub db {
  my $self = shift;
  return unless $self->{'NAME'};
  $self->{'dbh'} ||= DBI->connect(
      "DBI:mysql:database=$self->{'NAME'};host=$self->{'HOST'};port=$self->{'PORT'}",
      $self->{'USER'}, "$self->{'PASS'}"
  );
  return $self->{'dbh'};
}

sub summary {
  my ($self, $species) = @_;
  return unless $self->db;
  
  my $summary = $self->db->selectcol_arrayref(
    qq{  
      SELECT sp.name, s.biosample_group, mk.meta_key, mk.meta_val, 
        COUNT(s.sample_id) AS sample_count, 
        COUNT(im.individual_metadata_id) AS individual_count
      FROM species sp, sample s, individual_metadata im, metadata_keyval mk
      WHERE s.species_id = sp.species_id
        AND im.individual_id = s.sample_id
        AND im.metadata_keyval_id = mk.metadata_keyval_id
        AND s.ensembl_individual_id IS NOT NULL
      GROUP BY s.species_id, im.metadata_keyval_id
      ORDER BY sp.name, s.biosample_group, mk.meta_key, mk.meta_val
    }, 
    { Slice => {} }
  );
  
  return $summary;
}

1;
