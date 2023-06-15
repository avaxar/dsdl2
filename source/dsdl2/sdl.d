/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org/, MIT License)
 +/

module dsdl2.sdl;

import bindbc.sdl;

import std.conv : to;
import std.string : toStringz;
import std.format : format;

/++
 + SDL exception generated from `SDL_GetError()` or dsdl2-specific exceptions
 +/
class SDLException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }

    this(string file = __FILE__, size_t line = __LINE__) {
        super(SDL_GetError().to!string.idup, file, line);
    }
}

version (BindSDL_Static) {
}
else {
    /++
     + Loads any SDL2 SO/DLL dynamically
     +
     + If bindbc-sdl is compiled in dynamic-linking mode (the mode set by default), this function will exist to
     + load any SDL2 shared libraries found. This function wraps bindbc-sdl's `loadSDL`. In the aforementioned
     + dynamic-linking mode, this function has to be called before any calls to SDL2 is made. Otherwise, the
     + program would cause a segfault.
     + 
     + In static-linking mode (through `BindSDL_Static` or `BindBC_Static` version), this function doesn't exist,
     + thus will result in a compilation error when referenced.
     + 
     + Params:
     +     libName = base SDL SO/DLL file name or path to look for (By default, it looks through the path)
     + 
     + Throws: `dsdl2.SDLException` if library not found. If the library was found, but the version was incompatible,
     +         a warning through `stdin` would be issued.
     +/
    void loadSO(string libName = null) {
        SDLSupport current = libName is null ? loadSDL() : loadSDL(libName.toStringz());
        if (current == sdlSupport) {
            return;
        }

        Version wanted;
        wanted._sdlVersion = sdlSupport;

        if (current == SDLSupport.badLibrary) {
            import std.stdio : writeln;

            writeln("WARNING: dsdl2 expects SDL ", wanted.format(), ", but got ", getVersion().format(), ".");
        }
        else if (current == SDLSupport.noLibrary) {
            throw new SDLException("No SDL2 library found, especially of version " ~ wanted.format(),
                __FILE__, __LINE__);
        }
    }
}

static if (sdlSupport >= SDLSupport.v2_0_9) {
    /++
     + Wraps `SDL_INIT_*` to specify initialization and deinitialization of subsystems
     +/
    enum SubSystem : uint {
        timer = SDL_INIT_TIMER,
        audio = SDL_INIT_AUDIO,
        video = SDL_INIT_VIDEO,
        joystick = SDL_INIT_JOYSTICK,
        haptic = SDL_INIT_HAPTIC,
        gameController = SDL_INIT_GAMECONTROLLER,
        events = SDL_INIT_EVENTS,
        everything = SDL_INIT_EVERYTHING,
        sensor = SDL_INIT_SENSOR,
        noparachute = SDL_INIT_NOPARACHUTE,
    }
}
else {
    /// ditto
    enum SubSystem : uint {
        timer = SDL_INIT_TIMER,
        audio = SDL_INIT_AUDIO,
        video = SDL_INIT_VIDEO,
        joystick = SDL_INIT_JOYSTICK,
        haptic = SDL_INIT_HAPTIC,
        gameController = SDL_INIT_GAMECONTROLLER,
        events = SDL_INIT_EVENTS,
        everything = SDL_INIT_EVERYTHING,
        noparachute = SDL_INIT_NOPARACHUTE,
    }
}

/++
 + Wraps `SDL_Init` which initializes selected subsystems
 + 
 + Params:
 +     subsystems = an array of `dsdl2.SubSystem` to initialize (By default, `dsdl2.SubSystem.everything`)
 + 
 + Throws: `dsdl2.SDLException` if any selected subsystem failed to initialize
 +/
void init(const SubSystem[] subsystems = [SubSystem.everything]) {
    uint flags;
    foreach (SubSystem sub; subsystems) {
        flags |= sub;
    }

    int code = SDL_Init(flags);
    if (code != 0) {
        throw new SDLException;
    }
}

/++
 + Wraps `SDL_Quit` which entirely deinitializes SDL2
 +/
void quit() {
    SDL_Quit();
}

/++
 + Wraps `SDL_QuitSubSystem` which deinitializes specified subsystems
 +
 + Params:
 +     subsystems = an array of `dsdl2.SubSystem`s to deinitialize
 +/
void quit(const SubSystem[] subsystems) {
    uint flags;
    foreach (SubSystem sub; subsystems) {
        flags |= sub;
    }

    SDL_QuitSubSystem(flags);
}

/++
 + Wraps `SDL_WasInit` which checks whether a specified subsystem is already initialized
 + 
 + Params:
 +     subsystem = the `dsdl2.SubSystem` to be checked of its status of initialization
 +
 + Returns: `true` if initialized, otherwise `false`
 +/
bool wasInit(SubSystem subsystem) {
    return SDL_WasInit(subsystem) != 0;
}

