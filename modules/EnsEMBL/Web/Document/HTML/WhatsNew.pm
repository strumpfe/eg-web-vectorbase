# $Id: WhatsNew.pm,v 1.1 2011-07-25 12:25:04 gk4 Exp $

package EnsEMBL::Web::Document::HTML::WhatsNew;

### This module outputs a selection of news headlines for the home page,
### based on the user's settings or a default list

use strict;
use warnings;

use EnsEMBL::Web::Hub;

sub render {
  my $self = shift;
  my $hub = new EnsEMBL::Web::Hub;

  my $species_defs = $hub->species_defs;

  my $file = '/ssi/whatsnew.html';

  my $html = sprintf (qq{<h2 class="first"> What's in Release %s (%s)</h2>}, $species_defs->SITE_RELEASE_VERSION, $species_defs->SITE_RELEASE_DATE);

  $html .= EnsEMBL::Web::Controller::SSI::template_INCLUDE(undef, $file);

  $html .= sprintf (qq{<p>
%s release %s operates using Ensembl %d software.
</p>}, $species_defs->SITE_NAME, $species_defs->SITE_RELEASE_VERSION, $species_defs->ENSEMBL_VERSION);
  return $html;

}

1;
