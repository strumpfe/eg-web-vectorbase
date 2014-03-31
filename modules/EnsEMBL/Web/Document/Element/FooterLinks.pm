package EnsEMBL::Web::Document::Element::FooterLinks;

### Generates release info for the footer                                                                                                                                                                                                    
use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
    my $species_defs = shift->species_defs;
#  return sprintf '<div class="twocol-right right unpadded">%s release %d - %s</div>', $species_defs->ENSEMBL_SITE_NAME, $species_defs->ENSEMBL_VERSION, $species_defs->ENSEMBL_RELEASE_DATE
return qq(
    <div class="twocol-right right">
      <script type="text/javascript">var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));</script>
       <script type="text/javascript">try { var pageTracker = _gat._getTracker("UA-6417661-1"); pageTracker._trackPageview(); } catch(err) {} </script>
      <a href="https://preview.vectorbase.org/about">About&nbsp;VectorBase</a> | 
      <a href="https://preview.vectorbase.org/contact">Contact&nbsp;Us</a> | 
      <a href="https://preview.vectorbase.org/navigation/help">Help</a> 
    </div>); 
}

1;

