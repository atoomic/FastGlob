#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use FastGlob ();

# Test ** (globstar) matching: zero or more directory levels.

my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );

# Build a deep directory tree:
#   $tmpdir/
#     src/
#       main.c
#       lib/
#         util.c
#         helper.c
#         deep/
#           core.c
#     docs/
#       readme.txt
#     top.c
#     .hidden/
#       secret.c

my @dirs = (
    "$tmpdir/src",
    "$tmpdir/src/lib",
    "$tmpdir/src/lib/deep",
    "$tmpdir/docs",
    "$tmpdir/.hidden",
);
make_path(@dirs);

my @files = (
    "$tmpdir/src/main.c",
    "$tmpdir/src/lib/util.c",
    "$tmpdir/src/lib/helper.c",
    "$tmpdir/src/lib/deep/core.c",
    "$tmpdir/docs/readme.txt",
    "$tmpdir/top.c",
    "$tmpdir/.hidden/secret.c",
);
for my $f (@files) {
    open my $fh, '>', $f or die "Cannot create $f: $!";
    close $fh;
}

sub rel {
    my @sorted = sort @_;
    my @out;
    for (@sorted) {
        my $r = $_;
        $r =~ s/\Q$tmpdir\E[\/\\]//;
        $r =~ s/\\/\//g;
        push @out, $r;
    }
    return @out;
}

# ---- Basic globstar patterns ----

subtest '**/*.c finds .c files at any depth' => sub {
    my @got = FastGlob::glob("$tmpdir/**/*.c");
    is_deeply( [rel(@got)],
        ['src/lib/deep/core.c', 'src/lib/helper.c', 'src/lib/util.c', 'src/main.c', 'top.c'],
        '**/*.c matches all .c files recursively' );
};

subtest '**/core.c finds specific file at any depth' => sub {
    my @got = FastGlob::glob("$tmpdir/**/core.c");
    is_deeply( [rel(@got)], ['src/lib/deep/core.c'],
        '**/core.c finds deeply nested file' );
};

subtest 'src/** matches everything under src/' => sub {
    my @got = FastGlob::glob("$tmpdir/src/**");
    my @rel = rel(@got);
    ok( (grep { $_ eq 'src/main.c' } @rel), 'src/** finds src/main.c' );
    ok( (grep { $_ eq 'src/lib/util.c' } @rel), 'src/** finds src/lib/util.c' );
    ok( (grep { $_ eq 'src/lib/deep/core.c' } @rel), 'src/** finds src/lib/deep/core.c' );
};

subtest 'src/**/*.c finds .c files under src/' => sub {
    my @got = FastGlob::glob("$tmpdir/src/**/*.c");
    is_deeply( [rel(@got)],
        ['src/lib/deep/core.c', 'src/lib/helper.c', 'src/lib/util.c', 'src/main.c'],
        'src/**/*.c matches all .c files under src/' );
};

subtest '** at zero depth (file in same dir)' => sub {
    my @got = FastGlob::glob("$tmpdir/**/top.c");
    is_deeply( [rel(@got)], ['top.c'],
        '**/top.c finds file at root level (zero-depth match)' );
};

subtest '** with middle component: src/**/core.c' => sub {
    my @got = FastGlob::glob("$tmpdir/src/**/core.c");
    is_deeply( [rel(@got)], ['src/lib/deep/core.c'],
        'src/**/core.c traverses multiple levels' );
};

subtest '** with non-matching extension' => sub {
    my @got = FastGlob::glob("$tmpdir/**/*.xyz");
    is_deeply( \@got, [], '**/*.xyz returns empty for no matches' );
};

# ---- Dotfile hiding with globstar ----

subtest '** respects hidedotfiles=1' => sub {
    local $FastGlob::hidedotfiles = 1;
    my @got = FastGlob::glob("$tmpdir/**/*.c");
    my @rel = rel(@got);
    ok( !(grep { /\.hidden/ } @rel), '** hides .hidden directory by default' );
};

subtest '** shows dotdirs when hidedotfiles=0' => sub {
    local $FastGlob::hidedotfiles = 0;
    my @got = FastGlob::glob("$tmpdir/**/*.c");
    my @rel = rel(@got);
    ok( (grep { $_ eq '.hidden/secret.c' } @rel), '** finds .hidden/secret.c when hidedotfiles=0' );
};

# ---- Multiple ** in pattern ----

subtest 'src/**/lib/**/*.c with double globstar' => sub {
    my @got = FastGlob::glob("$tmpdir/src/**/lib/**/*.c");
    is_deeply( [rel(@got)],
        ['src/lib/deep/core.c', 'src/lib/helper.c', 'src/lib/util.c'],
        'double ** works correctly' );
};

# ---- ** with brace expansion ----

subtest '**/*.{c,txt} combines globstar with braces' => sub {
    my @got = FastGlob::glob("$tmpdir/**/*.{c,txt}");
    my @rel = rel(@got);
    ok( (grep { $_ eq 'docs/readme.txt' } @rel), 'finds .txt file' );
    ok( (grep { $_ eq 'src/main.c' } @rel), 'finds .c file' );
};

done_testing;
