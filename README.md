# pg-quilter

`pg-quilter` is a continuous integration tool to help streamline the
Postgres patch review process.

Most of this process takes place can be tracked via the [CommitFest
manager](https://commitfest.postgresql.org/), but this still leaves
some manual work: the actual code review, checking whether the patch
(still) applies, testing whether it passes the `make check` test
suite, and running other tests as appropriate.

Some of this can be automated, and the goal of `pg-quilter` is to take
on some of that work.

`pg-quilter` subscribes to the
[pgsql-hackers](http://www.postgresql.org/list/pgsql-hackers/) mailing
list, watches for patches, attempts to apply them against the latest
Postgres master branch, and submits a GitHub pull request for the
change to its own fork of the Postgres repository. It configures these
requests for builds by [Travis CI](https://travis-ci.org/), and Travis
then indicates whether or not a run of `make check` succeeded. It also
updates the pull requests when changes are committed upstream in
Postgres to ensure that the patch always applies against current code.

The Travis state of a pull request will indicate whether or not a
patch applied successfully (`pg-quilter` creates a sentinel file when
this step fails and Travis automatically fails the build) and if so,
whether it passes `make check`.


## Production

`pg-quilter` is currently running on Heroku and using the
[pg-quilter/postgres](https://github.com/pg-quilter/postgres) GitHub
repo. For currently open requests, see the [pull
requests](https://github.com/pg-quilter/postgres/pulls) page.

N.B.: It's relatively easy to spoof mail to `pg-quilter` right
now. The patches are an out-of-band feedback mechanism and the
problems caused are likely minimal, but please keep this in mind.


## Known Issues

 * Does not close pull requests itself, so it may try to build a patch
   that has already been merged
 * Does not yet support gzipped or inlined patches
 * Following a set of patches on the same issue is heuristic and not
   always perfect


## Heroku Setup

`pg-quilter` is fairly easy to set up on Heroku:

```console
$ git clone git@github.com:deafbybeheading/pg-quilter.git
$ cd pg-quilter
$ heroku create
```

`pg-quilter` needs some GitHub credentials to operate: a private key
to allow it to run push to its repo, and an account password. This should
be a separate account with a separate ssh key:

```console
$ heroku config:set GITHUB_PRIVATE_KEY=<(cat /path/to/key/id_rsa)
$ heroku config:set GITHUB_PASSWORD=...
```

Make sure that the corresponding public key has been [uploaded to
GitHub](https://github.com/settings/ssh).

Then add the necessary addons and deploy:

```console
$ heroku addons:add heroku-postgresql:basic
$ heroku addons:add cloudmailin:starter
$ git push heroku master
$ heroku ps:scale web=1 worker=1
```


## Other Setup

To set up elsewhere, you'll need a
[CloudMailIn](http://www.cloudmailin.com/) account and appropriate
config settings in your environment. You'll also need a Postgres
database as `DATABASE_URL`. Use
[Foreman](https://github.com/ddollar/foreman) to run it based on the
process manifest in the `Procfile`.


## License

Copyright (c) 2013 Maciek Sakrejda

`pg-quilter` is available under the 2-clause BSD license. For details,
see the LICENSE file.