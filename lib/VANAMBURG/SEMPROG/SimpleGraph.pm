package VANAMBURG::SEMPROG::SimpleGraph;

use vars qw($VERSION);
$VERSION = '0.002';

use Moose;
use Text::CSV_XS;
use Set::Scalar;
use List::MoreUtils qw(each_array);

use English;

use Data::Dumper;

#
# Store triples in nested hashrefs with a Set::Scalar instance
# at the leafe nodes.
# Keep several hashes for accessing based on need
# in calls to 'triples' method.  Three indexes are:
#   1) subject, then predicate then object, or
#   2) predicate, object, then subject,
#   3) object, then subject then predicate.
#

has '_spo' => (isa => 'HashRef', is => 'rw', default => sub { {} });
has '_pos' => (isa => 'HashRef', is => 'rw', default => sub { {} });
has '_osp' => (isa => 'HashRef', is => 'rw', default => sub { {} });

sub add
{
    my ($self, $sub, $pred, $obj) = @_;

    $self->_addToIndex($self->_spo(), $sub,  $pred, $obj);
    $self->_addToIndex($self->_pos(), $pred, $obj,  $sub);
    $self->_addToIndex($self->_osp(), $obj,  $sub,  $pred);
}

sub _addToIndex
{
    my ($self, $index, $a, $b, $c) = @ARG;

    return if (!defined($a) || !defined($b) || !defined($c));

    if (!defined($index->{$a}->{$b}))
    {
        my $set = Set::Scalar->new();
        $set->insert($c);
        $index->{$a}->{$b} = $set;
    }
    else
    {
        $index->{$a}->{$b}->insert($c);
    }
}

sub remove
{
    my ($self, $sub, $pred, $obj) = @ARG;

    my @tripls = $self->triples($sub, $pred, $obj);
    for my $t (@tripls)
    {
        $self->_removeFromIndex($self->_spo(), $t->[0], $t->[1], $t->[2]);
        $self->_removeFromIndex($self->_pos(), $t->[1], $t->[2], $t->[0]);
        $self->_removeFromIndex($self->_osp(), $t->[2], $t->[0], $t->[1]);
    }
}

sub _removeFromIndex
{
    my ($self, $index, $a, $b, $c) = @ARG;

    eval {
        my $bs   = $index->{$a};
        my $cset = $bs->{$b};
        $cset->delete($c);
        delete $bs->{$b} if ($cset->size == 0);
        delete $index->{$a} if (keys(%$bs) == 0);
    };
    if ($EVAL_ERROR) { print "ERROR: $EVAL_ERROR\n"; }
}

sub triples
{
    my ($self, $sub, $pred, $obj) = @ARG;

    my @result;

    # check which terms are present in order to use the correct index:

    if (defined($sub))
    {
        if (defined($pred))
        {

            # sub pred obj
            if (defined($obj) && defined($self->_spo()->{$sub}->{$pred}))
            {
                push @result, [$sub, $pred, $obj]
                  if ($self->_spo()->{$sub}->{$pred}->has($obj));

            }
            else
            {

                # sub pred undef
                map { push @result, [$sub, $pred, $_]; }
                  $self->_spo()->{$sub}->{$pred}->members()
                  if defined($self->_spo()->{$sub}->{$pred});
            }
        }
        else
        {

            # sub undef obj
            if (defined($obj) && defined($self->_osp()->{$obj}->{$sub}))
            {
                map { push @result, [$sub, $obj, $_]; }
                  $self->_osp()->{$obj}->{$sub}->members();
            }
            else
            {

                # sub undef undef
                while (my ($retPred, $objSet) = each %{$self->_spo()->{$sub}})
                {
                    map { push @result, [$sub, $retPred, $_]; }
                      $objSet->members();
                }
            }
        }
    }
    else
    {
        if (defined($pred))
        {

            # undef pred obj
            if (defined($obj))
            {

                map { push @result, [$_, $pred, $obj] }
                  $self->_pos()->{$pred}->{$obj}->members()
                  if (defined($self->_pos()->{$pred}->{$obj}));
            }
            else
            {

                # undef pred undef
                while (my ($retObj, $subSet) = each %{$self->_pos()->{$pred}})
                {
                    map { push @result, [$_, $pred, $retObj]; }
                      $subSet->members();
                }
            }
        }
        else
        {

            # undef undef obj
            if (defined($obj))
            {
                while (my ($retSub, $predSet) = each %{$self->_osp()->{$obj}})
                {
                    map { push @result, [$retSub, $_, $obj]; }
                      $predSet->members();
                }
            }
            else
            {

                # undef undef undef
                while (my ($retSub, $predSet) = each %{$self->_spo()})
                {
                    while (my ($retPred, $objSet) = each %{$predSet})
                    {
                        map { push @result, [$retSub, $retPred, $_]; }
                          $objSet->members();
                    }
                }
            }
        }

    }

    return @result;
}

