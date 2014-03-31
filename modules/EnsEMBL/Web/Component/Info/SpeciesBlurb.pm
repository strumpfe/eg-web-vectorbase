# $Id: SpeciesBlurb.pm,v 1.3 2014-01-23 16:25:18 nl2 Exp $

package EnsEMBL::Web::Component::Info::SpeciesBlurb;

use strict;

use EnsEMBL::Web::Controller::SSI;

sub content {
  my $self              = shift;
  my $hub               = $self->hub;
  my $species_defs      = $hub->species_defs;
  my $species           = $hub->species;
  my $common_name       = $species_defs->SPECIES_COMMON_NAME;
  my $display_name      = $species_defs->SPECIES_SCIENTIFIC_NAME;
  my $ensembl_version   = $species_defs->ENSEMBL_VERSION;
  my $current_assembly  = $species_defs->ASSEMBLY_NAME;
  my $accession         = $species_defs->ASSEMBLY_ACCESSION;
  my $source            = $species_defs->ASSEMBLY_ACCESSION_SOURCE || 'NCBI';
  my $source_type       = $species_defs->ASSEMBLY_ACCESSION_TYPE;
  my %archive           = %{$species_defs->get_config($species, 'ENSEMBL_ARCHIVES') || {}};
  my %assemblies        = %{$species_defs->get_config($species, 'ASSEMBLIES')       || {}};
  my $previous          = $current_assembly;

  my $html = qq(
<div class="column-wrapper">  
  <div class="column-one">
    <div class="column-padding no-left-margin">
      <img src="/i/species/48/$species.png" class="species-img float-left" alt="" />
      <h1 style="margin-bottom:0">$common_name Assembly and Gene Annotation</p>
    </div>
  </div>
</div>
          );

  ## ASSEMBLY STATS 
  my $file = '/ssi/species/stats_' . $self->hub->species . '.html';
  $html .= EnsEMBL::Web::Controller::SSI::template_INCLUDE($self, $file);

  my $interpro = $self->hub->url({'action' => 'IPtop500'});
  $html .= qq(<h3>InterPro Hits</h3>
<ul>
  <li><a href="$interpro">Table of top 500 InterPro hits</a></li>
</ul>);

  return $html;  
}

1;
