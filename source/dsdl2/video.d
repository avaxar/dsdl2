/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.video;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.pixels;
import dsdl2.rect;

import std.array : uninitializedArray;
import std.conv : to;
import std.format : format;
import std.string : toStringz;
import std.typecons : Tuple, tuple;

void initVideo(string driverName) @trusted {
    if (SDL_VideoInit(driverName.toStringz()) != 0) {
        throw new SDLException;
    }
}

void quitVideo() @trusted {
    SDL_VideoQuit();
}

string[] getVideoDrivers() @trusted {
    int numDrivers = SDL_GetNumVideoDrivers();
    if (numDrivers <= 0) {
        throw new SDLException;
    }

    static string[] drivers;
    if (drivers !is null) {
        drivers.length = numDrivers;
        if (numDrivers > drivers.length) {
            foreach (i; drivers.length .. numDrivers) {
                drivers[i] = SDL_GetVideoDriver(i.to!int).to!string.idup;
            }
        }

        return drivers;
    }
    drivers = new string[](numDrivers);

    foreach (i; 0 .. numDrivers) {
        drivers[i] = SDL_GetVideoDriver(i).to!string.idup;
    }

    return drivers;
}

string getCurrentVideoDriver() @trusted {
    return SDL_GetCurrentVideoDriver().to!string.idup;
}

struct DisplayMode {
    PixelFormat pixelFormat;
    uint[2] size;
    uint refreshRate;
    void* driverData;

    this() @disable;

    this(SDL_DisplayMode sdlDisplayMode) {
        this.pixelFormat = new PixelFormat(sdlDisplayMode.format);
        this.size = [sdlDisplayMode.w.to!uint, sdlDisplayMode.h.to!uint];
        this.refreshRate = sdlDisplayMode.refresh_rate.to!uint;
        this.driverData = sdlDisplayMode.driverdata;
    }

    this(PixelFormat pixelFormat, uint[2] size, uint refreshRate, void* driverData = null)
    in {
        assert(pixelFormat !is null);
    }
    do {
        this.pixelFormat = pixelFormat;
        this.size = size;
        this.refreshRate = refreshRate;
        this.driverData = driverData;
    }

    invariant {
        assert(pixelFormat !is null);
    }

    string toString() const {
        return "dsdl2.DisplayMode(%s, [%d, %d], %d, %p)".format(this.pixelFormat.to!string, this.width,
            this.height, this.refreshRate, this.driverData);
    }

    inout(SDL_DisplayMode) sdlDisplayMode() inout @property {
        return inout SDL_DisplayMode(this.pixelFormat.sdlPixelFormatEnum, this.width.to!int, this.height.to!int,
            this.refreshRate.to!int, this.driverData);
    }

    ref inout(uint) width() return inout @property {
        return this.size[0];
    }

    ref inout(uint) height() return inout @property {
        return this.size[1];
    }
}

class Display {
    const uint sdlDisplayIndex;

    this() @disable;

    private this(uint sdlDisplayIndex) {
        this.sdlDisplayIndex = sdlDisplayIndex;
    }

    override string toString() const @trusted {
        return "dsdl2.Display(%d, name: %s, bounds: %s)".format(this.sdlDisplayIndex, this.name,
            this.bounds.to!string);
    }

    string name() const @property @trusted {
        if (const(char)* name = SDL_GetDisplayName(this.sdlDisplayIndex)) {
            return name.to!string.idup;
        }
        else {
            throw new SDLException;
        }
    }

    Rect bounds() const @property @trusted {
        Rect rect = void;
        if (SDL_GetDisplayBounds(this.sdlDisplayIndex, &rect.sdlRect) != 0) {
            throw new SDLException;
        }

        return rect;
    }

    DisplayMode[] displayModes() const @property @trusted {
        int numModes = SDL_GetNumDisplayModes(this.sdlDisplayIndex);
        if (numModes <= 0) {
            throw new SDLException;
        }

        SDL_DisplayMode[] sdlModes = new SDL_DisplayMode[](numModes);
        foreach (i; 0 .. numModes) {
            if (SDL_GetDisplayMode(this.sdlDisplayIndex, i, &sdlModes[i]) != 0) {
                throw new SDLException;
            }
        }

        DisplayMode[] modes = uninitializedArray!(DisplayMode[])(numModes);
        foreach (i, SDL_DisplayMode sdlMode; sdlModes) {
            modes[i] = DisplayMode(sdlMode);
        }

        return modes;
    }

    DisplayMode desktopDisplayMode() const @property @trusted {
        SDL_DisplayMode sdlMode = void;
        if (SDL_GetDesktopDisplayMode(this.sdlDisplayIndex, &sdlMode) != 0) {
            throw new SDLException;
        }

        return DisplayMode(sdlMode);
    }

    DisplayMode currentDisplayMode() const @property @trusted {
        SDL_DisplayMode sdlMode = void;
        if (SDL_GetCurrentDisplayMode(this.sdlDisplayIndex, &sdlMode) != 0) {
            throw new SDLException;
        }

        return DisplayMode(sdlMode);
    }

    DisplayMode getClosestDisplayMode(DisplayMode desiredMode) const @trusted {
        SDL_DisplayMode sdlDesiredMode = desiredMode.sdlDisplayMode;
        SDL_DisplayMode sdlClosestMode = void;

        if (SDL_GetClosestDisplayMode(this.sdlDisplayIndex.to!int, &sdlDesiredMode, &sdlClosestMode) is null) {
            throw new SDLException;
        }

        return DisplayMode(sdlClosestMode);
    }

    static if (sdlSupport >= SDLSupport.v2_0_4) {
        private alias DisplayDPI = Tuple!(float, "ddpi", float, "hdpi", float, "vdpi");
        DisplayDPI displayDPI() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 4));
        }
        do {
            DisplayDPI dpi = void;
            if (SDL_GetDisplayDPI(this.sdlDisplayIndex, &dpi.ddpi, &dpi.hdpi, &dpi.vdpi) != 0) {
                throw new SDLException;
            }

            return dpi;
        }
    }
}

Display[] getDisplays() @trusted {
    int numDisplays = SDL_GetNumVideoDisplays();
    if (numDisplays <= 0) {
        throw new SDLException;
    }

    static Display[] displays;
    if (displays !is null) {
        displays.length = numDisplays;
        if (numDisplays > displays.length) {
            foreach (i; displays.length .. numDisplays) {
                displays[i] = new Display(i.to!uint);
            }
        }

        return displays;
    }
    displays = new Display[](numDisplays);

    foreach (i; 0 .. numDisplays) {
        displays[i] = new Display(i);
    }

    return displays;
}
