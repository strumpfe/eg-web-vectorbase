package EnsEMBL::Web::ConfigPacker;

use strict;
use warnings;
no warnings qw(uninitialized);

sub _summarise_variation_db {
  my($self,$code,$db_name) = @_;
  my $dbh     = $self->db_connect( $db_name );
  return unless $dbh;
  push @{ $self->db_tree->{'variation_like_databases'} }, $db_name;
  $self->_summarise_generic( $db_name, $dbh );
  
  # get menu config from meta table if it exists
  my $v_conf_aref = $dbh->selectall_arrayref('select meta_value from meta where meta_key = "web_config" order by meta_id asc');
  foreach my $row(@$v_conf_aref) {
    my ($type, $long_name, $key, $parent) = split /\#/, $row->[0];
  
    push @{$self->db_details($db_name)->{'tables'}{'menu'}}, {
      type       => $type,
      long_name  => $long_name,
      key        => $key,
      parent     => $parent
    };
  }
  
  my $t_aref = $dbh->selectall_arrayref( 'select source_id,name,description, if(somatic_status = "somatic", 1, 0), type from source' );
#---------- Add in information about the sources from the source table
  my $temp = {map {$_->[0],[$_->[1],0]} @$t_aref};
  my $temp_description = {map {$_->[1],$_->[2]} @$t_aref};
  my $temp_somatic = { map {$_->[1],$_->[3]} @$t_aref};
  my $temp_type = { map {$_->[1], $_->[4]} @$t_aref};
  foreach my $t (qw(variation variation_synonym)) {
    my $t_aref = $dbh->selectall_arrayref( "select source_id,count(*) from $t group by source_id" );
    foreach (@$t_aref) {
      $temp->{$_->[0]}[1] += $_->[1];
    }
  }
  $self->db_details($db_name)->{'tables'}{'source'}{'counts'} = { map {@$_} values %$temp};
  $self->db_details($db_name)->{'tables'}{'source'}{'descriptions'} = \%$temp_description;
  $self->db_details($db_name)->{'tables'}{'source'}{'somatic'} = \%$temp_somatic;
  $self->db_details($db_name)->{'tables'}{'source'}{'type'} = \%$temp_type;

#---------- Store dbSNP version 
 my $s_aref = $dbh->selectall_arrayref( 'select version from source where name = "dbSNP"' );
 foreach (@$s_aref){
    my ($version) = @$_;
    $self->db_details($db_name)->{'dbSNP_VERSION'} = $version;   
  }

#--------- Does this species have structural variants?
 my $sv_aref = $dbh->selectall_arrayref('select count(*) from structural_variation');
 foreach (@$sv_aref){
    my ($count) = @$_;
    $self->db_details($db_name)->{'STRUCTURAL_VARIANT_COUNT'} = $count;
 }

#---------- Add in information about the display type from the sample table
   my $d_aref = [];
   if ($self->db_details($db_name)->{'tables'}{'sample'}) {
      $d_aref = $dbh->selectall_arrayref( "select name, display from sample where display not like 'UNDISPLAYABLE'" );
   } else {
      my $i_aref = $dbh->selectall_arrayref( "select name, display from individual where display not like 'UNDISPLAYABLE'" );
      push @$d_aref, @$i_aref;
      my $p_aref = $dbh->selectall_arrayref( "select name, display from population where display not like 'UNDISPLAYABLE'" );
      push @$d_aref, @$p_aref; 
   }
   my (@default, $reference, @display, @ld);
   foreach (@$d_aref){
     my  ($name, $type) = @$_;  
     if ($type eq 'REFERENCE') { $reference = $name;}
     elsif ($type eq 'DISPLAYABLE'){ push(@display, $name); }
     elsif ($type eq 'DEFAULT'){ push (@default, $name); }
     elsif ($type eq 'LD'){ push (@ld, $name); } 
   }
   $self->db_details($db_name)->{'tables'}{'individual.reference_strain'} = $reference;
   $self->db_details($db_name)->{'REFERENCE_STRAIN'} = $reference; 
   $self->db_details($db_name)->{'meta_info'}{'individual.default_strain'} = \@default;
   $self->db_details($db_name)->{'DEFAULT_STRAINS'} = \@default;  
   $self->db_details($db_name)->{'meta_info'}{'individual.display_strain'} = \@display;
   $self->db_details($db_name)->{'DISPLAY_STRAINS'} = \@display; 
   $self->db_details($db_name)->{'LD_POPULATIONS'} = \@ld;

## VB - add description lookup
  
  my $name_desc = $dbh->selectall_arrayref( "select name, description from individual where display not like 'UNDISPLAYABLE'" );
  $self->db_details($db_name)->{'DISPLAY_STRAIN_DESCRIPTION'}->{$_->[0]} = $_->[1] for @$name_desc;

##

#---------- Add in strains contained in read_coverage_collection table
  if ($self->db_details($db_name)->{'tables'}{'read_coverage_collection'}){
    my $r_aref = $dbh->selectall_arrayref(
        'select distinct i.name, i.individual_id
        from individual i, read_coverage_collection r
        where i.individual_id = r.sample_id' 
     );
     my @strains;
     foreach my $a_aref (@$r_aref){
       my $strain = $a_aref->[0] . '_' . $a_aref->[1];
       push (@strains, $strain);
     }
     if (@strains) { $self->db_details($db_name)->{'tables'}{'read_coverage_collection_strains'} = join(',', @strains); } 
  }

#--------- Add in structural variation information
  my $v_aref = $dbh->selectall_arrayref("select s.name, count(*), s.description from structural_variation sv, source s, attrib a where sv.source_id=s.source_id and sv.class_attrib_id=a.attrib_id and a.value!='probe' and sv.somatic=0 group by sv.source_id");
  my %structural_variations;
  my %sv_descriptions;
  foreach (@$v_aref) {
   $structural_variations{$_->[0]} = $_->[1];    
   $sv_descriptions{$_->[0]} = $_->[2];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'counts'} = \%structural_variations;
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'descriptions'} = \%sv_descriptions;

