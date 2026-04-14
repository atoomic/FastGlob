#!/usr/bin/env perl

# Test POSIX [!...] bracket negation in glob patterns.
# Regression: FastGlob treated ! as a literal character inside brackets
# instead of converting [!...] to regex [^...] for negation.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use FastGlob ();

my $dir = tempdir( DIR => '.', CLEANUP => 1 );

# Create single-letter files: a.txt through e.txt
for my $letter ('a' .. 'e') {
    open my $fh, '>', "$dir/$letter.txt" or die "Cannot create $dir/$letter.txt: $!";
    close $fh;
}

# [!abc].txt — should match d.txt and e.txt (negation)
{
    my @got    = FastGlob::glob("$dir/[!abc].txt");
    my @expect = sort CORE::glob("$dir/[!abc].txt");
    is_deeply( \@got, \@expect,
        '[!abc] negation matches files NOT in the set' );
    is( scalar @got, 2, '[!abc] returns exactly 2 matches (d, e)' );
}

# [abc].txt — positive match should still work
{
    my @got    = FastGlob::glob("$dir/[abc].txt");
    my @expect = sort CORE::glob("$dir/[abc].txt");
    is_deeply( \@got, \@expect,
        '[abc] positive match still works' );
    is( scalar @got, 3, '[abc] returns exactly 3 matches' );
}

# [!a-c].txt — negated range
{
    my @got    = FastGlob::glob("$dir/[!a-c].txt");
    my @expect = sort CORE::glob("$dir/[!a-c].txt");
    is_deeply( \@got, \@expect,
        '[!a-c] negated range works' );
    is( scalar @got, 2, '[!a-c] returns exactly 2 matches (d, e)' );
}

# [a-c].txt — positive range should still work
{
    my @got    = FastGlob::glob("$dir/[a-c].txt");
    my @expect = sort CORE::glob("$dir/[a-c].txt");
    is_deeply( \@got, \@expect,
        '[a-c] positive range still works' );
    is( scalar @got, 3, '[a-c] returns exactly 3 matches' );
}

# Edge: [!] should not break (single ! in brackets)
{
    my @got = FastGlob::glob("$dir/[!].txt");
    # [!] with no chars after ! is degenerate — just ensure no crash
    ok( defined \@got, '[!] degenerate case does not crash' );
}

done_testing;
