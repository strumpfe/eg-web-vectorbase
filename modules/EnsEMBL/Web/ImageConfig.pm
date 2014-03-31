package EnsEMBL::Web::ImageConfig;

use strict;

sub menus {
  return $_[0]->{'menus'} ||= {
    # Sequence
    seq_assembly        => 'Sequence and assembly',
    sequence            => [ 'Sequence',                'seq_assembly' ],
    misc_feature        => [ 'Clones & misc. regions',  'seq_assembly' ],
    genome_attribs      => [ 'Genome attributes',       'seq_assembly' ],
    marker              => [ 'Markers',                 'seq_assembly' ],
    simple              => [ 'Simple features',         'seq_assembly' ],
    ditag               => [ 'Ditag features',          'seq_assembly' ],
    dna_align_other     => [ 'GRC alignments',          'seq_assembly' ],
    dna_align_compara   => [ 'Imported alignments',     'seq_assembly' ],
    
    # Transcripts/Genes
    gene_transcript     => 'Genes and transcripts',
    transcript          => [ 'Genes',                  'gene_transcript' ],
    prediction          => [ 'Prediction transcripts', 'gene_transcript' ],
    lrg                 => [ 'LRG transcripts',        'gene_transcript' ],
    rnaseq              => [ 'RNASeq models',         'gene_transcript' ],
## VB    
    cap                 => [ 'Community annotations', 'gene_transcript' ],
## /VB
    
    # Supporting evidence
    splice_sites        => 'Splice sites',
    evidence            => 'Evidence',
    
    # Alignments
    mrna_prot           => 'mRNA and protein alignments',
    dna_align_cdna      => [ 'mRNA alignments',    'mrna_prot' ],
    dna_align_est       => [ 'EST alignments',     'mrna_prot' ],
    protein_align       => [ 'Protein alignments', 'mrna_prot' ],
    protein_feature     => [ 'Protein features',   'mrna_prot' ],
    dna_align_rna       => 'ncRNA',
## VB
    rnaseq_align        => 'RNAseq alignments',
## /VB
    
    # Proteins
    domain              => 'Protein domains',
    gsv_domain          => 'Protein domains',
    feature             => 'Protein features',
    
    # Variations
    variation           => 'Variation',
    recombination       => [ 'Recombination & Accessibility', 'variation' ],    
    somatic             => 'Somatic mutations',
    ld_population       => 'Population features',
    
    # Regulation
    functional          => 'Regulation',
    
    # Compara
    compara             => 'Comparative genomics',
    pairwise_blastz     => [ 'BLASTz/LASTz alignments',    'compara' ],
    pairwise_other      => [ 'Pairwise alignment',         'compara' ],
    pairwise_tblat      => [ 'Translated blat alignments', 'compara' ],
    multiple_align      => [ 'Multiple alignments',        'compara' ],
    conservation        => [ 'Conservation regions',       'compara' ],
    synteny             => 'Synteny',
    
    # Other features
    repeat              => 'Repeat regions',
    oligo               => 'Oligo probes',
    trans_associated    => 'Transcript features',
        
    # Info/decorations
    information         => 'Information',
    decorations         => 'Additional decorations',
    other               => 'Additional decorations',
    
    # External data
    user_data           => 'Your data',
    external_data       => 'External data',
  };
}

sub add_oligo_probes {
  my ($self, $key, $hashref) = @_;
  my $menu = $self->get_node('oligo');

  return unless $menu;

  my $data = $hashref->{'oligo_feature'}{'arrays'};
## VB
  #my $description = $hashref->{'oligo_feature'}{'analyses'}{'AlignAffy'}{'desc'};  # Different loop - no analyses - base on probeset query results
##
  foreach my $key_2 (sort keys %$data) {
    my $key_3 = $key_2;
    $key_2    =~ s/:/__/;

## VB
    my $description = $hashref->{'oligo_feature'}{'descriptions'}{$key_3};
##

    $menu->append($self->create_track("oligo_${key}_" . uc $key_2, $key_3, {
      glyphset    => '_oligo',
      db          => $key,
      sub_type    => 'oligo',
      array       => $key_2,
      object_type => 'ProbeFeature',
      colourset   => 'feature',
      description => $description,
      caption     => $key_3,
      strand      => 'b',
      display     => 'off',
      renderers   => $self->{'alignment_renderers'}
    }));
  }
}


1;
