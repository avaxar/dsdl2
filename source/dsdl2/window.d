/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.window;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.pixels;
import dsdl2.rect;
import dsdl2.surface;

import core.memory : GC;
import std.conv : to;
import std.string : toStringz;
import std.format : format;

static if (sdlSupport >= SDLSupport.v2_0_16) {
    /++
     + D enum that wraps `SDL_WINDOW_*` enumerations in specifying window constructions
     +/
    enum WindowFlag {
        /++
         + Wraps `SDL_WINDOW_*` enumeration constants
         +/
        fullscreen = SDL_WINDOW_FULLSCREEN,
        fullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP, /// ditto
        openGL = SDL_WINDOW_OPENGL, /// ditto
        shown = SDL_WINDOW_SHOWN, /// ditto
        hidden = SDL_WINDOW_HIDDEN, /// ditto
        borderless = SDL_WINDOW_BORDERLESS, /// ditto
        resizable = SDL_WINDOW_RESIZABLE, /// ditto
        minimized = SDL_WINDOW_MINIMIZED, /// ditto
        maximized = SDL_WINDOW_MAXIMIZED, /// ditto
        inputGrabbed = SDL_WINDOW_INPUT_GRABBED, /// ditto
        inputFocus = SDL_WINDOW_INPUT_FOCUS, /// ditto
        mouseFocus = SDL_WINDOW_MOUSE_FOCUS, /// ditto
        foreign = SDL_WINDOW_FOREIGN, /// ditto
        allowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI, /// ditto
        mouseCapture = SDL_WINDOW_MOUSE_CAPTURE, /// ditto
        alwaysOnTop = SDL_WINDOW_ALWAYS_ON_TOP, /// ditto
        skipTaskbar = SDL_WINDOW_SKIP_TASKBAR, /// ditto
        utility = SDL_WINDOW_UTILITY, /// ditto
        tooltip = SDL_WINDOW_TOOLTIP, /// ditto
        popupMenu = SDL_WINDOW_POPUP_MENU, /// ditto
        vulkan = SDL_WINDOW_VULKAN, /// ditto
        metal = SDL_WINDOW_METAL, /// ditto
        mouseGrabbed = SDL_WINDOW_MOUSE_GRABBED, /// ditto
        keyboardGrabbed = SDL_WINDOW_KEYBOARD_GRABBED
    }
}
else static if (sdlSupport >= SDLSupport.v2_0_6) {
    /++
     + D enum that wraps `SDL_WINDOW_*` enumerations in specifying window constructions
     +/
    enum WindowFlag {
        /++
         + Wraps `SDL_WINDOW_*` enumeration constants
         +/
        fullscreen = SDL_WINDOW_FULLSCREEN,
        fullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP, /// ditto
        openGL = SDL_WINDOW_OPENGL, /// ditto
        shown = SDL_WINDOW_SHOWN, /// ditto
        hidden = SDL_WINDOW_HIDDEN, /// ditto
        borderless = SDL_WINDOW_BORDERLESS, /// ditto
        resizable = SDL_WINDOW_RESIZABLE, /// ditto
        minimized = SDL_WINDOW_MINIMIZED, /// ditto
        maximized = SDL_WINDOW_MAXIMIZED, /// ditto
        inputGrabbed = SDL_WINDOW_INPUT_GRABBED, /// ditto
        inputFocus = SDL_WINDOW_INPUT_FOCUS, /// ditto
        mouseFocus = SDL_WINDOW_MOUSE_FOCUS, /// ditto
        foreign = SDL_WINDOW_FOREIGN, /// ditto
        allowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI, /// ditto
        mouseCapture = SDL_WINDOW_MOUSE_CAPTURE, /// ditto
        alwaysOnTop = SDL_WINDOW_ALWAYS_ON_TOP, /// ditto
        skipTaskbar = SDL_WINDOW_SKIP_TASKBAR, /// ditto
        utility = SDL_WINDOW_UTILITY, /// ditto
        tooltip = SDL_WINDOW_TOOLTIP, /// ditto
        popupMenu = SDL_WINDOW_POPUP_MENU, /// ditto
        vulkan = SDL_WINDOW_VULKAN, /// ditto
        metal = SDL_WINDOW_METAL /// ditto
    }
}
else static if (sdlSupport >= SDLSupport.v2_0_5) {
    /++
     + D enum that wraps `SDL_WINDOW_*` enumerations in specifying window constructions
     +/
    enum WindowFlag {
        /++
         + Wraps `SDL_WINDOW_*` enumeration constants
         +/
        fullscreen = SDL_WINDOW_FULLSCREEN,
        fullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP, /// ditto
        openGL = SDL_WINDOW_OPENGL, /// ditto
        shown = SDL_WINDOW_SHOWN, /// ditto
        hidden = SDL_WINDOW_HIDDEN, /// ditto
        borderless = SDL_WINDOW_BORDERLESS, /// ditto
        resizable = SDL_WINDOW_RESIZABLE, /// ditto
        minimized = SDL_WINDOW_MINIMIZED, /// ditto
        maximized = SDL_WINDOW_MAXIMIZED, /// ditto
        inputGrabbed = SDL_WINDOW_INPUT_GRABBED, /// ditto
        inputFocus = SDL_WINDOW_INPUT_FOCUS, /// ditto
        mouseFocus = SDL_WINDOW_MOUSE_FOCUS, /// ditto
        foreign = SDL_WINDOW_FOREIGN, /// ditto
        allowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI, /// ditto
        mouseCapture = SDL_WINDOW_MOUSE_CAPTURE, /// ditto
        alwaysOnTop = SDL_WINDOW_ALWAYS_ON_TOP, /// ditto
        skipTaskbar = SDL_WINDOW_SKIP_TASKBAR, /// ditto
        utility = SDL_WINDOW_UTILITY, /// ditto
        tooltip = SDL_WINDOW_TOOLTIP, /// ditto
        popupMenu = SDL_WINDOW_POPUP_MENU /// ditto
    }
}
else static if (sdlSupport >= SDLSupport.v2_0_4) {
    /++
     + D enum that wraps `SDL_WINDOW_*` enumerations in specifying window constructions
     +/
    enum WindowFlag {
        /++
         + Wraps `SDL_WINDOW_*` enumeration constants
         +/
        fullscreen = SDL_WINDOW_FULLSCREEN,
        fullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP, /// ditto
        openGL = SDL_WINDOW_OPENGL, /// ditto
        shown = SDL_WINDOW_SHOWN, /// ditto
        hidden = SDL_WINDOW_HIDDEN, /// ditto
        borderless = SDL_WINDOW_BORDERLESS, /// ditto
        resizable = SDL_WINDOW_RESIZABLE, /// ditto
        minimized = SDL_WINDOW_MINIMIZED, /// ditto
        maximized = SDL_WINDOW_MAXIMIZED, /// ditto
        inputGrabbed = SDL_WINDOW_INPUT_GRABBED, /// ditto
        inputFocus = SDL_WINDOW_INPUT_FOCUS, /// ditto
        mouseFocus = SDL_WINDOW_MOUSE_FOCUS, /// ditto
        foreign = SDL_WINDOW_FOREIGN, /// ditto
        allowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI, /// ditto
        mouseCapture = SDL_WINDOW_MOUSE_CAPTURE /// ditto
    }
}
else static if (sdlSupport >= SDLSupport.v2_0_1) {
    /++
     + D enum that wraps `SDL_WINDOW_*` enumerations in specifying window constructions
     +/
    enum WindowFlag {
        /++
         + Wraps `SDL_WINDOW_*` enumeration constants
         +/
        fullscreen = SDL_WINDOW_FULLSCREEN,
        fullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP, /// ditto
        openGL = SDL_WINDOW_OPENGL, /// ditto
        shown = SDL_WINDOW_SHOWN, /// ditto
        hidden = SDL_WINDOW_HIDDEN, /// ditto
        borderless = SDL_WINDOW_BORDERLESS, /// ditto
        resizable = SDL_WINDOW_RESIZABLE, /// ditto
        minimized = SDL_WINDOW_MINIMIZED, /// ditto
        maximized = SDL_WINDOW_MAXIMIZED, /// ditto
        inputGrabbed = SDL_WINDOW_INPUT_GRABBED, /// ditto
        inputFocus = SDL_WINDOW_INPUT_FOCUS, /// ditto
        mouseFocus = SDL_WINDOW_MOUSE_FOCUS, /// ditto
        foreign = SDL_WINDOW_FOREIGN, /// ditto
        allowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI /// ditto
    }
}
else {
    /++
     + D enum that wraps `SDL_WINDOW_*` enumerations in specifying window constructions
     +/
    enum WindowFlag {
        /++
         + Wraps `SDL_WINDOW_*` enumeration constants
         +/
        fullscreen = SDL_WINDOW_FULLSCREEN,
        fullscreenDesktop = SDL_WINDOW_FULLSCREEN_DESKTOP, /// ditto
        openGL = SDL_WINDOW_OPENGL, /// ditto
        shown = SDL_WINDOW_SHOWN, /// ditto
        hidden = SDL_WINDOW_HIDDEN, /// ditto
        borderless = SDL_WINDOW_BORDERLESS, /// ditto
        resizable = SDL_WINDOW_RESIZABLE, /// ditto
        minimized = SDL_WINDOW_MINIMIZED, /// ditto
        maximized = SDL_WINDOW_MAXIMIZED, /// ditto
        inputGrabbed = SDL_WINDOW_INPUT_GRABBED, /// ditto
        inputFocus = SDL_WINDOW_INPUT_FOCUS, /// ditto
        mouseFocus = SDL_WINDOW_MOUSE_FOCUS, /// ditto
        foreign = SDL_WINDOW_FOREIGN /// ditto
    }
}

