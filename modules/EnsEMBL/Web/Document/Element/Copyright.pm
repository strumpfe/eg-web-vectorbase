package EnsEMBL::Web::Document::Element::Copyright;

### Copyright notice for footer (basic version with no logos)

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub new {
    return shift->SUPER::new({
	%{$_[0]},
    sitename => '?'
			     });
}

sub sitename :lvalue { $_[0]{'sitename'}; }


sub content {
    #my @time = localtime;
    #my $year = @time[5] + 1900;
    #my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;

    # VectorBase release 6 - October 2010 © VectorBase
    return qq{                                                                                                         
    <div class="twocol-left left">VectorBase release $SiteDefs::SITE_RELEASE_VERSION - $SiteDefs::SITE_RELEASE_DATE
	&copy; <span class="print_hide"><a href="/" class="nowrap">VectorBase</a></span>             
      <span class="screen_hide_inline">VectorBase</span>
</div>                                                                                                           
    };

#    return $_[0]->printf( 
#	qq(<div class="twocol-left left unpadded">
#           %s release %d - %s
#           &copy; <span class="print_hide"><a href="/" style="white-space:nowrap">VectorBase</a></span>
#           <span class="screen_hide_inline">VectorBase</span>
#           </div>),     
#	$sd->SITE_NAME, $sd->SITE_RELEASE_VERSION, $sd->SITE_RELEASE_DATE
#	);

}

sub init {
    $_[0]->sitename = $_[0]->species_defs->ENSEMBL_SITETYPE;
}


#  my $sd = $ENSEMBL_WEB_REGISTRY->species_defs;
 
# $_[0]->printf( qq(
#  <div class="twocol-left left unpadded">
#		   %s release %d - %s
#		  &copy; <span class="print_hide"><a href="/" style="white-space:nowrap">VectorBase</a></span>
#      <span class="screen_hide_inline">VectorBase</span>
#  </div>),     $sd->SITE_NAME, $sd->SITE_RELEASE_VERSION, $sd->SITE_RELEASE_DATE
#	       );
#}

1;

