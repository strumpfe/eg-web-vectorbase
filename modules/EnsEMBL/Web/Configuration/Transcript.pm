package EnsEMBL::Web::Configuration::Transcript;

use strict;

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->object;
  my $species_defs = $hub->species_defs;
  
  my $go_menu = $self->get_node('GO');
  $self->delete_node('Ontology/Image');
  $self->delete_node('Ontology/Table');

  # get all ontologies mapped to this species
  my %olist = map {$_ => 1} @{$species_defs->DISPLAY_ONTOLOGIES ||[]};

  if (%olist) {


     # get all ontologies available in the ontology db
     my %clusters = $species_defs->multiX('ONTOLOGIES');

     # get all the clusters that can generate a graph
     my @clist =  grep { $olist{ $clusters{$_}->{db} }} sort {$clusters{$a}->{db} cmp $clusters{$b}->{db}} keys %clusters; # Find if this ontology has been loaded into ontology db

     foreach my $oid (@clist) {
   my $cluster = $clusters{$oid};
   my $dbname = $cluster->{db};

# special case: there are many ontologies loaded into PBO - we only want to display gene_ex
   if ($dbname eq 'PBO') {
       next unless $oid eq 'gene_ex';
   }


   my $go_hash  = $self->object ? $object->get_ontology_chart($dbname, $cluster->{root}) : {};
   next unless (%$go_hash);
   my @c = grep { $go_hash->{$_}->{selected} } keys %$go_hash;
   my $num = scalar(@c);
   
   my $url2 = $hub->url({
       type    => 'Transcript',
       action  => 'Ontology/'.$oid,
       oid     => $oid
            });

   (my $desc2 = "$cluster->{db}: $cluster->{description}") =~ s/_/ /g;
   $go_menu->append($self->create_node('Ontology/'.$oid, "$desc2 ($num)",
               [qw( go EnsEMBL::Web::Component::Transcript::Ontology )],
               { 'availability' => 'transcript', 'concise' => $desc2, 'url' =>  $url2 }
        ));
   
     }
  }

  $self->delete_node('S4_PROTEIN_STRUCTURE');  
}


1;

