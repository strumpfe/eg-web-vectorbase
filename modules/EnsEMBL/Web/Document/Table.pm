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

# $Id: Table.pm,v 1.35 2013-11-28 10:53:32 sb23 Exp $

package EnsEMBL::Web::Document::Table;

use strict;

# Returns a hidden input used to configure the sorting options for a javascript data table
sub data_table_config {
  my $self      = shift;
  my $code      = $self->code;
  my $col_count = scalar @{$self->{'columns'}};
  
  return unless $code && $col_count;
  
  my $i              = 0;
  my %columns        = map { $_->{'key'} => $i++ } @{$self->{'columns'}};
  my $session_data   = $self->session ? $self->session->get_data(type => 'data_table', code => $code) : {};
  my $sorting        = $session_data->{'sorting'} ?        from_json($session_data->{'sorting'})        : $self->{'options'}{'sorting'}        || [];
  my $hidden         = $session_data->{'hidden_columns'} ? from_json($session_data->{'hidden_columns'}) : $self->{'options'}{'hidden_columns'} || [];
  my $default_hidden = $self->{'options'}{'hidden_columns'} ? $self->jsonify({ map { $_ => 1 } @{$self->{'options'}{'hidden_columns'}} }) : '';
     $default_hidden =~ s/"/'/g;
  my $config         = qq{<input type="hidden" name="code" value="$code" />};
  my $sort           = [];
  
  foreach (@$sorting) {
    my ($col, $dir) = split / /;
    $col = $columns{$col} unless $col =~ /^\d+$/ && $col < $col_count;
    push @$sort, [ $col, $dir ] if defined $col;
  }
  
  if (scalar @$sort) {
    (my $aaSorting = $self->jsonify($sort)) =~ s/"/'/g;
    $config .= qq{<input type="hidden" name="aaSorting" value="$aaSorting" />};
  }
  
  $config .= sprintf '<input type="hidden" name="hiddenColumns" value="%s" />', $self->jsonify($hidden) if scalar @$hidden;
  $config .= qq{<input type="hidden" name="defaultHiddenColumns" value="$default_hidden" />} if $default_hidden;
  
  foreach (keys %{$self->{'options'}{'data_table_config'}}) {
    my $option = $self->{'options'}{'data_table_config'}{$_};
    my $val;
    
    if (ref $option) {
      ($val = $self->jsonify($option)) =~ s/"/'/g;
    } else {
      $val = $option;
    }
    
    $config .= qq{<input type="hidden" name="$_" value="$val" />};
  }
  
  $config .= sprintf '<input type="hidden" name="expopts" value="%s" />', $self->export_options;
 
## VB FIX for a datatable inside a form - can't have nested forms - see also DataTable.js
#  return qq{<form class="data_table_config" action="#">$config</form>};
  return qq{<div class="data_table_config">$config</div>};  
##
}

   
1;
