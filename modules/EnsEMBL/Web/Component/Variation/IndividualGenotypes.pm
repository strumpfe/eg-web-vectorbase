package EnsEMBL::Web::Component::Variation::IndividualGenotypes;

use strict;

sub content {
  my $self         = shift;
  my $object       = $self->object;
  my $hub          = $self->hub;
  my $selected_pop = $hub->param('pop');
  
  
  my $pop_obj  = $selected_pop ? $self->hub->get_adaptor('get_PopulationAdaptor', 'variation')->fetch_by_dbID($selected_pop) : undef;
  my %ind_data = %{$object->individual_table($pop_obj)};

  return sprintf '<h3>No individual genotypes for this SNP%s %s</h3>', $selected_pop ? ' in population' : '', $pop_obj->name unless %ind_data;

  my (%rows, %all_pops, %pop_names);
  my $flag_children = 0;
  my $allele_string = $self->object->alleles;

  my $al_colours = $self->object->get_allele_genotype_colours;
  
## VB
  my @names = map {$_->{'Name'}} values %ind_data;
  
  my $variation_db_adaptor = $hub->database('variation');

  my $sample_st = $variation_db_adaptor->prepare(
    "SELECT i.name, iss.name FROM individual i, individual_synonym iss, source s
     WHERE i.individual_id = iss.individual_id
     AND s.source_id = iss.source_id
     AND s.name = 'VBPopBio'
     AND i.name IN ('" . join("', '", @names) . "')"
  );

  $sample_st->execute;  

  my %sample_name = map { $_->[0] => $_->[1] } @{$sample_st->fetchall_arrayref};
##
  
  foreach my $ind_id (sort { $ind_data{$a}{'Name'} cmp $ind_data{$b}{'Name'} } keys %ind_data) {
    my $data     = $ind_data{$ind_id};
    my $genotype = $data->{'Genotypes'};
    
    next if $genotype eq '(indeterminate)';
    
    my $father      = $self->format_parent($data->{'Father'});
    my $mother      = $self->format_parent($data->{'Mother'});
    my $description = $data->{'Description'} || '-';
    my %populations;
    
    my $other_ind = 0;
    
    foreach my $pop(@{$data->{'Population'}}) {
      my $pop_id = $pop->{'ID'};
      next unless ($pop_id);
      
      if ($pop->{'Size'} == 1) {
        $other_ind = 1;
      }
      else {
        $populations{$pop_id} = 1;
        $all_pops{$pop_id}    = $self->pop_url($pop->{'Name'}, $pop->{'Link'});
        $pop_names{$pop_id}   = $pop->{'Name'};
      }
    }
    
    # Colour the genotype
    foreach my $al (keys(%$al_colours)) {
      $genotype =~ s/$al/$al_colours->{$al}/g;
    } 
    
    my $row = {
## VB      
      Individual  => sprintf("<small><a href=\"/popbio/sample/?id=%s\">$data->{'Name'}</a> (%s)</small>", $sample_name{$data->{'Name'}}, substr($data->{'Gender'}, 0, 1)),
##
      Genotype    => "<small>$genotype</small>",
      Population  => "<small>".join(", ", sort keys %{{map {$_->{Name} => undef} @{$data->{Population}}}})."</small>",
      Father      => "<small>".($father eq '-' ? $father : "<a href=\"#$father\">$father</a>")."</small>",
      Mother      => "<small>".($mother eq '-' ? $mother : "<a href=\"#$mother\">$mother</a>")."</small>",
      Children    => '-'
    };
    
    my @children = map { sprintf "<small><a href=\"#$_\">$_</a> (%s)</small>", substr($data->{'Children'}{$_}[0], 0, 1) } keys %{$data->{'Children'}};
    
    if (@children) {
      $row->{'Children'} = join ', ', @children;
      $flag_children = 1;
    }
    
    if ($other_ind == 1 && scalar(keys %populations) == 0) {  
      push @{$rows{'other_ind'}}, $row;
      ## need this to display if there is only one genotype for a sequenced individual
      $pop_names{"other_ind"} = "single individuals";
    }
    else {
      push @{$rows{$_}}, $row foreach keys %populations;
    }
  }
  
  my $columns = $self->get_table_headings;
  
  push @$columns, { key => 'Children', title => 'Children<br /><small>(Male/Female)</small>', sort => 'none', help => 'Children names and genders' } if $flag_children;
    
  
  if ($selected_pop || scalar keys %rows == 1) {
    $selected_pop ||= (keys %rows)[0]; # there is only one entry in %rows
      
    return $self->toggleable_table(
      "Genotypes for $pop_names{$selected_pop}", $selected_pop, 
      $self->new_table($columns, $rows{$selected_pop}, { data_table => 1, sorting => [ 'Individual asc' ] }),
      1,
      qq{<span style="float:right"><a href="#$self->{'id'}_top">[back to top]</a></span><br />}
    );
  }
  
  return $self->summary_tables(\%all_pops, \%rows, $columns);
}

1;