sub value
{
    my ($self, $kwargs) = @ARG;

    for my $t ($self->triples($kwargs->{sub}, $kwargs->{pred}, $kwargs->{obj}))
    {
        return $t->[0] if !defined($kwargs->{sub});
        return $t->[1] if !defined($kwargs->{pred});
        return $t->[2] if !defined($kwargs->{obj});
        last;
    }
}

sub load
{
    my ($self, $filename) = @ARG;

    my $csv = Text::CSV_XS->new(
                      {allow_whitespace => 1, binary => 1, blank_is_undef => 1})
      or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

    open my $fh, "<:encoding(utf8)", $filename or die "$!";

    while (my $row = $csv->getline($fh))
    {
        $self->add($row->[0], $row->[1], $row->[2]);
    }

    close $fh or die "$!";
}

sub save
{
    my ($self, $filename) = @ARG;
    open my $fh, ">", $filename or die "Cannot open file for save: $!";
    my $csv = Text::CSV_XS->new({allow_whitespace => 1, blank_is_undef => 1})
      or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
    $csv->eol("\r\n");
    $csv->print($fh, $_)
      or csv->error_diag()
      for $self->triples(undef, undef, undef);
    close $fh or die "Cannot close file for save: $!";
}

sub query
{
    my ($self, $clauses) = @ARG;

    my @bindings;

    my @trpl_inx = (0 .. 2);

    $DB::single = 2;

    for my $clause (@$clauses)
    {
        my %bpos;
        my @qparams;
        my @rows;

        # Check each three indexes of clause to see if
        # it is a binding variable (starts with '?').
        # Generate a store for the binding variables,
        # implimented as a hash keyed by binding variable name,
        # and holding the triple index indicating if it
        # represents a subject, predicate, or object.
        #
        # Also define parameters for subsequent call to
        # 'triples'.

        my $each = each_array(@$clause, @trpl_inx);
        while (my ($x, $pos) = $each->())
        {
            if ($x =~ /^\?/)
            {
                push @qparams, undef;
                my $key = substr($x, 1);
                $bpos{$key} = $pos;
            }
            else
            {
                push @qparams, $x;
            }
        }

        @rows = $self->triples($qparams[0], $qparams[1], $qparams[2]);
        if (!@bindings)
        {
            for my $row (@rows)
            {
                my %binding;
                while (my ($var, $pos) = each %bpos)
                {
                    $binding{$var} = $row->[$pos];
                }

                push @bindings, \%binding;
            }
        }
        else
        {
            my @newb;
            for my $binding (@bindings)
            {
                for my $row (@rows)
                {
                    my $validmatch  = 1;
                    my %tempbinding = %$binding;
                    while (my ($var, $pos) = each %bpos)
                    {
                        if (defined($tempbinding{$var}))
                        {
                            if ($tempbinding{$var} ne $row->[$pos])
                            {
                                $validmatch = 0;
                            }
                        }
                        else
                        {
                            $tempbinding{$var} = $row->[$pos];
                        }
                    }
                    if ($validmatch)
                    {
                        $DB::single = 2;
                        push @newb, \%tempbinding;
                    }

                }
                $DB::single = 2;

            }
            @bindings = @newb;
        }
    }
    return @bindings;
}

sub applyinference
{
    my ($self, $rule) = @ARG;

    my @bindings = $self->query($rule->getqueries());

    for my $binding (@bindings){
	for my $triple ( @{$rule->maketriples($binding)} ) {
	    $self->add( @$triple );
	}
    }

}

1;

__END__


=head1 SYNOPSIS

A Perl interpretation of the SimpleGraph developed in Python by Toby Segaran in his book "Programming the Semantic Web", published by O'Reilly, 2009.  CPAN modules are used in place of the Python standard library modules used by Mr. Segaran.

    my $graph = VANAMBURG::SEMPROG::SimpleGraph->new();

    $graph->load("data/place_triples.txt");

    $graph->add("Morgan Stanley", "headquarters", "New_York_New_York");

    my @sanfran_key = $graph->value({
       sub=>undef, pred=>'name', obj=>'San Francisco'
    });

    my @sanfran_triples = $graph->triples($sanfram_key, undef, undef);

    my @bindings = $g->query([
       ['?company', 'headquarters', 'New_York_New_York'],
       ['?company', 'industry',     'Investment Banking'],
       ['?contrib', 'contributor',  '?company'],
       ['?contrib', 'recipient',    'Orrin Hatch'],
       ['?contrib', 'amount',       '?dollars'],
    ]);

    for my $binding (@bindings){
       printf "company=%s, contrib=%s, dollars=%s\n", 
           ($binding->{company},$binding->{contrib},$binding->{dollars});
    }
    

    $graph->applyinference( VANAMBURG::SEMPROG::GeocodeRule->new() );