/++
 + D class that wraps `SDL_Window` managing a window instance specific to the OS
 +/
final class Window {
    private PixelFormat pixelFormatProxy = null;
    private Surface surfaceProxy = null;
    private bool isOwner = true;
    private void* userRef = null;

    @system SDL_Window* sdlWindow = null; /// Internal `SDL_Window` 

    /++ 
     + Constructs a `dsdl2.Window` from a vanilla `SDL_Window*` from bindbc-sdl
     + 
     + Params:
     +   sdlWindow = the `SDL_Window` pointer to manage
     +   isOwner   = whether the instance owns the given `SDL_Window*` and should destroy it on its own
     +   userRef   = optional pointer to maintain reference link, avoiding GC cleanup
     +/
    this(SDL_Window* sdlWindow, bool isOwner = true, void* userRef = null) @system
    in {
        assert(sdlWindow !is null);
    }
    do {
        this.sdlWindow = sdlWindow;
        this.isOwner = isOwner;
        this.userRef = userRef;

        this.pixelFormatProxy = new PixelFormat(SDL_GetWindowPixelFormat(this.sdlWindow));
        this.surfaceProxy = new Surface(SDL_GetWindowSurface(this.sdlWindow), false, cast(void*) this);
    }

    /++ 
     + Creates an SDL-handled window from a native pointer handle of the OS, which wraps `SDL_CreateWindowFrom`
     + 
     + Params:
     +   nativeHandle = pointer to the native OS window
     + Throws: `dsdl2.SDLException` if window creation failed
     +/
    this(void* nativeHandle) @system
    in {
        assert(nativeHandle !is null);
    }
    do {
        this.sdlWindow = SDL_CreateWindowFrom(nativeHandle);
        if (this.sdlWindow is null) {
            throw new SDLException;
        }

        this.pixelFormatProxy = new PixelFormat(SDL_GetWindowPixelFormat(this.sdlWindow));
        this.surfaceProxy = new Surface(SDL_GetWindowSurface(this.sdlWindow), false, cast(void*) this);
    }