#--------- Add in copy number variant probes information
  my $cnv_aref = $dbh->selectall_arrayref("select s.name, count(*), s.description from structural_variation sv, source s, attrib a where sv.source_id=s.source_id and sv.class_attrib_id=a.attrib_id and a.value='probe' group by sv.source_id");
  my %cnv_probes;
  my %cnv_probes_descriptions;
  foreach (@$cnv_aref) {
   $cnv_probes{$_->[0]} = $_->[1];    
   $cnv_probes_descriptions{$_->[0]} = $_->[2];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{cnv_probes}{'counts'} = \%cnv_probes;
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{cnv_probes}{'descriptions'} = \%cnv_probes_descriptions;
#--------- Add in somatic structural variation information
  my $som_sv_aref = $dbh->selectall_arrayref("select s.name, count(*), s.description from structural_variation sv, source s, attrib a where sv.source_id=s.source_id and sv.class_attrib_id=a.attrib_id and a.value!='probe' and sv.somatic=1 group by sv.source_id");
  my %somatic_sv;
  my %somatic_sv_descriptions;
  foreach (@$som_sv_aref) {
   $somatic_sv{$_->[0]} = $_->[1];    
   $somatic_sv_descriptions{$_->[0]} = $_->[2];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'somatic'}{'counts'} = \%somatic_sv;
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'somatic'}{'descriptions'} = \%somatic_sv_descriptions;  
#--------- Add in structural variation study information
  my $study_sv_aref = $dbh->selectall_arrayref("select distinct st.name, st.description from structural_variation sv, study st where sv.study_id=st.study_id");
  my %study_sv_descriptions;
  foreach (@$study_sv_aref) {    
   $study_sv_descriptions{$_->[0]} = $_->[1];
  }
  $self->db_details($db_name)->{'tables'}{'structural_variation'}{'study'}{'descriptions'} = \%study_sv_descriptions;    
