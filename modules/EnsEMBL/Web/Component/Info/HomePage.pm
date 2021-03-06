# $Id: HomePage.pm,v 1.8 2013-12-03 12:44:26 nl2 Exp $

package EnsEMBL::Web::Component::Info::HomePage;

use strict;

sub _assembly_text {
  my $self             = shift;
  my $hub              = $self->hub;
  my $species_defs     = $hub->species_defs;
  my $species          = $hub->species;
  my $name             = $species_defs->SPECIES_COMMON_NAME;
  my $img_url          = $self->img_url;
  my $sample_data      = $species_defs->SAMPLE_DATA;
  my $ensembl_version  = $species_defs->SITE_RELEASE_VERSION;
  my $current_assembly = $species_defs->ASSEMBLY_NAME;
  my $accession        = $species_defs->ASSEMBLY_ACCESSION;
  my $source           = $species_defs->ASSEMBLY_ACCESSION_SOURCE || 'NCBI';
  my $source_type      = $species_defs->ASSEMBLY_ACCESSION_TYPE;
 #my %archive          = %{$species_defs->get_config($species, 'ENSEMBL_ARCHIVES') || {}};
  my %assemblies       = %{$species_defs->get_config($species, 'ASSEMBLIES') || {}};
  my $previous         = $current_assembly;

  my $html = '<div class="homepage-icon">';

  if (@{$species_defs->ENSEMBL_CHROMOSOMES || []}) {
    $html .= qq(<a class="nodeco _ht" href="/$species/Location/Genome" title="Go to $name karyotype"><img src="${img_url}96/karyotype.png" class="bordered" /><span>View karyotype</span></a>);
  }

  my $region_text = $sample_data->{'LOCATION_TEXT'};
  my $region_url  = $species_defs->species_path . '/Location/View?r=' . $sample_data->{'LOCATION_PARAM'};

  $html .= qq(<a class="nodeco _ht" href="$region_url" title="Go to $region_text"><img src="${img_url}96/region.png" class="bordered" /><span>Example region</span></a>);
  $html .= '</div>'; #homepage-icon

## VB
  my $vb_species = $hub->database('core')->get_MetaContainer->single_value_by_key('species.vectorbase_name');
  my $assembly_display_name = $species_defs->ASSEMBLY_DISPLAY_NAME;
  (my $strain = lc($species_defs->SPECIES_STRAIN)) =~ s/\s+/-/g;
  my $assembly = sprintf( 
    '<a href="/organisms/%s/%s/%s">%s</a>', 
    lc($vb_species), 
    $strain,
    lc($assembly_display_name), 
    $assembly_display_name
  );
## VB
  
  
  $html .= "<h2>Genome assembly: $assembly</h2>";
  $html .= qq(<p><a href="/$species/Info/Annotation/#assembly" class="nodeco"><img src="${img_url}24/info.png" alt="" class="homepage-link" />More information and statistics</a></p>);

  # Link to FTP site
  if ($species_defs->ENSEMBL_FTP_URL) {
    my $ftp_url;
    if ($self->is_bacteria) {
      $ftp_url = sprintf '%s/release-%s/fasta/%s_collection/%s/dna/', $species_defs->ENSEMBL_FTP_URL, $ensembl_version, $species_defs->SPECIES_DATASET, lc $species;
    }
    else {
      $ftp_url = sprintf '%s/release-%s/fasta/%s/dna/', $species_defs->ENSEMBL_FTP_URL, $ensembl_version, lc $species;
    }
    $html .= qq(<p><a href="$ftp_url" class="nodeco"><img src="${img_url}24/download.png" alt="" class="homepage-link" />Download DNA sequence</a> (FASTA)</p>);
  }
  
  # Link to assembly mapper
  my $mappings = $species_defs->ASSEMBLY_MAPPINGS;
  if ($mappings && ref($mappings) eq 'ARRAY') {
    my $am_url = $hub->url({'type' => 'UserData', 'action' => 'SelectFeatures'});
    $html .= qq(<p><a href="$am_url" class="modal_link nodeco"><img src="${img_url}24/tool.png" class="homepage-link" />Convert your data to $assembly coordinates</a></p>);
  }

#EG no old assemblies
 ## PREVIOUS ASSEMBLIES
 #my @old_archives;
 #
 ## Insert dropdown list of old assemblies
 #foreach my $release (reverse sort keys %archive) {
 #  next if $release == $ensembl_version;
 #  next if $assemblies{$release} eq $previous;

 #  push @old_archives, {
 #    url      => sprintf('http://%s.archive.ensembl.org/%s/', lc $archive{$release},           $species),
 #    assembly => "$assemblies{$release}",
 #    release  => (sprintf '(%s release %s)',                  $species_defs->ENSEMBL_SITETYPE, $release),
 #  };

 #  $previous = $assemblies{$release};
 #}

 ## Combine archives and pre
 #my $other_assemblies;
 #if (@old_archives) {
 #  $other_assemblies .= join '', map qq(<li><a href="$_->{'url'}" class="nodeco">$_->{'assembly'}</a> $_->{'release'}</li>), @old_archives;
 #}

 #my $pre_species = $species_defs->get_config('MULTI', 'PRE_SPECIES');
 #if ($pre_species->{$species}) {
 #  $other_assemblies .= sprintf('<li><a href="http://pre.ensembl.org/%s/" class="nodeco">%s</a> (Ensembl pre)</li>', $species, $pre_species->{$species}[1]);
 #}

 #if ($other_assemblies) {
 #  $html .= qq(
 #    <h3 style="color:#808080;padding-top:8px">Other assemblies</h3>
 #    <ul>$other_assemblies</ul>
 #  );
 #}

  return $html;
}

1;
