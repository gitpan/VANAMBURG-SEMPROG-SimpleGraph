#!perl -T
use strict;
use Test::More tests => 1;
use VANAMBURG::SEMPROG::SimpleGraph;

my $bg = VANAMBURG::SEMPROG::SimpleGraph->new();
$bg->load('data/business_triples.csv');

# find investment banks
my @ibanks = map { $_->[0] } 
   $bg->triples(undef, 'industry', 'Investment Banking');
diag(">>> there are ".@ibanks." investment banks.");

ok (1 == 1, "one is one");

#print " Contribution nodes from investment banks:"
#bank_contrib = {}
#for b in ibanks:
#    bank_contrib[b] = [ t[0] for t in bg.triples((None, 'contributor', b)) ]
#print bank_contrib


#print " Contributions from investment banks to politicians"
#for b, contribs in bank_contrib.items():
#    for contrib in contribs:
#        print [t[2] for t in bg.triples((contrib, None, None))]

