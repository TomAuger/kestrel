# Kestrel

Mobile app MV(C) framework for Flash-based development using the Flash IDE for dynamically loaded views.

## Purpose

Kestrel provides a solid and robust multi-platform foundation for rapid mobile app development within Adobe AIR using the Flash IDE. 

## Usage

1. In your ActionScript IDE (Flash CC, FlashDevelop, FDT or FlashBuilder), make sure there is a `lib` directory, or other directory to contain external libraries.
2. Make sure that directory is in the "Classpath". See documentation for your IDE of choice for how to add directories to the classpath.
3. Copy everything inside the `src` folder of this repo into that `lib` directory. You may need to merge with other libraries - for example if you are using `com.greensock.tweenlite` then you already have a `com` directory inside your `lib` directory, so you just need to copy `zeitguys` into the `com` directory and you're done.

## Documentation

Currently there's a fair bit of inline docs. Working on an ASDoc and some GitHub/Wiki pages eventually.
