#  File Cloud.app

Upload files to [File Cloud](https://github.com/skalnik/file-cloud).

![macOS Demo](https://c.sklnk.xyz/c-kB3.gif)

## Build

```sh
brew install xcodegen
make build
```

## Release

1. `make bump`
2. Commit the change.
3. `make archive-macos` or `make archive-ios`.