/++ 
 + A D struct that wraps `SDL_version` containing version information
 + 
 + `dsdl2.Version` is able to contain SDL version information, composed of `major`, `minor`, and `patch`,
 + each corresponding to the three numbers in a version. This wrapper adds the ability to compare versions
 + using the comparison operator, and to format versions into string using the `.format()` method.
 +
 + Examples:
 + ---
 + auto minimumVersion = dsdl2.Version(2, 0, 0);
 + auto ourVersion = dsdl2.getVersion();
 + assert(ourVersion >= minimumVersion);
 + 
 + import std.stdio;
 + writeln("We're currently using SDL version ", ourVersion.format());
 + ---
 +/
struct Version {
    SDL_version _sdlVersion;
    alias _sdlVersion this;

    /++ 
     + Constructs a `dsdl2.Version` from a vanilla `SDL_version` from bindbc-sdl
     + 
     + Params:
     +   sdlVersion = the `SDL_version` struct
     +/
    this(SDL_version sdlVersion) {
        this._sdlVersion = sdlVersion;
    }

    /++ 
     + Constructs a `dsdl2.Version` by feeding in `major`, `minor`, and `patch` version numbers
     + 
     + Params:
     +   major = major version number
     +   minor = minor version number
     +   patch = patch verion number
     +/
    this(ubyte major, ubyte minor, ubyte patch) {
        this.major = major;
        this.minor = minor;
        this.patch = patch;
    }

    /++ 
     + Compares two `dsdl2.Version`s from chronology
     +/
    int opCmp(Version other) const {
        if (this.major != other.major) {
            return this.major - other.major;
        }
        else if (this.minor != other.minor) {
            return this.minor - other.minor;
        }
        else {
            return this.patch - other.patch;
        }
    }

    /++
     + Formats the `dsdl2.Version` into its construction representation: `"dsdl2.Version(<major>, <minor>, <patch>)"`
     +
     + Returns: the formatted `string`
     +/
    string toString() const {
        return "dsdl2.Version(%d, %d, %d)".format(this.major, this.minor, this.patch);
    }

    /++ 
     + Formats the `dsdl2.Version` into `string`: `"<major>.<minor>.<patch>"`
     + 
     + Returns: the formatted `string`
     +/
    string format() const {
        return "%d.%d.%d".format(this.major, this.minor, this.patch);
    }
}

/++ 
 + Wraps `SDL_GetVersion` which gets the version of the linked SDL2 library
 + 
 + Returns: `dsdl2.Version` of the version of the linked SDL2 library
 +/
Version getVersion() {
    Version ver;
    SDL_GetVersion(&ver._sdlVersion);
    return ver;
}

/++ 
 + Wraps `SDL_GetRevision` which returns the revision string of the linked SDL2 library
 +
 + Returns: `string` of the revision code
 +/
string getRevision() {
    return SDL_GetRevision().to!string.idup;
}

/++
 + A D enumeration that wraps `SDL_HintPriority`
 + 
 + Notes: `SDL_HINT_DEFAULT` and `SDL_HINT_OVERRIDE` are named as `low` and `high` respectively.
 +/
enum HintPriority : SDL_HintPriority {
    low = SDL_HINT_DEFAULT,
    normal = SDL_HINT_NORMAL,
    high = SDL_HINT_OVERRIDE
}

/++
 + Wraps `SDL_SetHintWithPriority` which provides giving a hint to SDL2 in runtime
 + 
 + Params:
 +     name     = name of the hint
 +     value    = value to set the hint as
 +     priority = priority of the hint configuration (by default, `dsdl2.HintPriority.normal`)
 + 
 + Returns: `true` if the hint was set, `false` otherwise
 +/
bool setHint(string name, string value, HintPriority priority = HintPriority.normal) {
    return SDL_SetHintWithPriority(name.toStringz(), value.toStringz(), priority) == SDL_TRUE;
}

static if (sdlSupport >= SDLSupport.v2_26) {
    /++
     + Wraps `SDL_ResetHints` (from SDL 2.26) which resets any user-set hints given to SDL2 to default
     +/
    void resetHints()
    in {
        assert(getVersion() >= Version(2, 26, 0));
    }
    do {
        SDL_ResetHints();
    }
}

/++
 + Wraps `SDL_GetHint` which gets the value of a specified user-set hint
 +
 + Params:
 +     name = name of the hint
 + 
 + Returns: value of the given `name` of the hint
 +/
string getHint(string name) {
    return SDL_GetHint(name.toStringz()).to!string.idup;
}

static if (sdlSupport >= SDLSupport.v2_0_5) {
    /++
     + Wraps `SDL_GetHintBoolean` (from SDL 2.0.5) which gets the value of a specified user-set hint as a `bool`
     +
     + Params:
     +     name         = name of the hint
     +     defaultValue = default returned value if the hint wasn't set
     + 
     + Returns: `bool` value of the given `name` of the hint or `defaultValue` if the hint wasn't set
     +/
    bool getHintBool(string name, bool defaultValue = false)
    in {
        assert(getVersion() >= Version(2, 0, 5));
    }
    do {
        return SDL_GetHintBoolean(name.toStringz(), defaultValue) == SDL_TRUE;
    }
}
