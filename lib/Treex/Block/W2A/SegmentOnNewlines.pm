package Treex::Block::W2A::SegmentOnNewlines;
{
  $Treex::Block::W2A::SegmentOnNewlines::VERSION = '0.07194';
}
use Moose;
use Treex::Core::Common;
extends 'Treex::Core::Block';

has '+language' => ( required => 1 );

has [qw(allow_empty_sentences delete_empty_sentences )] => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub process_document {
    my ( $self, $document ) = @_;
    my $doczone = $document->get_zone( $self->language, $self->selector );
    log_fatal 'The document does not contain a ' . $self->_doczone_name if !$doczone;
    my $text = $doczone->text;
    log_fatal $self->_doczone_name . ' contains no "text" attribute' if !defined $text;

    my @sentences;
    foreach my $sentence ( map { $self->normalize_sentence($_) } $self->get_segments($text) ) {
        if ( $sentence eq '' ) {
            if ( $self->delete_empty_sentences ) {
            }
            elsif ( !$self->allow_empty_sentences ) {
                log_fatal 'text in ' . $self->_doczone_name
                    . ' contains empty sentences. Consider using'
                    . ' the (allow|delete)_empty_sentences option.';
            }
            else {
                push @sentences, '';
            }
        }
        else {
            push @sentences, $sentence;
        }
    }

    # Segmentation blocks should work when the document contains
    # a) no bundles (typical case)
    # b) same number of bundles as the @sentences
    #    The bundles were perhaps created by segmentation of another language.
    my @bundles = $document->get_bundles();
    if ( !@bundles ) {
        @bundles = map { $document->create_bundle() } @sentences;
    }
    elsif ( @bundles != @sentences ) {
        log_fatal 'The document already contained bundles, but the number'
            . ' of bundles is different than the number of sentences segmented'
            . ' from the' . $self->_doczone_name;
    }
    while (@bundles) {
        my $bundle = shift @bundles;
        my $zone = $bundle->create_zone( $self->language, $self->selector );
        $zone->set_sentence( shift @sentences );
    }
    return 1;
}

sub _doczone_name {
    my ($self) = @_;
    return 'DocZone for language='
        . $self->language
        . ( $self->selector ne '' ? ' selector=' . $self->selector : '' );
}

sub get_segments {
    my ( $self, $text ) = @_;
    return split /\n/, $text;
}

sub normalize_sentence {
    my ( $self, $sentence ) = @_;

    # This method can be overriden.
    # However, since this class serves as an ancestor for other segmentation blocks,
    # it is questionable what should be the default behavior.
    # Should we preserve the original sentence
    # and handle the normalization within tokenization blocks?
    # Or do we want to have also the sentences tidy?
    $sentence =~ s/[\s\xa0]/ /g;    # get rid of tabs or nbsp
    $sentence =~ s/  +/ /g;
    $sentence =~ s/^ +| +$//g;      # trim, including nbsp
    return $sentence;
}

1;

__END__

TODO: has to be reviewed

=encoding utf-8

=head1 NAME

Treex::Block::W2A::SegmentOnNewlines - segment text on new lines

=head1 VERSION

version 0.07194

=head1 DESCRIPTION

The source text is segmented into sentences which are stored in document bundles.
If the document contained no bundles, the bundles are created.
Otherwise, the document must contain the same number of bundles as the number of
sentences (segmented by this blocks).
This means that this block (or its derivatives) can be used in this way:

    treex Read::Text language=en from=en.txt \
          Read::Text language=de from=de.txt \
          W2A::SegmentOnNewlines language=en \
          W2A::SegmentOnNewlines language=de \
          ...

This class detects sentences based on the newlines in the source text,
but it can be used as an ancestor for more apropriate segmentations
by overriding the method C<segment_text>.

=head1 ATTRIBUTES

=over 4

=item allow_empty_sentences

If set, empty sentences can be produced.

=item delete_empty_sentences

If set, empty sentences are automatically deleted.

=back

If none of the previous attributes is set and empty sentence found, fatal is raised.

=head1 METHODS

=over 4

=item get_segments()

This method produces segments from text given as parameter, can be overriden.

=item normalize_sentence()

This method does sentence normalization e.g. trims initial and terminal whitespaces.

=back

=head1 AUTHOR

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2011 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