    /++ 
     + Creates a window on the desktop, which wraps `SDL_CreateWindow`
     + 
     + Params:
     +   title    = title given to the shown window
     +   position = top-left position of the window in the desktop environment
     +   size     = size of the window in pixels
     +   flags    = optional flags given to the window
     + Throws: `dsdl2.SDLException` if window creation failed
     +/
    this(string title, uint[2] position, uint[2] size, WindowFlag[] flags = []) @trusted
    in {
        assert(title !is null);
    }
    do {
        uint intFlags;
        foreach (flag; flags) {
            intFlags |= flag;
        }

        this.sdlWindow = SDL_CreateWindow(title.toStringz(), position[0].to!int, position[1].to!int,
        size[0].to!int, size[1].to!int, intFlags);
        if (this.sdlWindow is null) {
            throw new SDLException;
        }

        this.pixelFormatProxy = new PixelFormat(SDL_GetWindowPixelFormat(this.sdlWindow));
        this.surfaceProxy = new Surface(SDL_GetWindowSurface(this.sdlWindow), false, cast(void*) this);
    }

    ~this() @trusted {
        if (this.isOwner) {
            SDL_DestroyWindow(this.sdlWindow);
        }
    }

    @trusted invariant {
        // Instance might be in an invalid state due to holding a non-owned externally-freed object when
        // destructed in an unpredictable order.
        if (!this.isOwner && GC.inFinalizer) {
            return;
        }

        assert(this.sdlWindow !is null);
        assert(this.pixelFormatProxy !is null);
        assert(this.surfaceProxy !is null);
    }