=head1 SimpleGraph

   
This module and it's test suite is inspired by the simple triple store implimentation
developed in chapters 2 and 3 of "Programming the Semantic Web" by Toby Segaran, 
Evans Colin, Taylor Jamie, 2009, O'Reilly.  Mr. Segaran uses Python and 
it's standard library to show the workins of a triple store.  This module 
and it's test make the same demonstration using Perl and CPAN modules, which 
may be thought of as a Perl companion to the book for readers who are interested in Perl.

In addition to SimpleGraph, the triple store, the other exercises presented in chapters 2 and 3 are here interpreted as a set of perl test programs, using
Test::More and are found in the modules 't/' directory.
    

B<Triple Store Modules>

    lib/VANAMBURG/SEMPROG/SimpleGraph.pm
    
    lib/VANAMBURG/SEMPROG/CloseToRule.pm
    lib/VANAMBURG/SEMPROG/GeocodeRule.pm
    lib/VANAMBURG/SEMPROG/InferenceRule.pm    
    lib/VANAMBURG/SEMPROG/TouristyRule.pm
    lib/VANAMBURG/SEMPROG/WestCoastRule.pm

B<Module Usage Shown in Tests>

    t/semprog_ch02_03_places.t
    t/semprog_ch02_04_celebs.t
    t/semprog_ch02_05_business.t
    t/semprog_ch02_moviegraph.t
    t/semprog_ch03_01_queries.t
    t/semprog_ch03_02_inference.t
    t/semprog_ch03_03_chain_of_rules.t
    t/semprog_ch03_04_shortest_path.t
    t/semprog_ch03_05_join_graph.t
    qt/semprog_ch03_chain_of_rules.t


Find out more about, or get the book at http://semprog.com, the Semantic Programming web site.

=head1 INSTALLATION NOTES

This module can be installed via cpan.  This method resolves dependency
issues and is convenient. In brief, it looks something like this in a 
terminal on linux:
 
  $sudo cpan
  cpan>install VANAMBURG::SEMPROG::SimpleGraph
  ...
  cpan>quit
  $

All dependencies, as well as the modules are now installed.  Leave out 'sudo' if using Strawberry perl on Windows.

You can then download the source package and read and run the test programs.

  $tar xzvf VANAMBURG-SEMPROG-SimpleGraph-0.001.tar.gz
  $cd VANAMBURG-SEMPROG-SimpleGraph-0.001/  
  $ perl Makefile.PL
  ...
  $make
  ...

Run 'dmake' instead of 'make' if using Strawberry Perl on Windows.

To run all the test programs:
 
  $make test

  -- Note that some tests require internet access for geo code data.

To run one test:

  $prove -Tvl lib - t/semprog_ch03_05_join_graph.t 

=head1 METHODS

=head2 add

Adds a triple to the graph.

    $g->add("San Francisco", "inside", "California");
    $g->add("Ann Arbor", "inside", "Michigan");

=head2 remove

Remove a triple pattern from the graph.    

    # remove all triples with predicate "inside"
    $g->remove(undef, "inside", undef);


=head2 triples

    # retrieve all triples with predicate "inside"
    my @triples = $g->triples(undef, "inside", undef);

    # @triples looks like this:
    #  [ 
    #    ["San Francisco", "inside", "California"],
    #    ["Ann Arbor", "inside", "Michigan"],
    #  ]

=head2 value

Retrieve a single value from a triple.

    my $x = $g->value(undef, 'inside', 'Michigan');
    # $x contains "Ann Arbor" given examples added.


=head2 query

Returns array of hashrefs where keys are binding variables for triples.

    my @bindings = $g->query([
	['?company','headquarters','New_York_New_York'],
	['?company','industry','Investment Banking'],
	['?cont','contributor','?company'],
	['?cont', 'recipient', 'Orrin Hatch'],
	['?cont', 'amount', '?dollars'],
    ]);

=head2 applyinference

Given an InferenceRule, generates additional triples in the triple store.


=head2 load
 
Loads a csv file in utf8 encoding.

    $g->load("some/file.csv");

=head2 save
 
Saves a csv file in utf8 encoding.

    $g->load("some/file.csv");

=head2 _addToIndex

See source for details.


=head2 _removeFromIndex

        Removes a triple from an index and clears up empty indermediate structures.


=cut 
