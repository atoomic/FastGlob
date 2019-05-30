# NAME

FastGlob - A faster glob() implementation

# VERSION

version 1.4

# SYNOPSIS

```perl
    use FastGlob qw(glob);
    my @list = &glob('*.c');
```

# DESCRIPTION

This module implements globbing in perl, rather than forking a csh.
This is faster than the built-in glob() call, and more robust (on
many platforms, csh chokes on `echo *` if too many files are in the
directory.)

There are several module-local variables that can be set for 
alternate environments, they are listed below with their (UNIX-ish)
defaults.

```
    $FastGlob::dirsep = '/';        # directory path separator
    $FastGlob::rootpat = '\A\Z';    # root directory prefix pattern
    $FastGlob::curdir = '.';        # name of current directory in dir
    $FastGlob::parentdir = '..';    # name of parent directory in dir
    $FastGlob::hidedotfiles = 1;    # hide filenames starting with .
```

So for MS-DOS for example, you could set these to:

```
    $FastGlob::dirsep = '\\';       # directory path separator
    $FastGlob::rootpat = '[A-Z]:';  # <Drive letter><colon> pattern
    $FastGlob::curdir = '.';        # name of current directory in dir
    $FastGlob::parentdir = '..';    # name of parent directory in dir
    $FastGlob::hidedotfiles = 0;    # hide filenames starting with .
```

And for MacOS to:

```
    $FastGlob::dirsep = ':';        # directory path separator
    $FastGlob::rootpat = '\A\Z';    # root directory prefix pattern
    $FastGlob::curdir = '.';        # name of current directory in dir
    $FastGlob::parentdir = '..';    # name of parent directory in dir
    $FastGlob::hidedotfiles = 0;    # hide filenames starting with .
```

# NAME

FastGlob - A faster glob() implementation

# INSTALLATION

Copy this module to the Perl 5 Library directory.

# COPYRIGHT

Copyright (c) 1997-1999 Marc Mengel. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# AUTHOR

Marc Mengel <`mengel@fnal.gov`>

# AUTHOR

Nicolas R <atoomic@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 1999 by Marc Mengel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
