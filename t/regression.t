#!/usr/bin/env perl

# Regression tests for known FastGlob edge cases.
#
# Each test documents a specific behavior gap between FastGlob and
# CORE::glob.  Tests marked TODO fail on master today; once the
# corresponding fix lands, the TODO should be removed so the test
# becomes a hard assertion.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Basename qw(basename);
use Cwd qw(getcwd abs_path);

use FastGlob ();

# --- helpers ---

my $root = tempdir( DIR => '.', CLEANUP => 1 );
$root = abs_path($root);

sub touch {
    my ($relpath) = @_;
    my $full = "$root/$relpath";
    my $dir  = $full;
    $dir =~ s{/[^/]*$}{};
    make_path($dir) unless -d $dir;
    open my $fh, '>', $full or die "Cannot create $full: $!";
    close $fh;
}

sub mkd {
    my ($relpath) = @_;
    make_path("$root/$relpath");
}

sub compare_glob {
    my ($pattern, $description, %opts) = @_;

    my @fast = sort( FastGlob::glob($pattern) );
    my @core = sort( CORE::glob($pattern) );

    if ( $^O eq 'MSWin32' ) {
        @fast = sort map { basename($_) } @fast;
        @core = sort map { basename($_) } @core;
    }

    if ( $opts{todo} ) {
        local $TODO = $opts{todo};
        is_deeply( \@fast, \@core, $description )
            or diag "FastGlob: [@fast]\nCORE:     [@core]";
    } else {
        is_deeply( \@fast, \@core, $description )
            or diag "FastGlob: [@fast]\nCORE:     [@core]";
    }
}

# --- build test tree ---

touch('alpha.c');
touch('beta.c');
touch('gamma.h');
touch('README');
touch('.hidden');
mkd('src');
touch('src/main.c');
touch('src/util.c');
mkd('docs');
touch('docs/guide.txt');
mkd('empty');

my $orig = getcwd();
chdir $root or die "Cannot chdir to $root: $!";

# =================================================================
# 1. Backslash escape stripping for literal paths
#    CORE::glob strips escape backslashes from non-wildcard patterns.
#    e.g. \*.c -> *.c (the file literally named "*.c" if it exists,
#    or empty list; the backslash is removed either way).
# =================================================================

{
    my @fast = FastGlob::glob(q{\*.c});
    # CORE::glob returns empty list (no file named *.c exists)
    # FastGlob should strip the backslash and also return empty
    my @core = CORE::glob(q{\*.c});

    local $TODO = 'backslash stripping for literal paths not yet implemented';
    is_deeply( [sort @fast], [sort @core],
        'escaped star in literal path: backslash stripped' )
        or diag "FastGlob: [@fast]\nCORE:     [@core]";
}

{
    my @fast = FastGlob::glob(q{b\ar.c});
    my @core = CORE::glob(q{b\ar.c});

    local $TODO = 'backslash stripping for literal paths not yet implemented';
    is_deeply( [sort @fast], [sort @core],
        'backslash before non-special char is stripped' )
        or diag "FastGlob: [@fast]\nCORE:     [@core]";
}

# =================================================================
# 2. Brace expansion: trailing empty alternatives
#    split(',', ...) drops trailing empty fields; need -1 limit.
# =================================================================

SKIP: {
    skip 'path differences on Windows', 1 if $^O eq 'MSWin32';

    # {alpha,beta,}.c should expand to alpha.c, beta.c, and .c
    # The trailing comma produces an empty alternative; split(',', ...)
    # without -1 limit silently drops it.
    my @fast = sort( FastGlob::glob('{alpha,beta,}.c') );
    my @core = sort( CORE::glob('{alpha,beta,}.c') );

    local $TODO = 'split without -1 drops trailing empty alternatives';
    is_deeply( \@fast, \@core,
        'brace expansion with trailing empty alternative' )
        or diag "FastGlob: [@fast]\nCORE:     [@core]";
}

# =================================================================
# 3. Trailing slash: directory-only matching
#    "src/" should only match directories and include the trailing /.
# =================================================================

SKIP: {
    skip 'path separator differences on Windows', 2 if $^O eq 'MSWin32';

    {
        my @fast = sort( FastGlob::glob('*/') );
        my @core = sort( CORE::glob('*/') );

        local $TODO = 'trailing slash directory-only matching not implemented';
        is_deeply( \@fast, \@core,
            'wildcard with trailing slash matches only directories' )
            or diag "FastGlob: [@fast]\nCORE:     [@core]";
    }

    compare_glob( 'src/',
        'literal dir with trailing slash' );
}

# =================================================================
# 4. Unclosed bracket: treated as literal
#    "[ab.c" has no closing ] — CORE::glob treats [ as literal.
# =================================================================

{
    # Create a file with [ in the name to test literal matching
    touch('[ab.c');

    my @fast = FastGlob::glob('[ab.c');
    my @core = CORE::glob('[ab.c');

    local $TODO = 'unclosed bracket not treated as literal character';
    is_deeply( [sort @fast], [sort @core],
        'unclosed bracket treated as literal' )
        or diag "FastGlob: [@fast]\nCORE:     [@core]";
}

# =================================================================
# 5. Remaining {} after brace expansion are literal
#    After expansion, bare {} should not trigger wildcard detection.
# =================================================================

{
    # {} with no comma: CORE::glob strips it (file{}.c -> file.c).
    # FastGlob currently drops the pattern entirely because the
    # bracepat regex matches {} but split(',', '') yields nothing.
    # At minimum, the pattern should not vanish.
    my @fast = FastGlob::glob('alpha{}.c');
    my @core = CORE::glob('alpha{}.c');

    local $TODO = 'bare {} causes pattern to be silently dropped';
    is_deeply( [sort @fast], [sort @core],
        'bare {} does not cause pattern to vanish' )
        or diag "FastGlob: [@fast]\nCORE:     [@core]";
}

# =================================================================
# 6. POSIX [!...] negation (already working on master)
#    This is NOT a TODO — verifies the fix stays in place.
# =================================================================

compare_glob( '[!b]*',
    '[!...] negation excludes entries starting with b' );

compare_glob( '[!a-c]*',
    '[!...] negation with range' );

# =================================================================
# 7. [^...] in glob context: caret is literal, not negation
#    POSIX glob uses [!...] for negation; [^...] means literal ^.
#    CORE::glob confirms this on macOS/Linux.
# =================================================================

{
    touch('^file.c');

    my @fast = FastGlob::glob('[^a]*.c');
    my @core = CORE::glob('[^a]*.c');

    local $TODO = '[^...] incorrectly treated as regex negation instead of literal caret';
    is_deeply( [sort @fast], [sort @core],
        '[^a] matches literal caret, not negation' )
        or diag "FastGlob: [@fast]\nCORE:     [@core]";
}

# =================================================================
# 8. Patterns that should match but verify correct behavior
#    These are NOT expected to fail — they guard against regressions.
# =================================================================

compare_glob( '*.c',    'basic wildcard still works' );
compare_glob( '?eta.c', 'question mark wildcard' );
compare_glob( '[ab]*.c', 'bracket expression' );
compare_glob( '{alpha,beta}.c', 'brace expansion' );

SKIP: {
    skip 'path differences on Windows', 2 if $^O eq 'MSWin32';

    compare_glob( 'src/*.c',   'subdirectory wildcard' );
    compare_glob( '*/*.c',     'star/star.ext pattern' );
}

compare_glob( '.*', 'dotfile matching with explicit dot' );

# =================================================================

chdir $orig;
done_testing;
