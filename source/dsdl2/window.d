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
import dsdl2.video;

import core.memory : GC;
import std.conv : to;
import std.string : toStringz;
import std.typecons : Nullable, nullable;

/++
 + D enum that wraps `SDL_WINDOWPOS_*` to specify certain state of position in `dsdl2.Window` construction
 +/
enum WindowPos : uint {
    centered = SDL_WINDOWPOS_CENTERED, /// Wraps `SDL_WINDOWPOS_CENTERED` which sets the window to be in the center
    undefined = SDL_WINDOWPOS_UNDEFINED /// Wraps `SDL_WINDOWPOS_UNDEFINED` which leaves the window's position undefined
}

static if (sdlSupport >= SDLSupport.v2_0_16) {
    /++
     + D enum that wraps `SDL_WindowFlags` in specifying window constructions
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
     + D enum that wraps `SDL_WindowFlags` in specifying window constructions
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
     + D enum that wraps `SDL_WindowFlags` in specifying window constructions
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
     + D enum that wraps `SDL_WindowFlags` in specifying window constructions
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
     + D enum that wraps `SDL_WindowFlags` in specifying window constructions
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
     + D enum that wraps `SDL_WindowFlags` in specifying window constructions
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

static if (sdlSupport >= SDLSupport.v2_0_16) {
    /++
     + D enum that wraps `SDL_FlashOperation` (from SDL 2.0.16) defining window flashing operations
     +/
    enum FlashOperation {
        /++
         + Wraps `SDL_FLASH_*` enumeration constants
         +/
        cancel = SDL_FLASH_CANCEL,
        briefly = SDL_FLASH_BRIEFLY, /// ditto
        untilFocused = SDL_FLASH_UNTIL_FOCUSED /// ditto
    }
}

/++
 + D class that wraps `SDL_Window` managing a window instance specific to the OS
 +
 + `dsdl2.Window` provides access to creating windows and managing them for rendering. Internally, SDL uses
 + OS functions to summon the window.
 +
 + Examples:
 + ---
 + auto window = new dsdl2.Window("My Window", [
 +     dsdl2.WindowPos.undefined, dsdl2.WindowPos.undefined
 + ], [800, 600]);
 + window.surface.fill(dsdl2.Color(255, 0, 0));
 + window.update();
 + ---
 +/
final class Window {
    private PixelFormat pixelFormatProxy = null;
    private Surface surfaceProxy = null;
    private bool isOwner = true;
    private void* userRef = null;

    @system SDL_Window* sdlWindow = null; /// Internal `SDL_Window` pointer

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
     + Creates a window on the desktop placed at a coordinate in the screen, which wraps `SDL_CreateWindow`
     +
     + Params:
     +   title    = title given to the shown window
     +   position = top-left position of the window in the desktop environment (pair of two `uint`s or flags
     +              from `dsdl2.WindowPos`)
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
     + Wraps `SDL_GetWindowDisplayIndex` which gets the display where the center of the window is located
     +
     + Returns: `dsdl2.Display` of the display the window is located
     + Throws: `dsdl2.SDLException` if failed to get the display
     +/
    Display display() const @property @trusted {
        int index = SDL_GetWindowDisplayIndex(cast(SDL_Window*) this.sdlWindow);
        if (index < 0) {
            throw new SDLException;
        }

        return getDisplays()[index];
    }

    /++
     + Wraps `SDL_GetWindowDisplayMode` which gets the window's display mode attributes
     +
     + Returns: `dsdl2.DisplayMode` storing the attributes
     + Throws: `dsdl2.SDLException` if failed to get the display mode
     +/
    DisplayMode displayMode() const @property @trusted {
        SDL_DisplayMode sdlMode = void;
        if (SDL_GetWindowDisplayMode(cast(SDL_Window*) this.sdlWindow, &sdlMode) != 0) {
            throw new SDLException;
        }

        return DisplayMode(sdlMode);
    }

    /++
     + Wraps `SDL_SetWindowDisplayMode` which sets new display mode attributes to the window
     +
     + Params:
     +   newDisplayMode = `dsdl2.DisplayMode` containing the desired attributes
     + Throws: `dsdl2.SDLException` if failed to set the display mode
     +/
    void displayMode(DisplayMode newDisplayMode) @property @trusted {
        SDL_DisplayMode sdlMode = newDisplayMode.sdlDisplayMode;
        if (SDL_SetWindowDisplayMode(this.sdlWindow, &sdlMode) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Gets the `dsdl2.PixelFormat` used for pixel data of the window
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
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & flag) == flag;
    }

    /++
     + Wraps `SDL_GetWindowFlags` which gets an array of flags the window has
     +
     + Returns: `dsdl2.WindowFlag` array of the window
     +/
    WindowFlag[] flags() const @property @trusted {
        uint sdlFlags = SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow);
        WindowFlag[] windowFlags;

        foreach (flagStr; __traits(allMembers, WindowFlag)) {
            WindowFlag flag = mixin("WindowFlag." ~ flagStr);
            if ((sdlFlags & flag) == flag) {
                windowFlags ~= flag;
            }
        }

        return windowFlags;
    }

    /++
     + Wraps `SDL_GetWindowTitle` which gets the shown title of the window
     +
     + Returns: title `string` of the window
     +/
    string title() const @property @trusted {
        return SDL_GetWindowTitle(cast(SDL_Window*) this.sdlWindow).to!string.idup;
    }

    /++
     + Wraps `SDL_SetWindowTitle` which sets a new title to the window
     +
     + Params:
     +   newTitle = `string` of the new title
     +/
    void title(string newTitle) @property @trusted {
        SDL_SetWindowTitle(this.sdlWindow, newTitle.toStringz());
    }

    /++
     + Wraps `SDL_SetWindowIcon` which sets a new icon to the window
     +
     + Params:
     +   newIcon = `dsdl2.Surface` of the new icon
     +/
    void icon(Surface newIcon) @property @trusted
    in {
        assert(newIcon !is null);
    }
    do {
        SDL_SetWindowIcon(this.sdlWindow, newIcon.sdlSurface);
    }

    /++
     + Wraps `SDL_GetWindowPosition` which gets the top-left coordinate position of the window in
     + the desktop environment
     +
     + Returns: top-left coordinate position of the window in the desktop environment
     +/
    uint[2] position() const @property @trusted {
        uint[2] xy;
        SDL_GetWindowPosition(cast(SDL_Window*) this.sdlWindow, cast(int*)&xy[0], cast(int*)&xy[1]);
        return xy;
    }

    /++
     + Wraps `SDL_SetWindowPosition` which sets the position of the window in the desktop environment
     +
     + Params:
     +   newPosition = top-left coordinate of the new window position in the desktop environment
     +/
    void position(uint[2] newPosition) @property @trusted {
        SDL_SetWindowPosition(this.sdlWindow, newPosition[0].to!int, newPosition[1].to!int);
    }

    /++
     + Wraps `SDL_GetWindowSize` which gets the drawable size of the window in pixels
     +
     + Returns: drawable size of the window in pixels
     +/
    uint[2] size() const @property @trusted {
        uint[2] wh;
        SDL_GetWindowSize(cast(SDL_Window*) this.sdlWindow, cast(int*)&wh[0], cast(int*)&wh[1]);
        return wh;
    }

    /++
     + Wraps `SDL_SetWindowSize` which sets the drawable size of the window in pixels
     +
     + Params:
     +   newSize = drawable new size of the window in pixels (width and height)
     +/
    void size(uint[2] newSize) @property @trusted {
        SDL_SetWindowSize(this.sdlWindow, newSize[0].to!int, newSize[1].to!int);
    }

    /++
     + Wraps `SDL_GetWindowMinimumSize` which gets the minimum size in pixels that the window can be
     + resized to
     +
     + Returns: minimum set size of the window in pixels
     +/
    uint[2] minimumSize() const @property @trusted {
        uint[2] wh;
        SDL_GetWindowMinimumSize(cast(SDL_Window*) this.sdlWindow, cast(int*)&wh[0], cast(
            int*)&wh[1]);
        return wh;
    }

    /++
     + Wraps `SDL_SetWindowMinimumSize` which sets the minimum size in pixels that the window can be
     + resized to
     +
     + Params:
     +   newMinimumSize = new minimum set size of the window in pixels (width and height)
     +/
    void minimumSize(uint[2] newMinimumSize) @property @trusted {
        SDL_SetWindowMinimumSize(this.sdlWindow, newMinimumSize[0].to!int,
        newMinimumSize[1].to!int);
    }

    /++
     + Wraps `SDL_GetWindowMaximumSize` which gets the maximum size in pixels that the window can be
     + resized to
     +
     + Returns: maximum set size of the window in pixels
     +/
    uint[2] maximumSize() const @property @trusted {
        uint[2] wh;
        SDL_GetWindowMaximumSize(cast(SDL_Window*) this.sdlWindow, cast(int*)&wh[0], cast(
            int*)&wh[1]);
        return wh;
    }

    /++
     + Wraps `SDL_SetWindowMaximumSize` which sets the maximum size in pixels that the window can be
     + resized to
     +
     + Params:
     +   newMaximumSize = new maximum set size of the window in pixels (width and height)
     +/
    void maximumSize(uint[2] newMaximumSize) @property @trusted {
        SDL_SetWindowMaximumSize(this.sdlWindow, newMaximumSize[0].to!int,
        newMaximumSize[1].to!int);
    }

    /++
     + Checks whether the borders of the window are visible
     +
     + Returns: `true` if borders are visible, otherwise `false`
     +/
    bool bordered() const @property @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & SDL_WINDOW_BORDERLESS) !=
            SDL_WINDOW_BORDERLESS;
    }

    /++
     + Wraps `SDL_SetWindowBordered` which sets whether the borders' visibility
     +
     + Params:
     +   newBordered = `true` to make the borders visible, otherwise `false`
     +/
    void bordered(bool newBordered) @property @trusted {
        SDL_SetWindowBordered(this.sdlWindow, newBordered);
    }

    /++
     + Wraps `SDL_ShowWindow` which sets the window to be visible in the desktop environment
     +/
    void show() @trusted {
        SDL_ShowWindow(this.sdlWindow);
    }

    /++
     + Wraps `SDL_HideWindow` which sets the window to be invisible in the desktop environment
     +/
    void hide() @trusted {
        SDL_HideWindow(this.sdlWindow);
    }

    /++
     + Wraps `SDL_RaiseWindow` which raises the window above other windows, and sets input focus to the window
     +/
    void raise() @trusted {
        SDL_RaiseWindow(this.sdlWindow);
    }

    /++
     + Wraps `SDL_MaximizeWindow` which maximizes the window in the desktop environment
     +/
    void maximize() @trusted {
        SDL_MaximizeWindow(this.sdlWindow);
    }

    /++
     + Wraps `SDL_MinimizeWindow` which minimizes the window in the desktop environment
     +/
    void minimize() @trusted {
        SDL_MinimizeWindow(this.sdlWindow);
    }

    /++
     + Wraps `SDL_RestoreWindow` which restores the size and position of the window as it was originally
     +/
    void restore() @trusted {
        SDL_RestoreWindow(this.sdlWindow);
    }

    /++
     + Checks whether the window's size is resizable by the user
     +
     + Returns: `true` if the window is resizable, otherwise `false`
     +/
    bool resizable() const @property @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & SDL_WINDOW_RESIZABLE) ==
            SDL_WINDOW_RESIZABLE;
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        /++
         + Wraps `SDL_SetWindowResizable` (from SDL 2.0.5) which sets the window's resizability
         +
         + Params:
         +   newResizable = `true` to make the window resizable, otherwise `false`
         +/
        void resizable(bool newResizable) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
        }
        do {
            SDL_SetWindowResizable(this.sdlWindow, newResizable);
        }
    }

    /++
     + Checks whether the window is in real fullscreen
     +
     + Returns: `true` if the the window is in real fullscreen, otherwise `false`
     +/
    bool fullscreen() const @property @trusted {
        return (SDL_GetWindowFlags(cast(SDL_Window*) this.sdlWindow) & SDL_WINDOW_FULLSCREEN) ==
            SDL_WINDOW_FULLSCREEN;
    }

    /++
     + Wraps `SDL_SetWindowFullscreen` which sets the fullscreen mode of the window
     +
     + Params:
     +   newFullscreen = `true` to make the window fullscreen, otherwise `false`
     + Throws: `dsdl2.SDLException` if failed to set the window's fullscreen mode
     +/
    void fullscreen(bool newFullscreen) @property @trusted {
        if (SDL_SetWindowFullscreen(this.sdlWindow, newFullscreen ? SDL_WINDOW_FULLSCREEN : 0) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_GetWindowGrab` which gets the window's grab mode
     +
     + Returns: `true` if the window is in grab mode, otherwise `false`
     +/
    bool grab() const @property @trusted {
        return SDL_GetWindowGrab(cast(SDL_Window*) this.sdlWindow) == SDL_TRUE;
    }

    /++
     + Wraps `SDL_SetWindowGrab` which sets the window's grab mode
     +
     + Params:
     +   newGrab = `true` to set the window on grab mode, otherwise `false`
     +/
    void grab(bool newGrab) @property @trusted {
        SDL_SetWindowGrab(this.sdlWindow, newGrab);
    }

    /++
     + Wraps `SDL_GetWindowBrightness` which gets the window's brightness value
     +
     + Returns: `float` value from `0.0` to `1.0` indicating the window's brightness
     +/
    float brightness() const @property @trusted {
        return SDL_GetWindowBrightness(cast(SDL_Window*) this.sdlWindow);
    }

    /++
     + Wraps `SDL_SetWindowBrightness` which sets the window's brightness value
     +
     + Params:
     +   newBrightness = `float` value specifying the window's brightness from `0.0` (darkest) to `1.0` (brightest)
     + Throws: `dsdl2.SDLException` if failed to set the window's brightness value
     +/
    void brightness(float newBrightness) @property @trusted {
        if (SDL_SetWindowBrightness(this.sdlWindow, newBrightness) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_GetWindowSurface` which gets the window's surface for software rendering
     +
     + Returns: `dsdl2.Surface` proxy to the window's surface
     + Throws: `dsdl2.SDLException` if failed to get the window's surface
     +/
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

    /++
     + Wraps `SDL_UpdateWindowSurface` which makes the changes to the window's surface current
     +
     + Throws: `dsdl2.SDLException` if failed to update the window's changes
     +/
    void update() @trusted {
        if (SDL_UpdateWindowSurface(this.sdlWindow) != 0) {
            throw new SDLException;
        }
    }

    /++
     + Wraps `SDL_UpdateWindowSurfaceRects` which makes the changes of certain parts of the window surface
     + as defined by a list of `dsdl2.Rect`s current
     +
     + Params:
     +   rects = array of `dsdl2.Rect`s defining parts of the window surface to update
     + Throws: `dsdl2.SDLException` if failed to update the window's changes
     +/
    void update(Rect[] rects) @trusted {
        if (SDL_UpdateWindowSurfaceRects(this.sdlWindow, cast(SDL_Rect*) rects.ptr,
                rects.length.to!int) != 0) {
            throw new SDLException;
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_5) {
        /++
         + Wraps `SDL_SetWindowInputFocus` (from SDL 2.0.5) which focuses the window to be in reach to the user
         +
         + Throws: `dsdl2.SDLException` if failed to focus the window
         +/
        void focus() @trusted
        in {
            assert(getVersion() >= Version(2, 0, 5));
        }
        do {
            if (SDL_SetWindowInputFocus(this.sdlWindow) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_SetWindowModalFor` (from SDL 2.0.5) which sets the window to be a modal of another parent
         + window, making the window always be above its parent window
         +
         + Params:
         +   parent = the parent window which owns the window as a modal
         + Throws: `dsdl2.SDLException` if failed to set the window as modal
         +/
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

        /++
         + Wraps `SDL_GetWindowOpacity` (from SDL 2.0.5) which gets the opacity of the window
         +
         + Returns: `float` indicating the opacity of the window from `0.0` (transparent) to `1.0` (opaque)
         + Throws: `dsdl2.SDLException` if failed to get the window's opacity
         +/
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

        /++
         + Wraps `SDL_SetWindowOpacity` (from SDL 2.0.5) which sets the opacity of the window
         +
         + Params:
         +   newOpacity = `float` indicating the opacity of the window from `0.0` (transparent) to
         +                `1.0` (opaque)
         + Throws: `dsdl2.SDLException` if failed to set the window's opacity
         +/
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

    static if (sdlSupport >= SDLSupport.v2_0_16) {
        /++
         + Wraps `SDL_FlashWindow` (from SDL 2.0.16) which flashes the window in the desktop environment
         +
         + Params:
         +   operation = flashing operation to do
         + Throws: `dsdl2.SDLException` if failed to flash the window
         +/
        void flash(FlashOperation operation) @trusted
        in {
            assert(getVersion() >= Version(2, 0, 16));
        }
        do {
            if (SDL_FlashWindow(this.sdlWindow, operation) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_SetWindowAlwaysOnTop` (from SDL 2.0.16) which sets the status of the window always
         + being on top above other windows
         +
         + Params:
         +   newOnTop = `true` to always make the window to be on top, otherwise `false`
         +/
        void onTop(bool newOnTop) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 16));
        }
        do {
            SDL_SetWindowAlwaysOnTop(this.sdlWindow, newOnTop);
        }

        /++
         + Wraps `SDL_GetWindowKeyboardGrab` (from SDL 2.0.16) which gets the status of the window grabbing
         + onto keyboard input
         +
         + Returns: `true` if the window is grabbing onto keyboard input, otherwise `false`
         +/
        bool keyboardGrab() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 16));
        }
        do {
            return SDL_GetWindowKeyboardGrab(cast(SDL_Window*) this.sdlWindow) == SDL_TRUE;
        }

        /++
         + Wraps `SDL_SetWindowKeyboardGrab` (from SDL 2.0.16) which sets the status of the window grabbing
         + onto keyboard input
         +
         + Params:
         +   newKeyboardGrab = `true` to enable keyboard grab, otherwise `false`
         +/
        void keyboardGrab(bool newKeyboardGrab) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 16));
        }
        do {
            SDL_SetWindowKeyboardGrab(this.sdlWindow, newKeyboardGrab);
        }

        /++
         + Wraps `SDL_GetWindowMouseGrab` (from SDL 2.0.16) which gets the status of the window grabbing
         + onto mouse input
         +
         + Returns: `true` if the window is grabbing onto mouse input, otherwise `false`
         +/
        bool mouseGrab() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 16));
        }
        do {
            return SDL_GetWindowMouseGrab(cast(SDL_Window*) this.sdlWindow) == SDL_TRUE;
        }

        /++
         + Wraps `SDL_SetWindowMouseGrab` (from SDL 2.0.16) which sets the status of the window grabbing
         + onto mouse input
         +
         + Params:
         +   newMouseGrab = `true` to enable mouse grab, otherwise `false`
         +/
        void mouseGrab(bool newMouseGrab) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 16));
        }
        do {
            SDL_SetWindowMouseGrab(this.sdlWindow, newMouseGrab);
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_18) {
        /++
         + Wraps `SDL_GetWindowICCProfile` (from SDL 2.0.18) which gets the raw ICC profile data for the
         + screen the window is currently on
         +
         + Returns: untyped array buffer of the raw ICC profile data
         + Throws `dsdl2.SDLException` if failed to obtain the ICC profile data
         +/
        void[] iccProfile() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 18));
        }
        do {
            size_t size = void;
            void* data = SDL_GetWindowICCProfile(cast(SDL_Window*) this.sdlWindow, &size);
            scope (exit)
                SDL_free(data);

            if (data is null) {
                throw new SDLException;
            }

            // Copies the data under allocation with the GC, as `data` is a manually-handled resource
            // allocated by SDL
            return data[0 .. size].dup;
        }

        /++
         + Wraps `SDL_GetWindowMouseRect` (from SDL 2.0.18) which gets the window's mouse confinement rectangle
         +
         + Returns: `dsdl2.Rect` of the mouse's confinement rectangle in the window
         +/
        Nullable!Rect mouseRect() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 18));
        }
        do {
            const(SDL_Rect)* rect = SDL_GetWindowMouseRect(cast(SDL_Window*) this.sdlWindow);
            if (rect is null) {
                return Nullable!Rect.init;
            }
            else {
                return Rect(*rect).nullable;
            }
        }

        /++
         + Wraps `SDL_SetWindowMouseRect` (from SDL 2.0.18) which sets the window's mouse confinement rectangle
         +
         + Params:
         +   newMouseRect = `dsdl2.Rect` specifying the rectangle in window coordinate space to confine the
         +                  mouse pointer in
         + Throws: `dsdl2.SDLException` if failed to set the confinement
         +/
        void mouseRect(Rect newMouseRect) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 18));
        }
        do {
            if (SDL_SetWindowMouseRect(this.sdlWindow, &newMouseRect.sdlRect) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Acts as `SDL_SetWindowMouseRect(window, NULL)` (from SDL 2.0.18) which resets the window's mouse
         + confinement rectangle
         +
         + Throws: `dsdl2.SDLException` if failed to reset the confinement
         +/
        void mouseRect(typeof(null) _) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 18));
        }
        do {
            if (SDL_SetWindowMouseRect(this.sdlWindow, null) != 0) {
                throw new SDLException;
            }
        }

        /++
         + Wraps `SDL_SetWindowMouseRect` (from SDL 2.0.18) which sets or resets the window's mouse
         + confinement rectangle
         +
         + Params:
         +   newMouseRect = `dsdl2.Rect` specifying the rectangle in window coordinate space to confine the
         +                  mouse pointer in; `null` to reset the confinement
         + Throws: `dsdl2.SDLException` if failed to set or reset the confinement
         +/
        void mouseRect(Nullable!Rect newMouseRect) @property @trusted
        in {
            assert(getVersion() >= Version(2, 0, 18));
        }
        do {
            if (newMouseRect.isNull) {
                this.mouseRect = null;
            }
            else {
                this.mouseRect = newMouseRect.get;
            }
        }
    }

    static if (sdlSupport >= SDLSupport.v2_26) {
        /++
         + Wraps `SDL_GetWindowSizeInPixels` (from SDL 2.26) which gets the actual size of the window in the
         + screen in pixels
         +
         + Returns: actual size of the window in the screen in pixels
         +/
        uint[2] sizeInPixels() const @property @trusted
        in {
            assert(getVersion() >= Version(2, 26, 0));
        }
        do {
            uint[2] size = void;
            SDL_GetWindowSizeInPixels(cast(SDL_Window*) this.sdlWindow, cast(int*)&size[0],
            cast(int*)&size[1]);
            return size;
        }
    }
}
