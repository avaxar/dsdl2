/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.mouse;
@safe:

import bindbc.sdl;
import dsdl2.sdl;

import std.bitmanip : bitfields;
import std.format : format;

/++ 
 + Wraps `SDL_GetMouseState` which gets the states of the mouse buttons
 + 
 + Returns: `dsdl2.MouseState` specifying the pressed-states of the mouse buttons
 +/
MouseState getMouseState() @trusted {
    return MouseState(SDL_GetMouseState(null, null));
}

/++ 
 + Wraps `SDL_GetMouseState` which gets the mouse position relative to a focused window
 + 
 + Returns: coordinate of the mouse in the focused window
 +/
int[2] getMousePosition() @trusted {
    int[2] pos = void;
    SDL_GetMouseState(&pos[0], &pos[1]);
    return pos;
}

/++ 
 + Wraps `SDL_WarpMouseInWindow` which sets the mouse position relative to a focused window
 + 
 + Params:
 +   newPosition = new coordinate of the mouse in the focused window
 +/
void setMousePosition(int[2] newPosition) @trusted {
    SDL_Window* window = SDL_GetMouseFocus();
    if (window !is null) {
        SDL_WarpMouseInWindow(window, newPosition[0], newPosition[1]);
    }
}

/++ 
 + Wraps `SDL_GetRelativeMouseMode` which checks whether relative mouse mode is enabled or not
 +
 + Returns: `true` if relative mouse mode is enabled, otherwise `false`
 +/
bool getRelativeMouseMode() @trusted {
    return SDL_GetRelativeMouseMode() == SDL_TRUE;
}

/++ 
 + Wraps `SDL_SetRelativeMouseMode` which sets relative mouse mode
 + 
 + Params:
 +   newRelativeMouseMode = `true` to enable relative mouse mode, otherwise `false`
 + Throws: `dsdl2.SDLException` if failed to toggle relative mouse mode
 +/
void setRelativeMouseMode(bool newRelativeMouseMode) @trusted {
    if (SDL_SetRelativeMouseMode(newRelativeMouseMode) != 0) {
        throw new SDLException;
    }
}

/++ 
 + Wraps `SDL_GetRelativeMouseState` which gets the relative states of the mouse buttons
 + 
 + Returns: `dsdl2.MouseState` specifying the relative pressed-states of the mouse buttons
 +/
MouseState getRelativeMouseState() @trusted {
    return MouseState(SDL_GetRelativeMouseState(null, null));
}

/++ 
 + Wraps `SDL_GetRelativeMouseState` which gets the relative mouse position
 + 
 + Returns: relative coordinate of the mouse
 +/
int[2] getRelativeMousePosition() @trusted {
    int[2] pos = void;
    SDL_GetRelativeMouseState(&pos[0], &pos[1]);
    return pos;
}

static if (sdlSupport >= SDLSupport.v2_0_4) {
    /++ 
     + Wraps `SDL_CaptureMouse` (from SDL 2.0.4) which sets mouse capture
     + 
     + Params:
     +   newMouseCapture = `true` to enable mouse capture, otherwise `false`
     + Throws: `dsdl2.SDLException` if failed to toggle mouse capture
     +/
    void setMouseCapture(bool newMouseCapture) @trusted
    in {
        assert(getVersion() >= Version(2, 0, 4));
    }
    do {
        if (SDL_CaptureMouse(newMouseCapture) != 0) {
            throw new SDLException;
        }
    }

    /++ 
     + Wraps `SDL_GetGlobalMouseState` (from SDL 2.0.4) which gets the global states of the mouse buttons
     + 
     + Returns: `dsdl2.MouseState` specifying the global pressed-states of the mouse buttons
     +/
    MouseState getGlobalMouseState() @trusted
    in {
        assert(getVersion() >= Version(2, 0, 4));
    }
    do {
        return MouseState(SDL_GetGlobalMouseState(null, null));
    }

    /++ 
     + Wraps `SDL_GetGlobalMouseState` (from SDL 2.0.4) which gets the mouse position globally
     + 
     + Returns: coordinate of the mouse in the display
     +/
    int[2] getGlobalMousePosition() @trusted
    in {
        assert(getVersion() >= Version(2, 0, 4));
    }
    do {
        int[2] pos = void;
        SDL_GetGlobalMouseState(&pos[0], &pos[1]);
        return pos;
    }

    /++ 
     + Wraps `SDL_WarpMouseGlobal` (from SDL 2.0.4) which sets the mouse position globally in the display
     + 
     + Params:
     +   newPosition = new coordinate of the mouse in the display
     +/
    void setGlobalMousePosition(int[2] newPosition) @trusted
    in {
        assert(getVersion() >= Version(2, 0, 4));
    }
    do {
        SDL_WarpMouseGlobal(newPosition[0], newPosition[1]);
    }
}

