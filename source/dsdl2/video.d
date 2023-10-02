/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.video;
@safe:

import bindbc.sdl;
import dsdl2.sdl;

import std.conv : to;
import std.string : toStringz;

/++
 + Wraps `SDL_VideoInit` which initializes the video subsystem while specifying the video driver used
 +
 + Params:
 +   driverName = the name of the video driver
 + Throws: `dsdl2.SDLException` if the video driver could not be initialized
 +/
void initVideo(string driverName) @trusted {
    if (SDL_VideoInit(driverName.toStringz()) != 0) {
        throw new SDLException;
    }
}

/++
 + Wraps `SDL_VideoQuit` which quits the video subsystem
 +/
void quitVideo() @trusted {
    SDL_VideoQuit();
}

/++
 + Wraps `SDL_GetNumVideoDrivers` and `SDL_GetVideoDriver` which return a list of available video drivers
 +
 + Returns: `string` names of the available video drivers
 + Throws: `dsdl2.SDLException` if failed to get the available video drivers
 +/
const(string[]) getVideoDrivers() @trusted {
    int numDrivers = SDL_GetNumVideoDrivers();
    if (numDrivers <= 0) {
        throw new SDLException;
    }

    static string[] drivers;
    if (drivers !is null) {
        size_t originalLength = drivers.length;
        drivers.length = numDrivers;

        if (numDrivers > originalLength) {
            foreach (i; originalLength .. numDrivers) {
                drivers[i] = SDL_GetVideoDriver(i.to!int).to!string.idup;
            }
        }
    }
    else {
        drivers = new string[](numDrivers);

        foreach (i; 0 .. numDrivers) {
            drivers[i] = SDL_GetVideoDriver(i).to!string.idup;
        }
    }

    return drivers;
}

/++
 + Wraps `SDL_GetCurrentVideoDriver` which returns the current video driver
 +
 + Returns: `string` name of the current video driver
 +/
string getCurrentVideoDriver() @trusted {
    return SDL_GetCurrentVideoDriver().to!string.idup;
}
