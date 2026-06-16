# easybs

> Easy bootstrap for y'all!

## What?

C, C++, shell. Reproducibly. From scratch.

## Why?

I need them.

## How?

1. ./dist/run.sh
2. idk (but we have a bootstrap container debian:easybs-aarch64-20260614T144248Z that will run everything).

## Where?

Build on Linux/arm64, Linux/amd64, use on Linux/arm64, Linux/amd64, Darwin/arm64 (more to come)

## I'm in.

Grab the .tar.xz, extract somewhere add $somewhere/bin to path


----


## But seriously though

EasyBS is part of SimplyBS, yet separate. It would be really cool to put simplybs bootstrap in simplybs but I want to avoid chicken and egg problem of "you need to build older simplybs to get current simplybs to work", that's where easybs comes with a clutch. It provides you with a couple tarballs to select from:


- zig, clang, gcc - depending on whatever works good for you as C and C++ compiler
- dash and toybox - shell plus core POSIX utilities (mkdir, cp, sed, tar, …)
- that's it man.

Directory structure is as follows:

- ${flavor}-${triplet}.tar.xz
  - flavor: clangXX, gccXX, zigXX (xx is version)
  - triplet: aarch64-linux-gnu, x86_64-linux-gnu, aarch64-apple-darwin (more to come, maybe - but these are core focus)

Once you untarxz you get:
- ${flavor}-${triplet}/
  - bin/
    - Here you will get clang, clang++ OR gcc, g++ OR zig, dash, toybox, and utility symlinks.
  - lib/
    - Any libraries that are needed to run the code.
  - something else? - Maybe, don't worry about it - just extract the file.

Assuming you untar clang21-aarch64-apple-darwin.tar.xz you will get a clang that runs on aarch64-apple-darwin and builds for aarch64-apple-darwin.

Assuming you untar clang21-aarch64-linux-gnu.tar.xz you will get a clang that runs on aarch64-linux-gnu and builds for aarch64-linux-gnu (with bundled glibc sysroot).

Assuming you untar clang21-x86_64-linux-gnu.tar.xz you will get a clang that runs on x86_64-linux-gnu and builds for x86_64-linux-gnu (with bundled glibc sysroot).

Build a flavor:

```bash
./dist/run.sh clang21-aarch64-apple-darwin
./dist/run.sh clang21-aarch64-linux-gnu
./dist/run.sh clang21-x86_64-linux-gnu
```

You can place the files anywhere you like and use them.. the way you would expect.