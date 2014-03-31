package EnsEMBL::Web::Component::Gene::S4DASPUBMED;
use strict;
use EBeyeSearch::EBeyeWSWrapper;
use base qw(EnsEMBL::Web::Component::Gene::S4DAS);
use Data::Dumper;
use URI::Escape;

sub _filter_features {
  my ($self, $features) = @_; 
  return [] unless @{$features};
  # only want features labelled 'All Articles'
  return [grep {$_->display_label =~ /^All Articles$/i} @{$features}];
}

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $gene_id      = $self->hub->param('g');
  my $species_defs = $hub->species_defs;
  my $logic_name   = $hub->referer->{'ENSEMBL_FUNCTION'} || $hub->function; # The DAS source this page represents
  
  my $html = qq{<p><a href="https://www.vectorbase.org/content/publication-submission/?gene_id=$gene_id">Add citations</a>};
  
  return $self->_error('No DAS source specified', 'No parameter passed!', '100%') unless $logic_name;
  
  my $source = $hub->get_das_by_logic_name($logic_name);
  
  return $self->_error(qq{DAS source "$logic_name" specified does not exist}, 'Cannot find the specified DAS source key supplied', '100%') unless $source;
  
  my $query_object = $self->_das_query_object;   

  return $html . '<p>No data available.<p>' unless $query_object;

  my $engine = new Bio::EnsEMBL::ExternalData::DAS::Coordinator(
    -sources => [ $source ],
    -proxy   => $species_defs->ENSEMBL_WWW_PROXY,
    -noproxy => $species_defs->ENSEMBL_NO_PROXY,
    -timeout => $species_defs->ENSEMBL_DAS_TIMEOUT * $self->{'timeout_multiplier'}
  );
  
  # Perform DAS requests
  my $data = $engine->fetch_Features($query_object)->{$logic_name};
  
  # Check for source errors (bad configs)
  my $source_err = $data->{'source'}->{'error'};
  
  #warn Data::Dumper::Dumper($data);
  
  if ($source_err) {
    if ($source_err eq 'Not applicable' or $source_err = 'No data for region') {
      return $html . '<p>No data available.<p>';
    } else {
      return $self->_error('Error', $source_err, '100%');
    }
  }
  
  my $segments = $self->_filter_segments($data->{'features'});
  
  my $table = $self->new_table(
    [
      { key => 'pubmed_id', title => 'PubMed&nbsp;ID', width => '6%',  align => 'left', sort => 'html' },
      { key => 'title',     title => 'Title',          width => '50%', align => 'left', sort => 'string' },
      { key => 'authors',   title => 'Authors',        width => '22%', align => 'left', sort => 'string' },
      { key => 'journal',   title => 'Journal',        width => '22%', align => 'left', sort => 'string' },
    ], 
    [], 
    { 
      class      => 'no_col_toggle',
      data_table => 1, 
      exportable => 0,
    }
  );
  
  foreach my $segment (@$segments) {
    #debug
    #$html .= sprintf qq{<a href="$segment->{url}">[view DAS response]</a>\n};
  
    if ($segment->{'error'}) {
      $html .= $self->_error('Error*', $segment->{'error'}, '100%');
      next;
    }
    
    my ($pubmed_id) = $segment->{url} =~ /segment=([^;]+)$/i;
    
    my $features = $self->_filter_features($segment->{'objects'});
    next unless @$features;

    foreach my $summary ( @{$self->_parse_features_by_type($features, 'Publication')} ) { # in reality probably only one item here
      my ($title, $authors, $journal) = @{$summary->{notes}};
      
      my @authors = split /\s*,\s+|\s*and\s+/, $authors;
      @authors = map {sprintf '<a href="http://www.ncbi.nlm.nih.gov/pubmed/?term=%s">%s</a>', uri_escape($_), $_  } @authors;
      
      $table->add_row({
        pubmed_id => sprintf( '<a href="%s" style="white-space:nowrap">%s</a>', $hub->get_ExtURL('PUBMED', $pubmed_id), $pubmed_id ),
        title     => $title,
        authors   => join(', ', @authors),
        journal   => $journal,
      });
    }
  } 
  
  $html .= $table->render;
 
  # debug
  #$html .= "<hr /><pre>" . Dumper($data->{'features'}) . "</pre>";

  return $html;
}

1;

