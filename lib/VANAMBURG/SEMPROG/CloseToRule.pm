use MooseX::Declare;

class VANAMBURG::SEMPROG::CloseToRule
    with VANAMBURG::SEMPROG::InferenceRule{


    method getqueries()
    {
	return [ ['?place', 'latitude', '?latitude'],
		 ['?place', 'longitude', '?longitude']
	    ];
    }

    method maketriples($binding)
    {
	my $distance =
	    sqrt
	    (
	     (69.1*($self->latitude - $binding->{latitude}))**2
	     +
	     (53*($self->longitude - $binding->{longitude}))**2
	    );

	if ($distance < 1){
	    return [[$self->place, 'close_to', $binding->{place}]];
	}else{
	    return [[$self->place, 'far_from', $binding->{place}]];
	}
    }

    has 'place' => (is=>'ro', required=>1);
    has 'graph' => (is=>'rw',
		    isa=>'VANAMBURG::SEMPROG::SimpleGraph',
		    required=>1);

    has 'latitude' => (isa=>'Num', is=>'rw');
    has 'longitude' => (isa=>'Num', is=>'rw');

    # must use 'sub' not 'method' to hook into Moose construction cycle.
    sub BUILD
    {
	my $self  = shift;

	my $lat =  $self->graph->value($self->place,'latitude',undef);
	$self->latitude($lat);

	my $lon = $self->graph->value($self->place, 'longitude', undef);
	$self->longitude($lon);
    }

}


__END__;


=head1 CloseToRule

=head2 BUILD

Initialize latitude and longitude based on parameters
passed in constructor.

=head2 getqueries

=head2 maketriples
