# NAME

FastGlob - A faster glob() implementation

# VERSION

version 1.6

# SYNOPSIS

```perl
    use FastGlob qw(glob);
    my @list = glob('*.c');
```

# DESCRIPTION

This module implements globbing in perl, rather than forking a csh.
This is faster than the built-in glob() call, and more robust (on
many platforms, csh chokes on `echo *` if too many files are in the
directory.)

There are several module-local variables that control platform-specific
behavior. On Windows (`$^O eq 'MSWin32'`), these are automatically set
to appropriate values. On other platforms, UNIX defaults are used.
You can override them after loading the module if needed.

```
    # UNIX defaults (auto-detected):
    $FastGlob::dirsep = '/';        # directory path separator
    $FastGlob::rootpat = '\A\Z';    # root directory prefix pattern
    $FastGlob::curdir = '.';        # name of current directory in dir
    $FastGlob::parentdir = '..';    # name of parent directory in dir
    $FastGlob::hidedotfiles = 1;    # hide filenames starting with .

    # Windows defaults (auto-detected on MSWin32):
    $FastGlob::dirsep = '\\';       # directory path separator
    $FastGlob::rootpat = '[A-Za-z]:';  # <Drive letter><colon> pattern
    $FastGlob::curdir = '.';        # name of current directory in dir
    $FastGlob::parentdir = '..';    # name of parent directory in dir
    $FastGlob::hidedotfiles = 1;    # hide filenames starting with .
```

For classic MacOS you would set:

```
    $FastGlob::dirsep = ':';        # directory path separator
    $FastGlob::rootpat = '\A\Z';    # root directory prefix pattern
    $FastGlob::curdir = '.';        # name of current directory in dir
    $FastGlob::parentdir = '..';    # name of parent directory in dir
    $FastGlob::hidedotfiles = 0;    # hide filenames starting with .
```

Tilde expansion (`~` and `~user`) uses `getpwuid`/`getpwnam` on UNIX.
On Windows, `~` falls back to `$HOME` or `$USERPROFILE`.

# INSTALLATION

Copy this module to the Perl 5 Library directory.

# AUTHOR

Marc Mengel <mengel@fnal.gov>

# COPYRIGHT AND LICENSE

This software is copyright (c) 1999 by Marc Mengel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
