package EnsEMBL::Web::Document::HTML::HomeSearch;

# simplified search form for VB

use strict;

sub render {
  my $self = shift;
  
  return if $ENV{'HTTP_USER_AGENT'} =~ /Sanger Search Bot/;
  
  my $hub                 = $self->hub;
  my $species_defs        = $hub->species_defs;
  my $page_species        = $hub->species;
  my $species_name        = $page_species eq 'Multi' ? '' : $species_defs->DISPLAY_NAME;
  $species_name           = "<i>$species_name</i>" if $species_name =~ /\./;
  my $search_url          = $species_defs->ENSEMBL_WEB_ROOT . "$page_species/psychic";
  my $default_search_code = $species_defs->ENSEMBL_DEFAULT_SEARCHCODE;
  my $input_size          = $page_species eq 'Multi' ? 30 : 50;
  my $favourites          = $hub->get_favourite_species;
  my $q                   = $hub->param('q');
  
  my $html = qq{
  <div style="clear:both">
    <form action="$search_url" method="get"><div>
      <input type="hidden" name="site" value="$default_search_code" />};
  
  $html .= '<label for="q">Search for</label>:';

  $html .= qq{
    <input class="vb-search-keywords" id="q" name="q" size="$input_size" value="$q" />
    <input class="vb-search-submit" type="submit" value="Go" class="input-submit" />};

  ## Examples
  my $sample_data;
  
  if ($page_species eq 'Multi') {
    $sample_data = $species_defs->get_config('MULTI', 'GENERIC_DATA') || {};
  } else {
    $sample_data = { %{$species_defs->SAMPLE_DATA || {}} };
    $sample_data->{'GENE_TEXT'} = "$sample_data->{'GENE_TEXT'}" if $sample_data->{'GENE_TEXT'};
  }
  
  if (keys %$sample_data) {
    my @examples = map $sample_data->{$_} || (), qw(GENE_TEXT LOCATION_TEXT SEARCH_TEXT);
  
    $html .= sprintf '<p style="margin-top:5px;">e.g. %s</p>', join ' or ', map qq{<strong><a href="$search_url?q=$_" style="text-decoration:none">$_</a></strong>}, @examples if scalar @examples;
    $html .= '
      </div></form>
    </div>';
  }

  return $html;
}

1;
