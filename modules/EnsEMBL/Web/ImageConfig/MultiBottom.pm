package EnsEMBL::Web::ImageConfig::MultiBottom;

use strict;

sub init {
  my $self = shift;
  
  $self->set_parameters({
    sortable_tracks => 1,  # allow the user to reorder tracks
    opt_lines       => 1,  # register lines
    spritelib       => { default => $self->species_defs->ENSEMBL_SERVERROOT . '/htdocs/img/sprites' }
  });

  # Add menus in the order you want them for this display
## VB  
  $self->create_menus(qw(
    sequence
    marker
    transcript
    prediction
    dna_align_cdna
    dna_align_est 
    dna_align_rna 
    dna_align_other 
    protein_align
    rnaseq
    rnaseq_align
    simple
    misc_feature
    variation 
    somatic 
    functional
    cap
    oligo
    repeat
    user_data
    decorations 
    information 
  ));
## /VB
  
  # Add in additional tracks
  $self->load_tracks;
  $self->load_configured_das;
  $self->image_resize = 1;
  
  $self->add_tracks('sequence', 
    [ 'contig', 'Contigs',  'contig',   { display => 'normal', strand => 'r', description => 'Track showing underlying assembly contigs' }],
    [ 'seq',    'Sequence', 'sequence', { display => 'normal', strand => 'b', description => 'Track showing sequence in both directions. Only displayed at 1Kb and below.', colourset => 'seq', threshold => 1, depth => 1 }],
  );
  
  $self->add_tracks('decorations',
    [ 'scalebar',  '', 'scalebar',   { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',      { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable',  { display => 'normal', strand => 'b', menu => 'no' }],
    [ 'nav',       '', 'navigation', { display => 'normal', strand => 'b', menu => 'no' }]
  );
  
  $_->set('display', 'off') for grep $_->id =~ /^chr_band_/, $self->get_node('decorations')->nodes; # Turn off chromosome bands by default
}

1;
