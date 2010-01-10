use MooseX::Declare;

class VANAMBURG::SEMPROG::TouristyRule
    with VANAMBURG::SEMPROG::InferenceRule{

    method getqueries()
    {
	return [
	    ['?ta', 'is_a', 'Tourist Attraction'],
	    ['?ta', 'close_to', '?restaurant'],
	    ['?restaurant', 'is_a', 'restaurant'],
	    ['?restaurant', 'cost', 'cheap'],
	    ];
    }


    method maketriples($binding)
    {
	return [[$binding->{restaurant}, 'is_a', 'touristy restaurant']];
    }

}

__END__;


=head1 TouristyRule

=head2 getqueries

=head2 maketriples
