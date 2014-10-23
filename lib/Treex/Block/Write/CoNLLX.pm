package Treex::Block::Write::CoNLLX;
{
  $Treex::Block::Write::CoNLLX::VERSION = '0.07297';
}
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';
with 'Treex::Block::Write::Redirectable';

my %FALLBACK_FOR = ( 'pos' => 'tag', 'deprel' => 'afun', );

has '+language'                        => ( required => 1 );
has 'deprel_attribute'                 => ( is       => 'rw', isa => 'Str', default => 'autodetect' );
has 'pos_attribute'                    => ( is       => 'rw', isa => 'Str', default => 'autodetect' );
has 'cpos_attribute'                   => ( is       => 'rw', isa => 'Str', default => 'conll/cpos' );
has 'feat_attribute'                   => ( is       => 'rw', isa => 'Str', default => 'conll/feat' );
has 'is_member_within_afun'            => ( is       => 'rw', isa => 'Bool', default => 0 );
has 'is_shared_modifier_within_afun'   => ( is       => 'rw', isa => 'Bool', default => 0 );
has 'is_coord_conjunction_within_afun' => ( is       => 'rw', isa => 'Bool', default => 0 );

has _was => ( is => 'rw', default => sub{{}} );


sub process_atree {
    my ( $self, $atree ) = @_;
    foreach my $anode ( $atree->get_descendants( { ordered => 1 } ) ) {
        my ( $lemma, $pos, $cpos, $deprel ) =
            map { $self->get_attribute( $anode, $_ ) }
            qw(lemma pos cpos deprel);

        #my $ctag  = $self->get_coarse_grained_tag($tag);

        # append suffices to afuns
        my $suffix = '';
        $suffix .= 'M' if $self->is_member_within_afun            && $anode->is_member;
        $suffix .= 'S' if $self->is_shared_modifier_within_afun   && $anode->is_shared_modifier;
        $suffix .= 'C' if $self->is_coord_conjunction_within_afun && $anode->wild->{is_coord_conjunction};
        $deprel .= "_$suffix" if $suffix;

        my $feat;
        if ( $self->feat_attribute eq 'conll/feat' && defined $anode->conll_feat() ) {
            $feat = $anode->conll_feat();
        }
        elsif ( $self->feat_attribute eq 'iset' && $anode->get_iset_pairs_list() ) {
            my @list = $anode->get_iset_pairs_list();
            my @pairs;
            for ( my $i = 0; $i <= $#list; $i += 2 )
            {
                push( @pairs, "$list[$i]=$list[$i+1]" );
            }
            $feat = join( '|', @pairs );
        }
        else {
            $feat = '_';
        }
        my $p_ord = $anode->get_parent->ord;
        print { $self->_file_handle } join( "\t", $anode->ord, $anode->form, $lemma, $cpos, $pos, $feat, $p_ord, $deprel ) . "\n";
    }
    print { $self->_file_handle } "\n" if $atree->get_descendants;
    return;
}

sub get_attribute {
    my ( $self, $anode, $name ) = @_;
    my $from = $self->{ $name . '_attribute' } || $name;    # TODO don't expect blessed hashref
    my $value;
    if ( $from eq 'autodetect' ) {
        my $before = $self->_was->{$name};
        if ( !defined $before ) {
            $value = $anode->get_attr("conll/$from");
            if ( defined $value ) {
                $self->_was->{$name} = "conll/$from";
            }
            else {
                my $fallback = $FALLBACK_FOR{$name}
                    or log_fatal "No fallback for attribute $name";
                $value = $anode->get_attr($fallback);
                $self->_was->{$name} = $fallback;
            }
        }
        else {
            $value = $anode->get_attr($before);
            if ( !defined $value && $before =~ /^conll/ ) {
                my $id = $anode->get_address();
                log_warn "Attribute $before not defined in $id"
                    . " but it was filled in some previous nodes."
                    . " Consider Write::CoNLLX with parameter ${name}_attribute != autodetect.";
            }
        }
    }
    else {
        $value = $anode->get_attr($from);
    }

    return defined $value ? $value : '_';
}

sub get_coarse_grained_tag {
    my ( $self, $tag ) = @_;
    return substr $tag, 0, 2;
}

1;

__END__

=head1 NAME

Treex::Block::Write::CoNLLX

=head1 VERSION

version 0.07297

=head1 DESCRIPTION

Document writer for CoNLLX format, one token per line.

=head1 PARAMETERS

=over

=item encoding

Output encoding. C<utf8> by default.

=item to

The name of the output file, STDOUT by default.

=item deprel_attribute

The name of attribute which will be printed into the 8th column (dependency relation).
Default is C<autodetect> which tries first C<conll/deprel>
and if it is not defined then C<afun>.

=item pos_attribute

The name of attribute which will be printed into the 5th column (part-of-speech tag).
Default is C<autodetect> which tries first C<conll/pos>
and if it is not defined then C<tag>.

=item cpos_attribute

The name of attribute which will be printed into the 4th column
(coarse-grain part-of-speech tag).
Default is C<conll/cpos>.

=item feat_attribute

The name of attribute which will be printed into the 6th column (features).
Default is C<_> which means that an underscore will be printed instead of the features.
Possible values are C<conll/feat> and C<iset>.


=back

=head1 METHODS

=over

=item process_document

Saves the document.

=back

=head1 AUTHOR

David Mareček, Daniel Zeman, Martin Popel

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
