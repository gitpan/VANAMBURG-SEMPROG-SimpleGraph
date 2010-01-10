use MooseX::Declare;

class VANAMBURG::SEMPROG::GeocodeRule
    with VANAMBURG::SEMPROG::InferenceRule{

    use LWP::Simple qw/get/;
    use URI::Escape qw/uri_escape/;
    use English qw/ARG/;

    method getqueries()
    {
	return [ ['?place', 'address', '?address'] ];
    }


    method maketriples($binding)
    {
	my $address = uri_escape($binding->{address});
	my $geo_result = get("http://rpc.geocoder.us/service/csv?address=$address");
	my ($longitude, $latitude) = split ',', $geo_result;

	return [
	    [$binding->{place}, 'longitude', $longitude],
	    [$binding->{place},  'latitude', $latitude],
	    ];
    }

}


__END__;


=head1 GeocodeRule

A rule to retrieve  latitude and longitude for addresses and adds
two triples to the store.

=head2 getqueries

=head2 maketriples