    /++ 
     + Wraps `SDL_GetWindowID` which gets the internal window ID of the `dsdl2.Window`
     + 
     + Returns: `uint` of the internal window ID
     +/
    uint id() const @property @trusted {
        return SDL_GetWindowID(cast(SDL_Window*) this.sdlWindow);
    }

    /++ 
     + Wraps `SDL_GetWindowDisplayIndex` which gets the index of the display where the center of the window
     + is located
     + 
     + Returns: `uint` of the display index
     + Throws: `dsdl2.SDLException` if failed to get the display index
     +/
    uint displayIndex() const @property @trusted {
        int display = SDL_GetWindowDisplayIndex(cast(SDL_Window*) this.sdlWindow);
        if (display < 0) {
            throw new SDLException;
        }

        return display;
    }

    /++ 
     + Gets the `dsdl2.PixelFormat` used for pixel data of the `dsdl2.Window`
     + 
     + Returns: read-only `dsdl2.PixelFormat` instance
     +/
    const(PixelFormat) pixelFormat() const @property @trusted {
        // If the pixel format of the window happen to change, redo the proxy.
        if (pixelFormat.sdlPixelFormatEnum != SDL_GetWindowPixelFormat(
                cast(SDL_Window*) this.sdlWindow)) {
            (cast(Window) this).pixelFormatProxy = new PixelFormat(
                SDL_GetWindowPixelFormat(cast(SDL_Window*) this.sdlWindow));
        }

        return this.pixelFormatProxy;
    }

