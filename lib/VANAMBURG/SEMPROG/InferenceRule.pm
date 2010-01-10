use MooseX::Declare;

role VANAMBURG::SEMPROG::InferenceRule{

    requires qw/getqueries maketriples/;

}


__END__


=head1 VANAMBURG::SEMPROG::InferenceRule

Used as an abstract base class to require two methods
in InferenceRule implementations.

=over 4

=item *

getqueries

=item *

maketriples

=back

=cut

