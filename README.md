#  File Cloud.app

Upload files to [File Cloud](https://github.com/skalnik/file-cloud).

![macOS Demo](https://c.sklnk.xyz/c-kB3.gif)

## Build

```sh
brew install xcodegen
make build
```

## Release

### macOS

The macOS app updates itself with [Sparkle](https://sparkle-project.org). It
reads `appcast.xml` from `main`.

For each release:

1. `make bump`
2. `make release-macos`. This notarizes the app, commits the paperwork as a
   release commit, pushes it to main, and finally makes the GitHub release,
   which makes the autoupdate go brr.

### iOS

1. `make bump`
2. Commit the change.
3. `make archive-ios`.