#--------- Add in Variation set information
  # First get all toplevel sets
  my (%super_sets, %sub_sets, %set_descriptions);

  my $st_aref = $dbh->selectall_arrayref('
    select vs.variation_set_id, vs.name, vs.description, a.value
      from variation_set vs, attrib a
      where not exists (
        select * 
          from variation_set_structure vss
          where vss.variation_set_sub = vs.variation_set_id
        )
        and a.attrib_id = vs.short_name_attrib_id'
  );
  
  # then get subsets foreach toplevel set
  foreach (@$st_aref) {
    my $set_id = $_->[0];
    
    $super_sets{$set_id} = {
      name        => $_->[1],
      description => $_->[2],
      short_name  => $_->[3],
      subsets     => [],
    };
  
  $set_descriptions{$_->[3]} = $_->[2];
    
    my $ss_aref = $dbh->selectall_arrayref("
      select vs.variation_set_id, vs.name, vs.description, a.value 
        from variation_set vs, variation_set_structure vss, attrib a
        where vss.variation_set_sub = vs.variation_set_id 
          and a.attrib_id = vs.short_name_attrib_id
          and vss.variation_set_super = $set_id"  
    );

    foreach my $sub_set (@$ss_aref) {
      push @{$super_sets{$set_id}{'subsets'}}, $sub_set->[0];
      
      $sub_sets{$sub_set->[0]} = {
        name        => $sub_set->[1],
        description => $sub_set->[2],
        short_name  => $sub_set->[3],
      };
    } 
  }
  
  # just get all descriptions
  my $vs_aref = $dbh->selectall_arrayref("
  SELECT a.value, vs.description
  FROM variation_set vs, attrib a
  WHERE vs.short_name_attrib_id = a.attrib_id
  ");
  
  $set_descriptions{$_->[0]} = $_->[1] for @$vs_aref;

  $self->db_details($db_name)->{'tables'}{'variation_set'}{'supersets'}    = \%super_sets;  
  $self->db_details($db_name)->{'tables'}{'variation_set'}{'subsets'}      = \%sub_sets;
  $self->db_details($db_name)->{'tables'}{'variation_set'}{'descriptions'} = \%set_descriptions;
  
#--------- Add in phenotype information
  my $pf_aref = $dbh->selectall_arrayref(qq{
    SELECT type, count(*)
    FROM phenotype_feature
    GROUP BY type
  });
  
  for(@$pf_aref) {
    $self->db_details($db_name)->{'tables'}{'phenotypes'}{'rows'} += $_->[1];
    $self->db_details($db_name)->{'tables'}{'phenotypes'}{'types'}{$_->[0]} = $_->[1];
  }

#--------- Add in somatic mutation information
  my %somatic_mutations;
  # Somatic source(s)
  my $sm_aref =  $dbh->selectall_arrayref(
    'select distinct(p.description), pf.phenotype_id, s.name 
     from phenotype p, phenotype_feature pf, source s, study st
     where p.phenotype_id=pf.phenotype_id and pf.study_id = st.study_id
     and st.source_id=s.source_id and s.somatic_status = "somatic"'
  );
  foreach (@$sm_aref){ 
    $somatic_mutations{$_->[2]}->{$_->[0]} = $_->[1] ;
  } 
  
  # Mixed source(s)
  my $mx_aref = $dbh->selectall_arrayref(
    'select distinct(s.name) from variation v, source s 
     where v.source_id=s.source_id and s.somatic_status = "mixed"'
  );
  foreach (@$mx_aref){ 
    $somatic_mutations{$_->[0]}->{'none'} = 'none' ;
  } 
  
  $self->db_details($db_name)->{'SOMATIC_MUTATIONS'} = \%somatic_mutations;

  ## Do we have SIFT and/or PolyPhen predictions?
  my $prediction_aref = $dbh->selectall_arrayref(
    'select distinct(a.value) from attrib a, protein_function_predictions p where a.attrib_id = p.analysis_attrib_id'
  );
  foreach (@$prediction_aref) {
    if ($_->[0] =~ /sift/i) {
      $self->db_details($db_name)->{'SIFT'} = 1;
    }
    if ($_->[0] =~ /^polyphen/i) {
      $self->db_details($db_name)->{'POLYPHEN'} = 1;
    }
  }
  
  # get possible values from attrib tables
  @{$self->db_details($db_name)->{'SIFT_VALUES'}} = map {$_->[0]} @{$dbh->selectall_arrayref(
    'SELECT a.value FROM attrib a, attrib_type t WHERE a.attrib_type_id = t.attrib_type_id AND t.code = "sift_prediction";'
  )};
  @{$self->db_details($db_name)->{'POLYPHEN_VALUES'}} = map {$_->[0]} @{$dbh->selectall_arrayref(
    'SELECT a.value FROM attrib a, attrib_type t WHERE a.attrib_type_id = t.attrib_type_id AND t.code = "polyphen_prediction";'
  )};

  $dbh->disconnect();
}

