package EnsEMBL::Web::Configuration::Gene;
use strict;
use warnings;

sub modify_tree {
  my $self = shift;
  my $hub = $self->hub;
  my $species = $hub->species;
  my $species_defs = $hub->species_defs;
  my $object = $self->object;

  my $summary = $self->get_node('Summary');

#  my $splice = $self->get_node('Splice');
#  $splice->set('components', [qw( image EnsEMBL::Web::Component::Gene::GeneSpliceImageNew )]);

  return unless ($self->object || $hub->param('g'));

  my $gene_adaptor = $hub->get_adaptor('get_GeneAdaptor', 'core', $species);
  my $gene   = $self->object ? $self->object->gene : $gene_adaptor->fetch_by_stable_id($hub->param('g'));  

  return if ref $gene eq 'Bio::EnsEMBL::ArchiveStableId';

  my @transcripts  = sort { $a->start <=> $b->start } @{ $gene->get_all_Transcripts || [] };
  my $transcript   = @transcripts > 0 ? $transcripts[0] : undef;

  my $region = $hub->param('r');
  my ($reg_name, $start, $end) = $region =~ /(.+?):(\d+)-(\d+)/ ? $region =~ /(.+?):(\d+)-(\d+)/ : (undef, undef, undef);

  if ($transcript) {
    my @exons        = sort {$a->start <=> $b->start} @{ $transcript->get_all_Exons || [] };
    if (@exons > 0) {
      if (defined( $transcript->coding_region_start ) && defined( $transcript->coding_region_end) ) {
        my $cover_next_e = 0;
        foreach my $e (@exons) {
    next if $e->start <= $transcript->coding_region_start && $e->end <= $transcript->coding_region_start;
          if (!$cover_next_e) {
            $start = $e->start <= $transcript->coding_region_start ? $transcript->coding_region_start : $e->start;
            $end   = $e->end   >= $transcript->coding_region_end   ? $transcript->coding_region_end   : $e->end;
            if (($end > $start) && ($end - $start + 1 < 200)) {
        $cover_next_e = 1;
            } 
    } else {
            $end   = $e->end   >= $transcript->coding_region_end   ? $transcript->coding_region_end   : $e->end;
            $cover_next_e = 0 unless ($end - $start + 1 < 200);
          }  
          last unless $cover_next_e;
        }
      } else {
        my $exon = $exons[0];
        ($start, $end) = ($exon->start, $exon->end); 
      }
    }
  }

  my $evidence_node = $self->get_node('Evidence');
  $evidence_node->set('caption', 'Supporting evidence ([[counts::supporting_evidence]])');
  $evidence_node->set('availability', 'gene has_supporting_evidence');

  my $compara_menu  = $self->get_node('Compara');
  my $genetree = $self->get_node('Compara_Tree');
  
  $genetree->set('components', [qw(
    tree_summary EnsEMBL::Web::Component::Gene::ComparaTreeSummary
    image EnsEMBL::Web::Component::Gene::ComparaTree
				   )
				]);

## VB
  my $expression_menu = $self->create_submenu('GeneExpression', 'Gene Expression');
  $expression_menu->append($self->create_node('GeneExpressionReporters', 'Reporters ([[counts::expression]])',
    [], { 'availability' => 'gene', 'url' => $SiteDefs::VECTORBASE_EXPRESSION_BROWSER . "/gene/" . $self->object->param('g'), 'raw' => 1 }
  ));

  my $regulation_node = $self->get_node('Regulation');
  $regulation_node->after($expression_menu);
## /VB

  # Graphical gene alignment:
  my $compara_align = $self->get_node('Compara_Alignments');
  $compara_align->set('caption', 'Genomic alignments (text)');
  my $compara_align_image = $self->create_node('Compara_Alignments/Image', 'Genomic alignments (image)',
    [qw(
      selector EnsEMBL::Web::Component::Compara_AlignSliceSelector
      bottom   EnsEMBL::Web::Component::Gene::Compara_AlignSliceBottom
    )],
    { 'availability' => 'gene database:compara core has_alignments' }
  );
  $compara_menu->append($compara_align_image);
  $compara_align->before($compara_align_image);
  #


  my $var_menu     = $self->get_node('Variation');

  my $r   = ($reg_name && $start && $end) ? $reg_name.':'.$start.'-'.$end : $gene->seq_region_name.':'.$gene->start.'-'.$gene->end;
  my $url = $hub->url({
                  type   => 'Gene',
                  action => 'Variation_Gene/Image',
                  g      => $hub->param('g') || $gene->stable_id,
                  r      => $r
  });

  my $variation_image = $self->get_node('Variation_Gene/Image');
  $variation_image->set('components', [qw( 
    imagetop EnsEMBL::Web::Component::Gene::VariationImageTop
    imagenav EnsEMBL::Web::Component::Gene::VariationImageNav
    image EnsEMBL::Web::Component::Gene::VariationImage )
             ]);
  $variation_image->set('availability', 'gene database:variation not_patch');
  $variation_image->set('url' =>  $url);

  $var_menu->append($variation_image);

  my $cdb_name = $self->hub->species_defs->COMPARA_DB_NAME || 'Comparative Genomics';

  $compara_menu->set('caption', $cdb_name);

  $compara_menu->append($self->create_subnode('Compara_Ortholog/PepSequence', 'Orthologue Sequences',
    [qw( alignment EnsEMBL::Web::Component::Gene::HomologSeq )],
           { 'availability'  => 'gene database:compara core has_orthologs', 'no_menu_entry' => 1 }
           ));

## VB
###----------------------------------------------------------------------
### Compara menu: alignments/orthologs/paralogs/trees
#  my $pancompara_menu = $self->create_submenu( 'PanCompara', 'Pan-taxonomic Compara' );
#
#
### Compara tree
#  my $tree_node = $self->create_node(
#    'Compara_Tree/pan_compara', "Gene Tree (image)",
#    [qw(image        EnsEMBL::Web::Component::Gene::ComparaTree)],
#    { 'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan' }
#  );
#  $tree_node->append( $self->create_subnode(
#    'Compara_Tree/Text_pan_compara', "Gene Tree (text)",
#    [qw(treetext        EnsEMBL::Web::Component::Gene::ComparaTree/text_pan_compara)],
#    { 'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan' }
#  ));
#
#  $tree_node->append( $self->create_subnode(
#    'Compara_Tree/Align_pan_compara',       "Gene Tree (alignment)",
#    [qw(treealign      EnsEMBL::Web::Component::Gene::ComparaTree/align_pan_compara)],
#    { 'availability' => 'gene database:compara_pan_ensembl core has_gene_tree_pan' }
#  ));
#  $pancompara_menu->append( $tree_node );
#
#
#  my $ol_node = $self->create_node(
#    'Compara_Ortholog/pan_compara',   "Orthologues ([[counts::orthologs_pan]])",
#    [qw(orthologues EnsEMBL::Web::Component::Gene::ComparaOrthologs)],
#    { 'availability' => 'gene database:compara_pan_ensembl core has_orthologs_pan',
#      'concise'      => 'Orthologues' }
#  );
#  $tree_node->append( $ol_node );
#  $ol_node->append( $self->create_subnode(
#    'Compara_Ortholog/Alignment_pan_compara', 'Orthologue Alignment',
#    [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
#    { 'availability'  => 'gene database:compara_pan_ensembl core',
#      'no_menu_entry' => 1 }
#  ));
#
#  $ol_node->append($self->create_subnode('Compara_Ortholog/PepSequence', 'Orthologue Sequences',
#    [qw( alignment EnsEMBL::Web::Component::Gene::HomologSeq )],
#           { 'availability'  => 'gene database:compara core has_orthologs', 'no_menu_entry' => 1 }
#           ));
#  my $pl_node = $self->create_node(
#    'Compara_Paralog/pan_compara',    "Paralogues ([[counts::paralogs_pan]])",
#    [qw(paralogues  EnsEMBL::Web::Component::Gene::ComparaParalogs)],
#    { 'availability' => 'gene database:compara_pan_ensembl core has_paralogs_pan',
#           'concise' => 'Paralogues' }
#  );
#  $tree_node->append( $pl_node );
#  $pl_node->append( $self->create_subnode(
#    'Compara_Paralog/Alignment_pan_compara', 'Paralog Alignment',
#    [qw(alignment EnsEMBL::Web::Component::Gene::HomologAlignment)],
#    { 'availability'  => 'gene database:compara core',
#      'no_menu_entry' => 1 }
#  ));
#  my $fam_node = $self->create_node(
#    'Family/pan_compara', 'Protein families ([[counts::families_pan]])',
#    [qw(family EnsEMBL::Web::Component::Gene::Family)],
#    { 'availability' => 'family_pan_ensembl' , 'concise' => 'Protein families' }
#  );
#  $pancompara_menu->append($fam_node);
#  my $sd = ref($self->{'object'}) ? $self->{'object'}->species_defs : undef;
#  my $name = $sd ? $sd->SPECIES_COMMON_NAME : '';
#  $fam_node->append($self->create_subnode(
#    'Family/Genes_pan_compara', uc($name).' genes in this family',
#    [qw(genes    EnsEMBL::Web::Component::Gene::FamilyGenes)],
#    { 'availability'  => 'family_pan_ensembl database:compara_pan_ensembl core', # database:compara core',
#      'no_menu_entry' => 1 }
#  ));
#  $fam_node->append($self->create_subnode(
#    'Family/Proteins_pan_compara', 'Proteins in this family',
#    [qw(ensembl EnsEMBL::Web::Component::Gene::FamilyProteins/ensembl_pan_compara
#        other   EnsEMBL::Web::Component::Gene::FamilyProteins/other_pan_compara)],
#    { 'availability'  => 'family_pan_ensembl database:compara_pan_ensembl core',
#      'no_menu_entry' => 1 }
#  ));
#  $fam_node->append($self->create_subnode(
#    'Family/Alignments_pan_compara', 'Multiple alignments in this family',
#    [qw(jalview EnsEMBL::Web::Component::Gene::FamilyAlignments)],
#    { 'availability'  => 'family_pan_ensembl database:compara_pan_ensembl core',
#      'no_menu_entry' => 1 }
#  ));
#
#  $tree_node->append($self->create_node('PanComparaSpecies', 'List of species',
#    [qw(pancompara_spec  EnsEMBL::Web::Component::Info::PanComparaSpecies)],
#                { 'availability' => 'gene database:compara_pan_ensembl core' }
#                ));
#
#### EG
#
#
#  $compara_menu->after($pancompara_menu);
## /VB
 
  # S4 DAS
## VB

  $compara_menu->before($self->create_node('Pathways', 'Pathways ([[counts::pathways]])',
    ['pathways', 'EnsEMBL::Web::Component::Gene::Pathways'],
    { 'availability' => 'gene has_pathways', 'concise' => 'Pathways' }
  ));

  $compara_menu->before($self->create_node("das/S4_PUBMED", 'PubMed ([[counts::pubmed]])',
    ['S4DASPUBMED', "EnsEMBL::Web::Component::Gene::S4DASPUBMED"], {
      availability => 'pubmed', 
      concise      => 'PubMed', 
    }
  ));
 
  # get all ontologies mapped to this species
  my $go_menu = $self->create_submenu('GO', 'Ontology');
  my %olist = map {$_ => 1} @{$species_defs->DISPLAY_ONTOLOGIES ||[]};

  if (%olist) {


     # get all ontologies available in the ontology db
     my %clusters = $species_defs->multiX('ONTOLOGIES');

     # get all the clusters that can generate a graph
     my @clist =  grep { $olist{ $clusters{$_}->{db} }} sort {$clusters{$a}->{db} cmp $clusters{$b}->{db}} keys %clusters; # Find if this ontology has been loaded into ontology db

     foreach my $oid (@clist) {
   my $cluster = $clusters{$oid};
   my $dbname = $cluster->{db};

   if ($dbname eq 'GO') {
       $dbname = 'GO|GO_to_gene';
   }
   my $go_hash  = $self->object ? $object->get_ontology_chart($dbname, $cluster->{root}) : {};
   next unless (%$go_hash);
   my @c = grep { $go_hash->{$_}->{selected} } keys %$go_hash;
   my $num = scalar(@c);
   
   my $url2 = $hub->url({
       type    => 'Gene',
       action  => 'Ontology/'.$oid,
       oid     => $oid
            });

   (my $desc2 = "$cluster->{db}: $cluster->{description}") =~ s/_/ /g;
   $go_menu->append($self->create_node('Ontology/'.$oid, "$desc2 ($num)",
               [qw( go EnsEMBL::Web::Component::Gene::Ontology )],
               { 'availability' => 'gene', 'concise' => $desc2, 'url' =>  $url2 }
        ));
   
     }
  }
  $compara_menu->before( $go_menu );
}

sub user_populate_tree {
    my $self        = shift;
    my $hub         = $self->hub;
    my $type        = $hub->type;
    my $all_das     = $hub->get_all_das;
    my $view_config = $hub->get_viewconfig('ExternalData');
    my @active_das  = grep { $view_config->get($_) eq 'yes' && $all_das->{$_} } $view_config->options;
    my $ext_node    = $self->tree->get_node('ExternalData');
  
    foreach (sort { lc($all_das->{$a}->caption) cmp lc($all_das->{$b}->caption) } @active_das) {
	my $source = $all_das->{$_};
    
    $ext_node->append($self->create_subnode("ExternalData/$_", $source->caption,
					    [ 'textdas', "EnsEMBL::Web::Component::${type}::TextDAS" ], {
        availability => lc $type, 
        concise      => $source->caption, 
        caption      => $source->caption, 
        full_caption => $source->label
	}
					    ));  
    }
}


1;
