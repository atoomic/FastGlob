#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FastGlob ();

ok( FastGlob->can('glob'),        'can glob' );
ok( FastGlob->can('recurseglob'), 'can recurseglob' );

sub globtest(;$) {

    my ( @t0, @t1, $udiffm, $sdiffm, $udiffg, $sdiffg, @list1, @list2 );
    local ($,);
    my $res = 1;

    $, = " ";
    while (<DATA>) {
        chomp;

        note "pattern: $_\n";
        if ( $_ =~ m{^#} ) {
          note " test skipped... TODO";
          next;
        }

        # On Windows, CORE::glob resolves relative components (../)
        # even when the leading path does not exist, producing results
        # that differ from FastGlob (which correctly returns empty).
        # Skip these patterns on Windows to avoid false failures.
        if ( $^O eq 'MSWin32' && /~\w+.*\.\./ ) {
          note " skipping on Windows (tilde-path with ..): $_";
          next;
        }

        @t0     = times();
        @list1  = FastGlob::glob($_);
        @t1     = times();

        $udiffm = ( $t1[0] + $t1[2] ) - ( $t0[0] + $t0[2] );
        $sdiffm = ( $t1[1] + $t1[3] ) - ( $t0[1] + $t0[3] );

        @t0     = times();
        @list2  = glob($_);
        @t1     = times();
        $udiffg = ( $t1[0] + $t1[2] ) - ( $t0[0] + $t0[2] );
        $sdiffg = ( $t1[1] + $t1[3] ) - ( $t0[1] + $t0[3] );

        is(  join( ' ', sort(@list1) ), join( ' ', sort(@list2) ), 'results match for '.join( ' ', @list1 ) )
          or diag "GOT: ", explain \@list1, "EXPECT: ", explain \@list2;

        note "mine: [${udiffm}u\t${sdiffm}s]";
        note "glob: [${udiffg}u\t${sdiffg}s]\n";
    }
}

globtest();

pass 'done';

# Tilde expansion tests — the module supports ~ and ~user patterns (lines 108-122)
# but they were completely untested.
SKIP: {
    my $has_getpwent = eval { getpwent(); 1 };
    endpwent() if $has_getpwent;

    skip 'getpwent not available on this platform', 4 unless $has_getpwent;

    # ~ expands to current user's home directory
    my @home = getpwuid($<);
    my $homedir = $home[7];

    skip 'cannot determine home directory', 4 unless $homedir && -d $homedir;

    my @tilde_results = FastGlob::glob('~');
    is( scalar @tilde_results, 1, '~ expands to exactly one entry' );
    is( $tilde_results[0], $homedir, '~ expands to current user home directory' );

    # ~root expands to root's home directory (named user)
    my @root_pw = getpwnam('root');
    skip 'root user not available', 2 unless @root_pw && $root_pw[7] && -d $root_pw[7];

    my @root_results = FastGlob::glob('~root');
    is( scalar @root_results, 1, '~root expands to exactly one entry' );
    is( $root_results[0], $root_pw[7], '~root expands to root home directory' );
}

done_testing;

__DATA__
*
*[Gg]lob*
./*
./*[Gg]lob*
#[^F]*
../*
../../.p*
#~mengel
#~lisa
bogus{1,2,3}
#~{mengel,lisa}/../{me,li}*
#/*/tmp/*x*
/afs/fnal/products/*/ftt
/usr/tmp/*
/usr//tmp/*
.././*.c
????????.??*
{ou,????????.??}*
