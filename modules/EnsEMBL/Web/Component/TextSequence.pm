# $Id: TextSequence.pm,v 1.5 2014-01-23 16:25:18 nl2 Exp $

package EnsEMBL::Web::Component::TextSequence;

sub tool_buttons {
  my ($self, $blast_seq, $species, $peptide) = @_;

  return unless $self->html_format;
  
  my $hub  = $self->hub;
  my $html = sprintf('
    <div class="other_tool">
      <p><a class="seq_export export" href="%s">Download view as RTF</a></p>
    </div>', 
    $self->ajax_url('rtf', { filename => join('_', $hub->type, $hub->action, $hub->species, $self->object->Obj->stable_id), _format => 'RTF' })
  );

## VB  
#  if ($blast_seq && $hub->species_defs->ENSEMBL_BLAST_ENABLED) {
#    $html .= sprintf('
#      <div class="other_tool">
#        <p><a class="seq_blast find" href="#">BLAST this sequence</a></p>
#        <form class="external hidden seq_blast" action="/Multi/blastview" method="post">
#          <fieldset>
#            <input type="hidden" name="_query_sequence" value="%s" />
#            <input type="hidden" name="species" value="%s" />
#            %s
#          </fieldset>
#        </form>
#      </div>',
#      $blast_seq, $hub->species, $peptide ? '<input type="hidden" name="query" value="peptide" /><input type="hidden" name="database" value="peptide" />' : ''
#    );
#  }
#  
#  return $html;
## /VB
}

1;
