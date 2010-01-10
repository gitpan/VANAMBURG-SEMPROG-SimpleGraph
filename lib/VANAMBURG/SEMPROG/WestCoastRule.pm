use MooseX::Declare;

class VANAMBURG::SEMPROG::WestCoastRule
    with VANAMBURG::SEMPROG::InferenceRule {

    method getqueries()
    {
	my @sfoq = qw/?company headquarters San_Francisco_California/;
	my @seaq = qw/?company headquarters Seattle_Washington/;
	my @laxq = qw/?company headquarters Los_Angelese_California/;
	my @porq = qw/?company headquarters Portland_Oregon/;

	my @result = (\@sfoq, \@seaq, \@laxq, \@porq);
	return \@result;
    }

    method maketriples($binding){
	return [ [$binding->{company}, 'on_coast', 'west_coast'] ];
    }
}

__END__

=head1 WestCoastRule

=head2 getqueries

  Returns array of queries. Each query is an array ref.


=head2 maketriples

    Returns sub, pred, obj in an array.

=cut
