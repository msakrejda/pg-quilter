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


## Production

`pg-quilter` is currently running on Heroku at
`pg-quilter.herokuapp.com`.


## Known Issues

 * Does not yet support multiple worker dynos
 * Does not gracefully retry builds on worker failure (or, e.g.,
   periodic dyno restart)
 * Does not yet support gzipped patches

## Heroku Setup

`pg-quilter` is fairly easy to set up on Heroku:

```console
$ git clone git@github.com:deafbybeheading/pg-quilter.git
$ cd pg-quilter
$ heroku create
```

`pg-quilter` needs a GitHub private key to allow it to fetch via the
`git` protocol. This should be a separate account with a separate ssh
key, and *not* your main private key:

```console
$ heroku config:set GITHUB_PRIVATE_KEY="$(cat /path/to/key/id_rsa)"
```

Make sure that the corresponding public key has been [uploaded to
GitHub](https://github.com/settings/ssh).

Then add the Heroku Postgres addon and deploy:

```console
$ heroku addons:add heroku-postgresql:hobby-basic
$ git push heroku master
$ heroku ps:scale web=1 worker=1
```


## Other Setup

To set up elsewhere, you'll need a Postgres database as
`DATABASE_URL`. Use [Foreman](https://github.com/ddollar/foreman) to
run it based on the process manifest in the `Procfile`.


## Usage

PG-Quilter exposes a simple build API for Postgres. You will need to
obtain an API token to use the system. For now, there is no self-serve
mechanism for obtaining tokens; please file an issue to obtain one.

A "build" can be created by issuing a `POST` to the app with a
Postgres base revision and an array of zero or more patches to be
applied sequentially:

```console
$ curl 2>/dev/null -u :<api-token> -d '{"base_rev":"master","patches":[]}' https://pg-quilter.herokuapp.com/v1/builds
{"id":"0d29e892-7ab8-4b21-81da-b1a5893a7bd0"}
```

Any patches have to be something that `git apply` can work with, e.g.,
the output of git diff (we can probably relax this later for gzip and
other non-standard patch support).

PG-Quilter will then attempt to apply all patches, build Postgres, and
run the basic `make check` test suites for Postgres itself and all
in-tree contrib modules.

You can then check the status of the build with its id:

```console
$ curl 2>/dev/null -u :<api-token> https://pg-quilter.herokuapp.com/v1/builds/0d29e892-7ab8-4b21-81da-b1a5893a7bd0 | jsonpretty
{
  "id": "0d29e892-7ab8-4b21-81da-b1a5893a7bd0",
  "created_at": "2013-08-29T05:58:32+00:00",
  "state": "running",
  "patches": [

  ]
}
```

N.B.: a tool like
[jsonpretty](https://github.com/nicksieger/jsonpretty) is very useful
when working with `pg-quilter` on the command line

Builds are either `pending` (just submitted, not yet worked on),
`running` (a run has started), or `complete` (build has finished,
either successfully or unsuccessfully). There are a number of different
steps, and each report their output individually:

 * reset: reset the workspace (useful for resolving a symbolic base SHA)
 * apply_patch: the actual patch application process--this step can
   occur zero or more times, once per patch
 * configure: run the `./configure` script
 * make: run `make`
 * make contrib: run `make` in the `contrib` directory
 * make check: run the `make check` test suite
 * make contribcheck: run the `make check` test suite in each contrib
   directory

The progress of individual steps can be checked with the
builds/:id/steps endpoint:

```console
$ curl 2>/dev/null -u :<api-token> https://pg-quilter.herokuapp.com/v1/builds/0d29e892-7ab8-4b21-81da-b1a5893a7bd0/steps | jsonpretty
[
  {
    "step": "reset",
    "started_at": "2013-09-01T17:20:32+00:00",
    "completed_at": "2013-09-01T17:20:34+00:00",
    "stdout": "HEAD is now at f49f8de Update 9.3 release notes.\n",
    "stderr": "+ workspace=/app/postgres\n+ base_rev=origin/master\n+ git clean -f -d\n+ git checkout master\nAlready on 'master'\n+ git fetch origin\nWarning: Permanently added 'github.com,192.30.252.128\
' (RSA) to the list of known hosts.\r\n+ git reset --hard origin/master\n",
    "status": 0,
    "attrs": {
      "resolved_rev": "f49f8de074c37d7af5441f79e5569b9e463d0b09"
    }
  },
  {
    "step": "configure",
    "started_at": "2013-09-01T17:20:34+00:00",
    "completed_at": "2013-09-01T17:22:01+00:00",
    "stdout": "checking build system type... x86_64-unknown-linux-gnu\nchecking host system type... x86_64-unknown-linux-gnu\n......
    ...
    ...
  }
]
```

Each step has stdout, stderr, and (exit) status recorded.


## License

Copyright (c) 2013 Maciek Sakrejda

`pg-quilter` is available under the 2-clause BSD license. For details,
see the LICENSE file.
