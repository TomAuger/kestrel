# Kestrel

Mobile app MV(C) framework for Flash-based development using the Flash IDE for dynamically loaded views.

## Purpose

Kestrel provides a solid and robust multi-platform foundation for rapid mobile app development within Adobe AIR using the Flash IDE. 

## Why another cross-platform mobile development framework?

There are a [ton](https://cordova.apache.org/) of [great ways](http://phonegap.com/) to develop cross-platform mobile apps and [new ones](https://facebook.github.io/react-native/) coming out [all the time](https://www.nativescript.org/), but none of them map to a traditional Flash-based workflow. Kestrel is specifically built for individuals and agencies that have Adobe Flash based designers and developers who want to be able to build apps using their existing knowledge of Flash, its layout and drawing tools, and as little ActionScript as necessary.

### Do I need Kestrel to build mobile apps with Flash?

Not at all. You can set up Flash to target iOS and Android pretty easily with the built-in Adobe AIR. What Kestrel does is all the little things that you didn't think you would have to worry about, such as:

* Handle device orientation changes
* Load additional assets (screens, UI elements, sounds, XML, CSS etc) after launch
* Load HiDPI assets when Retina or HiDPI devices are detected
* Throw up native-looking Modal Dialog boxes
* Handle your app going to sleep or app switching (due to a phone call, for instance)
* Switch from Screen to Screen as a result of user interactions, with the ability to leverage Transitions between them
* Add ActionScript functionality to Assets that you created in Flash without adding ABC (byte code) to the loaded SWFs (which would make your app ineligible for the Apple Store)
* Activate / Deactivate assets when switching screens
* and a lot more...

## Usage

1. In your ActionScript IDE (Flash CC, FlashDevelop, FDT or FlashBuilder), make sure there is a `lib` directory, or other directory to contain external libraries.
2. Make sure that directory is in the "Classpath". See documentation for your IDE of choice for how to add directories to the classpath.
3. Copy everything inside the `src` folder of this repo into that `lib` directory. You may need to merge with other libraries - for example if you are using `com.greensock.tweenlite` then you already have a `com` directory inside your `lib` directory, so you just need to copy `zeitguys` into the `com` directory and you're done.

## Documentation

Currently there's a fair bit of inline docs, so please look at the classes (in `src/com/zeitguys/framework`). Working on an ASDoc and some [GitHub/Wiki](https://github.com/TomAuger/kestrel/wiki) pages.
