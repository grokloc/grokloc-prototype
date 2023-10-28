# Contributing

As noted in `README.md`, this project is hosted at SourceHut:

The issue tracker:

https://todo.sr.ht/~grokloc/grokloc-prototype

The discussion list:

https://lists.sr.ht/~grokloc/grokloc-prototype

Please feel free to introduce yourself on the mailing list or create tickets
in the issue tracker. Obvious spam may be erased without notice or notification.

The build tracker:

https://builds.sr.ht/~grokloc/grokloc-prototype

## Git Workflow

As this project is hosted on SourceHut, there are no "pull requests" or "merge requests"
as provided by other Git hosting services. This project is utilizing an email
workflow provided by `git` directly through patches. For more information, try:

https://git-send-email.io/

Contributors should

1. Clone this repository
2. Make changes
3. Squash the commits
4. Use the single squashed commit to provide a patch over email

All contributors, including the repository owner(s), shall follow this process;
the only activity as the project home will be merged patches.

It is strongly encouraged to GPG-sign your commits.

Send patches to `~grokloc/grokloc-prototype@lists.sr.ht`

A paste with some more tips with command examples is available at:

https://paste.sr.ht/~grokloc/35bcd3dcc8175efce83aaa4deb88eec4406a394f

## Development

(This section will become more detailed over time, please suggest changes)

Note - this is a prototyping repository intended to be a safe place to make
a mess. The functionality may mimic that of the main `grokloc-app` repository
or not at any given time.

### Requirements

- `perl5.38`
- `docker`
- `docker-compose`
- `make`
- optional: local PostgreSQL client support

There are some `docker` images you will need; the easiest way to get these
and to construct the `docker` network and volumes is to type:

`make up`

which brings up the Compose environment, fetching all resources needed.

For more rapid development you can interact with your Rust code 
locally and access only PostgreSQL through `docker`:

1. Set an environment variable for reaching the database: `POSTGRES_APP_URL=postgres://grokloc:grokloc@localhost:5432/app`
2. Set an environment variable for test repository clone path: `REPOSITORY_BASE=/tmp`
3. Run `make local-db` to bring up *only* the database
4. When done, you can take the database down with `make local-db-down`

## Related Repositories

This repository contains Rust code that operates on a PostgreSQL database. The
repository for this part of the project is available here:

https://git.sr.ht/~grokloc/grokloc-postgres

If you wish to make database changes, you must do so in that repository as well
as this one. Currently, coordinating these two repositories is done through `docker` tags
(i.e. this repository will require a `grokloc/grokloc-postgres:$tag` that is fixed to a version).

