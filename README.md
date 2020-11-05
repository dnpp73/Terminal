Terminal
===========

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat-square)](https://github.com/apple/swift-package-manager)


## What is this

Terminal Emulator for iOS. based on [hterm.js](https://hterm.org) with `WKWebView`

This is not ssh client. only emulate terminal output.

If need ssh, you could use [`NMSSH/NMSSH`](https://github.com/NMSSH/NMSSH) library. Please see example app.


## Demo

<img src="/gif/nyancat.gif" alt="nyancat" width="200"> <img src="/gif/sl.gif" alt="sl" width="200"> <img src="/gif/cmatrix.gif" alt="cmatrix" width="200"> <img src="/gif/vim.gif" alt="vim" width="200">


## Features

- supports iOS 11 ~ (iOS 12 or above recommended)
- supports Interface Builder creation
- supports GUI selection, select all, copy, paste
- supports hardware keyboard input
- supports CJK IME (little buggy...)


## How to use

See Example Appication.

- [`TerminalViewController.swift`](/Example/TerminalExample/ViewController/TerminalViewController.swift)
- [`SSHTerminalViewController.swift`](/Example/TerminalExample/ViewController/SSHTerminalViewController.swift)


## How to build Example App

### `swiftlint` and `carthage` required

```sh
brew install swiftlint carthage
```

### Clone Repository and prepare

```sh
git clone git@github.com:dnpp73/Terminal.git

cd Terminal/Example

carthage bootstrap --platform iOS --no-use-binaries

open TerminalExample.xcodeproj
```

If you want to run on a real devices, change the `Team` because of code sign problem.


### `sshd` with password authentication?

I recommend using Docker. See [`Dockerize an SSH service`](https://docs.docker.com/engine/examples/running_ssh_service/)

[`dnpp73/chef_cutting_board`](https://github.com/dnpp73/chef_cutting_board) is convenient.


## Carthage

https://github.com/Carthage/Carthage

Write your `Cartfile`

```
github "dnpp73/Terminal"
```

and run

```sh
carthage bootstrap --cache-builds --no-use-binaries --platform iOS
```

or

```sh
carthage update --cache-builds --no-use-binaries --platform iOS
```


## Respect

- [Blink Shell for iOS](https://blink.sh) ([GitHub](https://github.com/blinksh/blink))
- [iSH](https://ish.app) ([GitHub](https://github.com/ish-app/ish))
- [a-Shell](https://holzschu.github.io/a-Shell_iOS/) ([GitHub](https://github.com/holzschu/a-shell))


## License

[MIT](/LICENSE)
