# pkgwatch

ok so you know how you have a `pubspec.yaml` sitting in your project and every couple weeks you wonder "wait am i on old versions of stuff". this is that, but as a cli. checks pub.dev for what's latest, tells you which ones are behind and by how much (major / minor / patch).

nothing fancy. drop-in for ci too. exits non-zero if anything's behind.

## install

```sh
dart pub global activate pkgwatch
```

or clone + `dart pub global activate --source path .`

## usage

```sh
pkgwatch                       # checks ./pubspec.yaml
pkgwatch --path some/pubspec.yaml
pkgwatch --quiet               # only prints the ones that are behind
pkgwatch --json                # machine-readable for ci
```

## example

```
$ pkgwatch
checking 12 packages against pub.dev...
  ^ http                0.13.6   ->  1.2.0    major behind
  ^ path                1.8.0    ->  1.9.1    minor behind
  ^ args                2.4.0    ->  2.5.2    patch behind
  . meta                1.11.0   up to date
  . test                1.25.0   up to date
3 updates available. run `dart pub upgrade` to take them.
```

## exit codes

- `0` everything current
- `2` at least one package behind

kinda perfect for a ci job that nags you on mondays.

## ci example

```yaml
- run: dart pub global activate pkgwatch
- run: pkgwatch --quiet
```

## why

i kept forgetting to run `dart pub outdated` and `pub outdated` has a lot of output. wanted something tiny that i could eyeball in 2 seconds.

## license

mit. farkhad
