package EG::Vectorbase::SiteDefs;
use strict;
use Sys::Hostname;

sub update_conf {

  if (hostname() =~  /fry/) {
    $SiteDefs::ENSEMBL_SERVERNAME   = 'pre.vectorbase.org';
    $SiteDefs::ENSEMBL_BASE_URL     = 'http://pre.vectorbase.org';
    $SiteDefs::VECTORBASE_BASE_URL  = 'http://pre.vectorbase.org';
  } else {
    $SiteDefs::ENSEMBL_SERVERNAME   = 'www.vectorbase.org';
    $SiteDefs::ENSEMBL_BASE_URL     = 'http://www.vectorbase.org';
    $SiteDefs::VECTORBASE_BASE_URL  = 'http://www.vectorbase.org';
  }

  $SiteDefs::SITE_RELEASE_VERSION  = '1402';
  $SiteDefs::SITE_RELEASE_DATE     = 'February 2014';
  $SiteDefs::VECTORBASE_VERSION    = 'VB-2014-02';

  $SiteDefs::ENSEMBL_PORT       = 8080; 
  $SiteDefs::APACHE_BIN         = '/usr/sbin/httpd';
  $SiteDefs::APACHE_DIR         = '/etc/httpd';
  $SiteDefs::SAMTOOLS_DIR       = '/nfs/public/rw/ensembl/samtools';

  $SiteDefs::ENSEMBL_PRIMARY_SPECIES    = 'Glossina_morsitans'; 
  $SiteDefs::ENSEMBL_SECONDARY_SPECIES  = 'Phlebotomus_papatasi';

  map {delete($SiteDefs::__species_aliases{$_}) } keys %SiteDefs::__species_aliases;
  
  $SiteDefs::__species_aliases{ 'Aedes_aegypti' } = [qw(aa aaeg aedes )];
  $SiteDefs::__species_aliases{ 'Culex_quinquefasciatus' } = [qw(cq culex common_house_mosquito Culex_pipiens C.quinquefasciatus C.pipiens )];
  $SiteDefs::__species_aliases{ 'Ixodes_scapularis'} = [qw(is ixodes blacklegged_tick black_legged_tick I.scapularis)];
  $SiteDefs::__species_aliases{ 'Pediculus_humanus' } = [qw(ph pediculus body_louse)];
  $SiteDefs::__species_aliases{ 'Rhodnius_prolixus' } = [qw(rp rhodnius triatomid_bug R.prolixus)];
  $SiteDefs::__species_aliases{ 'Glossina_morsitans' } = [qw(gm glossina tse_tse_fly G.morsitans)];
  $SiteDefs::__species_aliases{ 'Rhodnius_prolixus' } = [qw(rp rhodnius triatomid_bug R.prolixus)];
  $SiteDefs::__species_aliases{ 'Phlebotomus_papatasi' } = [qw(pp)];
  $SiteDefs::__species_aliases{ 'Lutzomyia_longipalpis' } = [qw(ll)];
  $SiteDefs::__species_aliases{ 'Drosophila_melanogaster' } = [qw(dm)];
  $SiteDefs::__species_aliases{ 'Biomphalaria_glabrata' } = [qw(bg)];
  
  $SiteDefs::__species_aliases{ 'Anopheles_gambiae' } = [qw(ag agam mosquito mos anopheles)];
  $SiteDefs::__species_aliases{ 'Anopheles_gambiaeS' } = [qw(ag agam mosquito mos anopheles)];
  $SiteDefs::__species_aliases{ 'Anopheles_stephensi' } = [qw(as)];
  $SiteDefs::__species_aliases{ 'Anopheles_darlingi' } = [qw(ad)];
  $SiteDefs::__species_aliases{ 'Anopheles_albimanus' } = [qw(A.albimanus)];
  $SiteDefs::__species_aliases{ 'Anopheles_arabiensis' } = [qw(A.arabiensis)];
  $SiteDefs::__species_aliases{ 'Anopheles_christyi' } = [qw(A.christyi)];
  $SiteDefs::__species_aliases{ 'Anopheles_dirus' } = [qw(A.dirus)];
  $SiteDefs::__species_aliases{ 'Anopheles_epiroticus' } = [qw(A.epiroticus)];
  $SiteDefs::__species_aliases{ 'Anopheles_funestus' } = [qw(A.funestus)];
  $SiteDefs::__species_aliases{ 'Anopheles_minimus' } = [qw(A.minimus)];
  $SiteDefs::__species_aliases{ 'Anopheles_quadriannulatus' } = [qw(A.quadriannulatus)];
  $SiteDefs::__species_aliases{ 'Anopheles_stephensiI' } = [qw(asi)];
  $SiteDefs::__species_aliases{ 'Anopheles_atroparvus' } = [qw(A.atroparvus)];
  $SiteDefs::__species_aliases{ 'Anopheles_culicifacies' } = [qw(A.culicifacies)];
  $SiteDefs::__species_aliases{ 'Anopheles_farauti' } = [qw(A.farauti)];
  $SiteDefs::__species_aliases{ 'Anopheles_maculatus' } = [qw(A.maculatus)];
  $SiteDefs::__species_aliases{ 'Anopheles_melas' } = [qw(A.melas)];
  $SiteDefs::__species_aliases{ 'Anopheles_merus' } = [qw(A.merus)];
  $SiteDefs::__species_aliases{ 'Anopheles_sinensis' } = [qw(A.sinensis)];
  $SiteDefs::__species_aliases{ 'Anopheles_coluzzii' } = [qw(A.coluzzii)];

  @SiteDefs::ENSEMBL_PERL_DIRS    = (
    $SiteDefs::ENSEMBL_SERVERROOT.'/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/eg-plugins/common/perl',
    $SiteDefs::ENSEMBL_SERVERROOT.'/eg-plugins/vectorbase/perl',
  );

  $SiteDefs::ENSEMBL_SITENAME       = 'VectorBase';
  $SiteDefs::ENSEMBL_SITE_NAME      = 'VectorBase';
  $SiteDefs::ENSEMBL_SITETYPE       = 'VectorBase';
  $SiteDefs::ENSEMBL_HELPDESK_EMAIL = 'info@vectorbase.org';
  $SiteDefs::ENSEMBL_SERVERADMIN    = 'webmaster@vectorbase.org';
  $SiteDefs::ENSEMBL_MAIL_SERVER    = 'smtp.vectorbase.org';
  $SiteDefs::SITE_FTP               = '/downloads';
  
  $SiteDefs::VECTORBASE_SEARCH_SITE        = "https://www.vectorbase.org";
  $SiteDefs::VECTORBASE_EXPRESSION_BROWSER = 'http://funcgen.vectorbase.org/expression-browser';
  $SiteDefs::VECTORBASE_FTP_PREFIX         = 'ftpi';
  
  $SiteDefs::ENSEMBL_LOGINS = 0;
  $SiteDefs::OBJECT_TO_SCRIPT->{'Info'} = 'AltPage';
  $siteDefs::UDC_CACHEDIR = '/tmp';
}

1;

