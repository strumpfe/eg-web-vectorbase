package EnsEMBL::Web::ConfigPacker;

use strict;
use warnings;
no warnings qw(uninitialized);

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