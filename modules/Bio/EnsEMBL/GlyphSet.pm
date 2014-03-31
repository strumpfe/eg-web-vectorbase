package Bio::EnsEMBL::GlyphSet;
use strict;
use warnings;
no warnings "uninitialized";

## VB
## revert to default behaviour 
sub _url { return shift->{'config'}->hub->url('ZMenu', @_) }     
## /VB

1;