sub _summarise_funcgen_db {
  my ($self, $db_key, $db_name) = @_;
  my $dbh = $self->db_connect($db_name);
  
  return unless $dbh;
  
  push @{$self->db_tree->{'funcgen_like_databases'}}, $db_name;
  
  $self->_summarise_generic($db_name, $dbh);
  
  ## Grab each of the analyses - will use these in a moment
  my $t_aref = $dbh->selectall_arrayref(
    'select a.analysis_id, a.logic_name, a.created, ad.display_label, ad.description, ad.displayable, ad.web_data
    from analysis a left join analysis_description as ad on a.analysis_id=ad.analysis_id'
  );
  
  my $analysis = {};
  
  foreach my $a_aref (@$t_aref) {
    my $desc;
    { no warnings; $desc = eval($a_aref->[4]) || $a_aref->[4]; }    
    (my $web_data = $a_aref->[6]) =~ s/^[^{]+//; ## Strip out "crap" at front and end! probably some q(')s
    $web_data     =~ s/[^}]+$//;
    $web_data     = eval($web_data) || {};
    
    $analysis->{$a_aref->[0]} = {
      'logic_name'  => $a_aref->[1],
      'name'        => $a_aref->[3],
      'description' => $desc,
      'displayable' => $a_aref->[5],
      'web_data'    => $web_data
    };
  }

  ## Get analysis information about each feature type
  foreach my $table (qw(probe_feature feature_set result_set)) {
    my $res_aref = $dbh->selectall_arrayref("select analysis_id, count(*) from $table group by analysis_id");
    
    foreach my $T (@$res_aref) {
      my $a_ref = $analysis->{$T->[0]}; #|| ( warn("Missing analysis entry $table - $T->[0]\n") && next );
      my $value = {
        'name'  => $a_ref->{'name'},
        'desc'  => $a_ref->{'description'},
        'disp'  => $a_ref->{'displayable'},
        'web'   => $a_ref->{'web_data'},
        'count' => $T->[1]
      }; 
      
      $self->db_details($db_name)->{'tables'}{$table}{'analyses'}{$a_ref->{'logic_name'}} = $value;
    }
  }

###
### Store the external feature sets available for each species
###
  my @feature_sets;
  my $f_aref = $dbh->selectall_arrayref(
    "select name
      from feature_set
      where type = 'external'"
  );
  foreach my $F ( @$f_aref ){ push (@feature_sets, $F->[0]); }  
  $self->db_tree->{'databases'}{'DATABASE_FUNCGEN'}{'FEATURE_SETS'} = \@feature_sets;


#---------- Additional queries - by type...

#
# * Oligos
#
#  $t_aref = $dbh->selectall_arrayref(
#    'select a.vendor, a.name,count(*)
#       from array as a, array_chip as c straight_join probe as p on
#            c.array_chip_id=p.array_chip_id straight_join probe_feature f on
#            p.probe_id=f.probe_id where a.name = c.name
#      group by a.name'
#  );

## VB - add probe descriptions
  $t_aref = $dbh->selectall_arrayref(
    'select a.vendor, a.name, a.array_id, a.description
       from array a, array_chip c, status s, status_name sn where  sn.name="DISPLAYABLE" 
       and sn.status_name_id=s.status_name_id and s.table_name="array" and s.table_id=a.array_id 
       and a.array_id=c.array_id
    '       
  );
  my $sth = $dbh->prepare(
    'select pf.probe_feature_id
       from array_chip ac, probe p, probe_feature pf, seq_region sr, coord_system cs
       where ac.array_chip_id=p.array_chip_id and p.probe_id=pf.probe_id  
       and pf.seq_region_id=sr.seq_region_id and sr.coord_system_id=cs.coord_system_id 
       and cs.is_current=1 and ac.array_id = ?
       limit 1 
    '
  );
  foreach my $row (@$t_aref) {
    my $array_name = $row->[0] .':'. $row->[1];
    my $description = $row->[3];
    $sth->bind_param(1, $row->[2]);
    $sth->execute;
    my $count = $sth->fetchrow_array();# warn $array_name ." ". $count;
    if( exists $self->db_details($db_name)->{'tables'}{'oligo_feature'}{'arrays'}{$array_name} ) {
      warn "FOUND";
    }
    $self->db_details($db_name)->{'tables'}{'oligo_feature'}{'arrays'}{$array_name} = $count ? 1 : 0;
    $self->db_details($db_name)->{'tables'}{'oligo_feature'}{'descriptions'}{$array_name} = $description;
  }
  $sth->finish;
## /VB
  
  
#
# * functional genomics tracks
#

  $f_aref = $dbh->selectall_arrayref(
    'select ft.name, ct.name 
       from supporting_set ss, data_set ds, feature_set fs, feature_type ft, cell_type ct  
       where ds.data_set_id=ss.data_set_id and ds.name="RegulatoryFeatures" 
       and fs.feature_set_id = ss.supporting_set_id and fs.feature_type_id=ft.feature_type_id 
       and fs.cell_type_id=ct.cell_type_id 
       order by ft.name;
    '
  );   
  foreach my $row (@$f_aref) {
    my $feature_type_key =  $row->[0] .':'. $row->[1];
    $self->db_details($db_name)->{'tables'}{'feature_type'}{'analyses'}{$feature_type_key} = 2;   
  }

  my $c_aref =  $dbh->selectall_arrayref(
    'select  ct.name, ct.cell_type_id 
       from  cell_type ct, feature_set fs  
       where  fs.type="regulatory" and ct.cell_type_id=fs.cell_type_id 
    group by  ct.name order by ct.name'
  );
  foreach my $row (@$c_aref) {
    my $cell_type_key =  $row->[0] .':'. $row->[1];
    $self->db_details($db_name)->{'tables'}{'cell_type'}{'ids'}{$cell_type_key} = 2;
  }

  foreach my $row (@{$dbh->selectall_arrayref(qq(
    select rs.result_set_id, a.display_label, a.description, c.name, 
           IF(min(g.is_project) = 0 or count(g.name)>1,null,min(g.name))
      from result_set rs 
      join analysis_description a using (analysis_id)
      join cell_type c using (cell_type_id)
      join result_set_input using (result_set_id)
      join input_set on input_set_id = table_id
      join experiment using (experiment_id) 
      join experimental_group g using (experimental_group_id) 
     where feature_class = 'dna_methylation' 
       and table_name = 'input_set'
  group by rs.result_set_id;
  ))}) {
    my ($id,$a_name,$a_desc,$c_desc,$group) = @$row;
    
    my $name = "$c_desc $a_name";
    $name .= " $group" if $group;
    my $desc = "$c_desc cell line: $a_desc";
    $desc .= " ($group group)." if $group;    
    $self->db_details($db_name)->{'tables'}{'methylation'}{$id} = {
      name => $name,
      description => $desc
    };
  }

  my $ft_aref =  $dbh->selectall_arrayref(
    'select ft.name, ft.feature_type_id from feature_type ft, feature_set fs, data_set ds, feature_set fs1, supporting_set ss 
      where fs1.type="regulatory" and fs1.feature_set_id=ds.feature_set_id and ds.data_set_id=ss.data_set_id 
        and ss.type="feature" and ss.supporting_set_id=fs.feature_set_id and fs.feature_type_id=ft.feature_type_id 
   group by ft.name order by ft.name'
  );
  foreach my $row (@$ft_aref) {
    my $feature_type_key =  $row->[0] .':'. $row->[1];
    $self->db_details($db_name)->{'tables'}{'feature_type'}{'ids'}{$feature_type_key} = 2;
  }

  my $rs_aref = $dbh->selectall_arrayref(
    'select name, string 
       from regbuild_string 
      where name like "%regbuild%" and 
            name like "%ids"'
  );
  foreach my $row (@$rs_aref ){
    my ($regbuild_name, $regbuild_string) = @$row; 
    $regbuild_name =~s/regbuild\.//;
    my @key_info = split(/\./,$regbuild_name); 
    my %data;  
    my @ids = split(/\,/,$regbuild_string);
    my $sth = $dbh->prepare(
          'select feature_type_id
             from feature_set
            where feature_set_id = ?'
    );
    foreach (@ids){
      if($key_info[1] =~/focus/){
        my $feature_set_id = $_;
        $sth->bind_param(1, $feature_set_id);
        $sth->execute;
        my ($feature_type_id)= $sth->fetchrow_array;
        $data{$feature_type_id} = $_;
      }
      else {
        $data{$_} = 1;
      }
      $sth->finish;
    } 
    $self->db_details($db_name)->{'tables'}{'regbuild_string'}{$key_info[1]}{$key_info[0]} = \%data;
  }
  $dbh->disconnect();
}

1;