/++ 
 + D enum that wraps `SDL_BUTTON_*` enumerations
 +/
enum MouseButton {
    /++ 
     + Wraps `SDL_BUTTON_*` enumeration constants
     +/
    left = SDL_BUTTON_LEFT,
    middle = SDL_BUTTON_MIDDLE, /// ditto
    right = SDL_BUTTON_RIGHT, /// ditto
    x1 = SDL_BUTTON_X1, /// ditto
    x2 = SDL_BUTTON_X2
}

/++ 
 + D struct that encapsulates mouse button state flags
 +/
struct MouseState {
    mixin(bitfields!(
            bool, "left", 1,
            bool, "middle", 1,
            bool, "right", 1,
            bool, "x1", 1,
            bool, "x2", 1,
            bool, "", 3));

    /++ 
     + Constructs a `dsdl2.MouseState` from a vanilla SDL mouse state flag
     + 
     + Params:
     +   sdlMouseState = the `uint` flag
     +/
    this(uint sdlMouseState) {
        this.left = (sdlMouseState & SDL_BUTTON_LMASK) != 0;
        this.middle = (sdlMouseState & SDL_BUTTON_MMASK) != 0;
        this.right = (sdlMouseState & SDL_BUTTON_RMASK) != 0;
        this.x1 = (sdlMouseState & SDL_BUTTON_X1MASK) != 0;
        this.x2 = (sdlMouseState & SDL_BUTTON_X2MASK) != 0;
    }

    /++ 
     + Constructs a `dsdl2.MouseState` by providing the flags
     + 
     + Params:
     +   base   = base flag to assign (`0` for none)
     +   left   = whether the left mouse button is pressed
     +   middle = whether the middle mouse button is pressed
     +   right  = whether the right mouse button is pressed
     +   x1     = whether the X1 mouse button is pressed
     +   x2     = whether the X2 mouse button is pressed
     +/
    this(uint base, bool left = false, bool middle = false, bool right = false, bool x1 = false, bool x2 = false) {
        this(base);
        this.left = left;
        this.middle = middle;
        this.right = right;
        this.x1 = x1;
        this.x2 = x2;
    }

    /++ 
     + Formats the `dsdl2.MouseState` into its construction representation:
     + `"dsdl2.MouseState(<sdlMouseState>, <left>, <middle>, <right>, <x1>, <x2>)"`
     + 
     + Returns: the formatted `string`
     +/
    string toString() const {
        return "dsdl2.MouseState(%d, %s, %s, %s, %s, %s)".format(this.sdlMouseState, this.left, this.middle,
            this.right, this.x1, this.x2);
    }

    /++ 
     + Gets the internal flag representation
     + 
     + Returns: `uint` with the appropriate bitflags toggled
     +/
    uint sdlMouseState() const @property {
        return (this.left ? SDL_BUTTON_LMASK : 0)
            | (this.middle ? SDL_BUTTON_MMASK
                    : 0)
            | (this.right ? SDL_BUTTON_RMASK : 0)
            | (this.x1 ? SDL_BUTTON_X1MASK : 0)
            | (this.x2 ? SDL_BUTTON_X2MASK : 0);
    }
}
