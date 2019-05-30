# Development

The distribution is contained in a Git repository, so simply clone the
repository

```
$ git clone git@github.com:atoomic/FastGlob.git
```

and change into the newly-created directory.

```
$ cd FastGlob
```

The project uses [`Dist::Zilla`](https://metacpan.org/pod/Dist::Zilla) to
build the distribution, hence this will need to be installed before
continuing:

```
$ cpanm Dist::Zilla
```

or you can also consider using the `Makefile.PL`

To install the required prequisite packages, run the following set of
commands:

```
$ dzil authordeps --missing | cpanm
$ dzil listdeps --author --missing | cpanm
```

The distribution can be tested like so:

```
$ dzil test
```

To run the full set of tests (including author and release-process tests),
add the `--author` and `--release` options:

```
$ dzil test --author --release
```