    /++ 
     + Checks whether the `dsdl2.Window` was created with the following `flag`, which wraps `SDL_GetWindowFlags`
     + 
     + Params:
     +   flag = corresponding `dsdl2.WindowFlag`
     + Returns: `true` it was, otherwise `false`
     +/
    bool hasFlag(WindowFlag flag) const @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & flag) != 0;
    }

    /++ 
     + Wraps `SDL_GetWindowTitle` which gets the shown title of the `dsdl2.Window`
     + 
     + Returns: title `string` of the `dsdl2.Window`
     +/
    string title() const @property @trusted {
        return SDL_GetWindowTitle(cast(SDL_Window*) this.sdlWindow).to!string.idup;
    }

    /++ 
     + Wraps `SDL_SetWindowTitle` which sets a new title to the `dsdl2.Window`
     + 
     + Params:
     +   newTitle = `string` of the new title
     +/
    void title(string newTitle) @property @trusted {
        SDL_SetWindowTitle(this.sdlWindow, newTitle.toStringz());
    }

    /++ 
     + Wraps `SDL_GetWindowPosition` which gets the top-left coordinate position of the `dsdl2.Window` in
     + the desktop environment
     +
     + Returns: top-left coordinate position of the `dsdl2.Window` in the desktop environment
     +/
    uint[2] position() const @property @trusted {
        uint[2] xy;
        SDL_GetWindowPosition(cast(SDL_Window*) this.sdlWindow, cast(int*)&xy[0], cast(int*)&xy[1]);
        return xy;
    }

    /++ 
     + Wraps `SDL_SetWindowPosition` which sets the position of the `dsdl2.Window` in the desktop environment
     +
     + Params:
     +   newPosition = top-left coordinate of the new `dsdl2.Window` position in the desktop environment
     +/
    void position(uint[2] newPosition) @property @trusted {
        SDL_SetWindowPosition(this.sdlWindow, newPosition[0].to!int, newPosition[1].to!int);
    }

    /++ 
     + Wraps `SDL_GetWindowSize` which gets the size of the `dsdl2.Window` in pixels
     + 
     + Returns: size of the `dsdl2.Window` in pixels
     +/
    uint[2] size() const @property @trusted {
        uint[2] wh;
        SDL_GetWindowSize(cast(SDL_Window*) this.sdlWindow, cast(int*)&wh[0], cast(int*)&wh[1]);
        return wh;
    }

    /++ 
     + Wraps `SDL_SetWindowSize` which sets the size of the `dsdl2.Window` in pixels
     + 
     + Params:
     +   newSize = new size of the `dsdl2.Window` in pixels (width and height)
     +/
    void size(uint[2] newSize) @property @trusted {
        SDL_SetWindowSize(this.sdlWindow, newSize[0].to!int, newSize[1].to!int);
    }

    /++ 
     + Wraps `SDL_GetWindowMinimumSize` which gets the minimum size in pixels that the `dsdl2.Window` can be
     + resized to
     + 
     + Returns: minimum set size of the `dsdl2.Window` in pixels
     +/
    uint[2] minimumSize() const @property @trusted {
        uint[2] wh;
        SDL_GetWindowMinimumSize(cast(SDL_Window*) this.sdlWindow, cast(int*)&wh[0], cast(int*)&wh[1]);
        return wh;
    }

    /++ 
     + Wraps `SDL_SetWindowMinimumSize` which sets the minimum size in pixels that the `dsdl2.Window` can be
     + resized to
     + 
     + Params:
     +   newMinimumSize = new minimum set size of the `dsdl2.Window` in pixels (width and height)
     +/
    void minimumSize(uint[2] newMinimumSize) @property @trusted {
        SDL_SetWindowMinimumSize(this.sdlWindow, newMinimumSize[0].to!int,
        newMinimumSize[1].to!int);
    }

    /++ 
     + Wraps `SDL_GetWindowMaximumSize` which gets the maximum size in pixels that the `dsdl2.Window` can be
     + resized to
     + 
     + Returns: maximum set size of the `dsdl2.Window` in pixels
     +/
    uint[2] maximumSize() const @property @trusted {
        uint[2] wh;
        SDL_GetWindowMaximumSize(cast(SDL_Window*) this.sdlWindow, cast(int*)&wh[0], cast(int*)&wh[1]);
        return wh;
    }

    /++ 
     + Wraps `SDL_SetWindowMaximumSize` which sets the maximum size in pixels that the `dsdl2.Window` can be
     + resized to
     + 
     + Params:
     +   newMaximumSize = new maximum set size of the `dsdl2.Window` in pixels (width and height)
     +/
    void maximumSize(uint[2] newMaximumSize) @property @trusted {
        SDL_SetWindowMaximumSize(this.sdlWindow, newMaximumSize[0].to!int,
        newMaximumSize[1].to!int);
    }

    bool bordered() const @property @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & SDL_WINDOW_BORDERLESS) == 0;
    }

    void bordered(bool newBordered) @property @trusted {
        SDL_SetWindowBordered(this.sdlWindow, newBordered);
    }

    void show() @trusted {
        SDL_ShowWindow(this.sdlWindow);
    }

    void hide() @trusted {
        SDL_HideWindow(this.sdlWindow);
    }

    void raise() @trusted {
        SDL_RaiseWindow(this.sdlWindow);
    }

    void maximize() @trusted {
        SDL_MaximizeWindow(this.sdlWindow);
    }

    void minimize() @trusted {
        SDL_MinimizeWindow(this.sdlWindow);
    }

    void restore() @trusted {
        SDL_RestoreWindow(this.sdlWindow);
    }

    bool resizable() const @property @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & SDL_WINDOW_RESIZABLE) != 0;
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        void resizable(bool newResizable) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
        }
        do {
            SDL_SetWindowResizable(this.sdlWindow, newResizable);
        }
    }

    bool fullscreen() const @property @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & SDL_WINDOW_FULLSCREEN) != 0;
    }

    void fullscreen(bool newFullscreen) @property @trusted {
        if (SDL_SetWindowFullscreen(this.sdlWindow, newFullscreen ? SDL_WINDOW_FULLSCREEN : 0) != 0) {
            throw new SDLException;
        }
    }

    bool grab() const @property @trusted {
        return SDL_GetWindowGrab(cast(SDL_Window*) this.sdlWindow) == SDL_TRUE;
    }

    void grab(bool newGrab) @property @trusted {
        SDL_SetWindowGrab(this.sdlWindow, newGrab);
    }

    float brightness() const @property @trusted {
        return SDL_GetWindowBrightness(cast(SDL_Window*) this.sdlWindow);
    }

    void brightness(float newBrightness) @property @trusted {
        if (SDL_SetWindowBrightness(this.sdlWindow, newBrightness) != 0) {
            throw new SDLException;
        }
    }

    inout(Surface) surface() inout @property @trusted {
        SDL_Surface* surfacePtr = SDL_GetWindowSurface(cast(SDL_Window*) this.sdlWindow);
        if (surfacePtr is null) {
            throw new SDLException;
        }

        // If the surface pointer happen to change, rewire the proxy.
        if (this.surfaceProxy.sdlSurface !is surfacePtr) {
            (cast(Window) this).surfaceProxy.sdlSurface = surfacePtr;
        }

        return this.surfaceProxy;
    }

    void update() @trusted {
        if (SDL_UpdateWindowSurface(this.sdlWindow) != 0) {
            throw new SDLException;
        }
    }

    void update(Rect[] rects) @trusted {
        if (SDL_UpdateWindowSurfaceRects(this.sdlWindow, cast(SDL_Rect*) rects.ptr,
                rects.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        void focus() @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
        }
        do {
            if (SDL_SetWindowInputFocus(this.sdlWindow) != 0) {
                throw new SDLException;
            }
        }

        void modalFor(Window parent) @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
            assert(parent !is null);
        }
        do {
            if (SDL_SetWindowModalFor(this.sdlWindow, parent.sdlWindow) != 0) {
                throw new SDLException;
            }
        }

        float opacity() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
        }
        do {
            float alpha = void;
            if (SDL_GetWindowOpacity(cast(SDL_Window*) this.sdlWindow, &alpha) != 0) {
                throw new SDLException;
            }

            return alpha;
        }

        void opacity(float newOpacity) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
        }
        do {
            if (SDL_SetWindowOpacity(this.sdlWindow, newOpacity) != 0) {
                throw new SDLException;
            }
        }
    }
}
