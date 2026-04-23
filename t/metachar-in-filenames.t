#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(basename);

use FastGlob ();

# Regex metacharacters in filenames must be treated as literal characters
# during glob-to-regex conversion.  Only glob-specific wildcards (*, ?, [])
# have special meaning; characters like ( ) $ ^ are ordinary.

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die "chdir: $!";

# --- helper ---
sub touch { open my $fh, '>', $_[0] or die "touch $_[0]: $!"; close $fh }
sub basenames { sort map { basename($_) } @_ }

# --- create test files ---

touch('file(1).txt');
touch('file(2).txt');
touch('normal.txt');

# Parentheses — balanced, with wildcard
{
    my @got = FastGlob::glob('file(*).*');
    is_deeply(
        [basenames(@got)],
        [qw(file(1).txt file(2).txt)],
        'file(*).*  — parens are literal, * matches inside'
    );
}

# Parentheses — balanced, no wildcard (literal path component)
{
    my @got = FastGlob::glob('file(1).txt');
    is_deeply(
        [basenames(@got)],
        [qw(file(1).txt)],
        'file(1).txt — exact literal match with parens'
    );
}

# Parentheses — literal parens with adjacent wildcard
{
    my @got = FastGlob::glob('file(1).*');
    is_deeply(
        [basenames(@got)],
        [qw(file(1).txt)],
        'file(1).* — parens literal, wildcard matches extension'
    );
}

# Caret in filename
SKIP: {
    touch('^start.txt');
    my @got = FastGlob::glob('^*');
    is_deeply(
        [basenames(@got)],
        [qw(^start.txt)],
        '^*  — caret is literal, not regex anchor'
    );
}

# Dollar sign in filename
SKIP: {
    my $file = 'price$5.txt';
    my $created = eval { touch($file); 1 };
    skip 'cannot create file with $ in name', 1 unless $created && -e $file;

    my @got = FastGlob::glob('price$*');
    is_deeply(
        [basenames(@got)],
        [$file],
        'price$*  — dollar sign is literal, not regex anchor'
    );
}

# Combination: parens + dollar + caret in one pattern
SKIP: {
    my $file = '(test$1)^2.dat';
    my $created = eval { touch($file); 1 };
    skip 'cannot create file with mixed metachars', 1 unless $created && -e $file;

    my @got = FastGlob::glob('(test$1)^2.*');
    is_deeply(
        [basenames(@got)],
        [$file],
        '(test$1)^2.* — all metachars literal in single component'
    );
}

done_testing;
