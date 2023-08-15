/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.event;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.display;
import dsdl2.keyboard;
import dsdl2.mouse;

import std.conv : to;
import std.format : format;

/++
 + Wraps `SDL_PollEvent` which returns the latest event in queue
 +
 + Returns: `dsdl2.Event` if there's an event, otherwise `null`
 + Examples:
 + ---
 + // Polls every upcoming event in queue
 + while (auto event = dsdl2.pollEvent()){
 +     if (cast(dsdl2.QuitEvent)event) {
 +         dsdl2.quit();
 +     }
 + }
 + ---
 +/
Event pollEvent() @trusted {
    SDL_Event event = void;
    if (SDL_PollEvent(&event) == 1) {
        return Event.fromSDL(event);
    }
    else {
        return null;
    }
}

/++
 + D abstract class that wraps `SDL_Event` containing details of an event polled from `dsdl2.pollEvent()`
 +/
abstract class Event {
    SDL_Event sdlEvent; /// Internal `SDL_Event` struct

    override string toString() const;

    /++
     + Gets the `SDL_EventType` of the underlying `SDL_Event`
     +
     + Returns: `SDL_EventType` enumeration from bindbc-sdl
     +/
    SDL_EventType sdlEventType() const nothrow @property {
        return this.sdlEvent.type;
    }

    /++
     + Proxy to the timestamp of the `dsdl2.Event`
     +
     + Returns: timestamp of the `dsdl2.Event`
     +/
    ref inout(uint) timestamp() return inout @property {
        return this.sdlEvent.common.timestamp;
    }

    /++
     + Turns a vanilla `SDL_Event` from bindbc-sdl to `dsdl2.Event`
     +
     + Params:
     +   sdlEvent = vanilla `SDL_Event` from bindbc-sdl
     + Returns: `dsdl2.Event` of the same attributes
     +/
    static Event fromSDL(SDL_Event sdlEvent) @trusted {
        switch (sdlEvent.type) {
        default:
            return new UnknownEvent(sdlEvent);

        case SDL_QUIT:
            return new QuitEvent;

        case SDL_APP_TERMINATING:
            return new AppTerminatingEvent;

        case SDL_APP_LOWMEMORY:
            return new AppLowMemoryEvent;

        case SDL_APP_WILLENTERBACKGROUND:
            return new AppWillEnterBackgroundEvent;

        case SDL_APP_DIDENTERBACKGROUND:
            return new AppDidEnterBackgroundEvent;

        case SDL_APP_WILLENTERFOREGROUND:
            return new AppWillEnterForegroundEvent;

        case SDL_APP_DIDENTERFOREGROUND:
            return new AppDidEnterForegroundEvent;

            static if (sdlSupport >= SDLSupport.v2_0_14) {
        case SDL_LOCALECHANGED:
                return new LocaleChangeEvent;
            }

            static if (sdlSupport >= SDLSupport.v2_0_9) {
        case SDL_DISPLAYEVENT:
                return DisplayEvent.fromSDL(sdlEvent);
            }

        case SDL_WINDOWEVENT:
            return WindowEvent.fromSDL(sdlEvent);

        case SDL_SYSWMEVENT:
            return new SysWMEvent(sdlEvent.syswm.msg);

        case SDL_KEYDOWN:
        case SDL_KEYUP:
            return KeyboardEvent.fromSDL(sdlEvent);

        case SDL_TEXTEDITING:
            return new TextEditingEvent(sdlEvent.edit.windowID, sdlEvent.edit.text.ptr.to!string,
                sdlEvent.edit.start.to!size_t, sdlEvent.edit.length.to!size_t);

        case SDL_TEXTINPUT:
            return new TextInputEvent(sdlEvent.text.windowID, sdlEvent.text.text.ptr.to!string);

            static if (sdlSupport >= SDLSupport.v2_0_4) {
        case SDL_KEYMAPCHANGED:
                return new KeymapChangedEvent;
            }

        case SDL_MOUSEMOTION:
            return new MouseMotionEvent(sdlEvent.motion.windowID, sdlEvent.motion.which,
                MouseState(sdlEvent.motion.state), [
                sdlEvent.motion.x, sdlEvent.motion.y
            ], [sdlEvent.motion.xrel, sdlEvent.motion.yrel]);

        case SDL_MOUSEBUTTONDOWN:
        case SDL_MOUSEBUTTONUP:
            return MouseButtonEvent.fromSDL(sdlEvent);

        case SDL_MOUSEWHEEL:
            static if (sdlSupport >= SDLSupport.v2_0_18) {
                return new MouseWheelEvent(sdlEvent.wheel.windowID, sdlEvent.wheel.which,
                    [sdlEvent.wheel.x, sdlEvent.wheel.y], cast(MouseWheel) sdlEvent.wheel.direction,
                    [sdlEvent.wheel.preciseX, sdlEvent.wheel.preciseY]);
            }
            else static if (sdlSupport >= SDLSupport.v2_0_4) {
                return new MouseWheelEvent(sdlEvent.wheel.windowID, sdlEvent.wheel.which,
                    [sdlEvent.wheel.x, sdlEvent.wheel.y], cast(MouseWheel) sdlEvent.wheel.direction);
            }
            else {
                return new MouseWheelEvent(sdlEvent.wheel.windowID, sdlEvent.wheel.which,
                    [sdlEvent.wheel.x, sdlEvent.wheel.y]);
            }
        }
    }
}

final class UnknownEvent : Event {
    this(SDL_Event sdlEvent) {
        this.sdlEvent = sdlEvent;
    }

    override string toString() const {
        return "dsdl2.UnknownEvent(%s)".format(this.sdlEvent);
    }
}

final class QuitEvent : Event {
    this() {
        this.sdlEvent.type = SDL_QUIT;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_QUIT);
    }

    override string toString() const {
        return "dsdl2.QuitEvent()";
    }
}

final class AppTerminatingEvent : Event {
    this() {
        this.sdlEvent.type = SDL_APP_TERMINATING;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_APP_TERMINATING);
    }

    override string toString() const {
        return "dsdl2.AppTerminatingEvent()";
    }
}

final class AppLowMemoryEvent : Event {
    this() {
        this.sdlEvent.type = SDL_APP_LOWMEMORY;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_APP_LOWMEMORY);
    }

    override string toString() const {
        return "dsdl2.AppLowMemoryEvent()";
    }
}

final class AppWillEnterBackgroundEvent : Event {
    this() {
        this.sdlEvent.type = SDL_APP_WILLENTERBACKGROUND;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_APP_WILLENTERBACKGROUND);
    }

    override string toString() const {
        return "dsdl2.AppWillEnterBackgroundEvent()";
    }
}

final class AppDidEnterBackgroundEvent : Event {
    this() {
        this.sdlEvent.type = SDL_APP_DIDENTERBACKGROUND;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_APP_DIDENTERBACKGROUND);
    }

    override string toString() const {
        return "dsdl2.AppDidEnterBackgroundEvent()";
    }
}

final class AppWillEnterForegroundEvent : Event {
    this() {
        this.sdlEvent.type = SDL_APP_WILLENTERFOREGROUND;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_APP_WILLENTERFOREGROUND);
    }

    override string toString() const {
        return "dsdl2.AppWillEnterForegroundEvent()";
    }
}

final class AppDidEnterForegroundEvent : Event {
    this() {
        this.sdlEvent.type = SDL_APP_DIDENTERFOREGROUND;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_APP_DIDENTERFOREGROUND);
    }

    override string toString() const {
        return "dsdl2.AppDidEnterForegroundEvent()";
    }
}

static if (sdlSupport >= SDLSupport.v2_0_14) {
    class LocaleChangeEvent : Event {
        this() {
            this.sdlEvent.type = SDL_LOCALECHANGED;
        }

        invariant {
            assert(this.sdlEvent.type == SDL_LOCALECHANGED);
        }

        override string toString() const {
            return "dsdl2.LocaleChangeEvent()";
        }
    }
}

static if (sdlSupport >= SDLSupport.v2_0_9) {
    abstract class DisplayEvent : Event {
        invariant {
            assert(this.sdlEvent.type == SDL_DISPLAYEVENT);
        }

        SDL_DisplayEventID sdlDisplayEventID() const nothrow @property {
            return this.sdlEvent.display.event;
        }

        ref inout(uint) display() return inout @property {
            return this.sdlEvent.display.display;
        }

        static Event fromSDL(SDL_Event sdlEvent)
        in {
            assert(sdlEvent.type == SDL_DISPLAYEVENT);
        }
        do {
            switch (sdlEvent.display.event) {
            default:
                return new UnknownEvent(sdlEvent);

            case SDL_DISPLAYEVENT_ORIENTATION:
                return new DisplayOrientationEvent(sdlEvent.display.display,
                    cast(DisplayOrientation) sdlEvent.display.data1);

            case SDL_DISPLAYEVENT_CONNECTED:
                return new DisplayConnectedEvent(sdlEvent.display.display);

            case SDL_DISPLAYEVENT_DISCONNECTED:
                return new DisplayDisconnectedEvent(sdlEvent.display.display);
            }
        }
    }

    class DisplayOrientationEvent : DisplayEvent {
        this(uint display, DisplayOrientation orientation) {
            this.sdlEvent.type = SDL_DISPLAYEVENT;
            this.sdlEvent.display.event = SDL_DISPLAYEVENT_ORIENTATION;
            this.sdlEvent.display.display = display;
            this.sdlEvent.display.data1 = orientation;
        }

        invariant {
            assert(this.sdlEvent.display.event == SDL_DISPLAYEVENT_ORIENTATION);
        }

        override string toString() const {
            return "dsdl2.DisplayOrientationEvent(%d, %d)".format(this.display, this.orientation);
        }

        DisplayOrientation orientation() const @property {
            return cast(DisplayOrientation) this.sdlEvent.display.data1;
        }

        void orientation(DisplayOrientation newOrientation) @property {
            this.sdlEvent.display.data1 = newOrientation;
        }
    }

    class DisplayConnectedEvent : DisplayEvent {
        this(uint display) {
            this.sdlEvent.type = SDL_DISPLAYEVENT;
            this.sdlEvent.display.event = SDL_DISPLAYEVENT_CONNECTED;
            this.sdlEvent.display.display = display;
        }

        invariant {
            assert(this.sdlEvent.display.event == SDL_DISPLAYEVENT_CONNECTED);
        }

        override string toString() const {
            return "dsdl2.DisplayConnectedEvent(%d)".format(this.display);
        }
    }

    class DisplayDisconnectedEvent : DisplayEvent {
        this(uint display) {
            this.sdlEvent.type = SDL_DISPLAYEVENT;
            this.sdlEvent.display.event = SDL_DISPLAYEVENT_DISCONNECTED;
            this.sdlEvent.display.display = display;
        }

        invariant {
            assert(this.sdlEvent.display.event == SDL_DISPLAYEVENT_DISCONNECTED);
        }

        override string toString() const {
            return "dsdl2.DisplayDisconnectedEvent(%d)".format(this.display);
        }
    }
}

abstract class WindowEvent : Event {
    invariant {
        assert(this.sdlEvent.type == SDL_WINDOWEVENT);
    }

    SDL_WindowEventID sdlWindowEventID() const nothrow @property {
        return this.sdlEvent.window.event;
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.window.windowID;
    }

    static Event fromSDL(SDL_Event sdlEvent)
    in {
        assert(sdlEvent.type == SDL_WINDOWEVENT);
    }
    do {
        switch (sdlEvent.window.event) {
        default:
            return new UnknownEvent(sdlEvent);

        case SDL_WINDOWEVENT_SHOWN:
            return new WindowShownEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_HIDDEN:
            return new WindowHiddenEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_EXPOSED:
            return new WindowExposedEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_MOVED:
            return new WindowMovedEvent(sdlEvent.window.windowID,
                [sdlEvent.window.data1, sdlEvent.window.data2]);

        case SDL_WINDOWEVENT_RESIZED:
            return new WindowResizedEvent(sdlEvent.window.windowID,
                [sdlEvent.window.data1, sdlEvent.window.data2]);

        case SDL_WINDOWEVENT_SIZE_CHANGED:
            return new WindowSizeChangedEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_MINIMIZED:
            return new WindowMinimizedEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_MAXIMIZED:
            return new WindowMaximizedEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_RESTORED:
            return new WindowRestoredEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_ENTER:
            return new WindowEnterEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_LEAVE:
            return new WindowLeaveEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_FOCUS_GAINED:
            return new WindowFocusGainedEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_FOCUS_LOST:
            return new WindowFocusLostEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_CLOSE:
            return new WindowCloseEvent(sdlEvent.window.windowID);

            static if (sdlSupport >= SDLSupport.v2_0_5) {
        case SDL_WINDOWEVENT_TAKE_FOCUS:
                return new WindowTakeFocusEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_HIT_TEST:
                return new WindowHitTestEvent(sdlEvent.window.windowID);
            }

            static if (sdlSupport >= SDLSupport.v2_0_18) {
        case SDL_WINDOWEVENT_ICCPROF_CHANGED:
                return new WindowICCProfileChangedEvent(sdlEvent.window.windowID);

        case SDL_WINDOWEVENT_DISPLAY_CHANGED:
                return new WindowDisplayChangedEvent(sdlEvent.window.windowID, sdlEvent
                        .window.data1);
            }
        }
    }
}

final class WindowShownEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_SHOWN;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_SHOWN);
    }

    override string toString() const {
        return "dsdl2.WindowShownEvent(%d)".format(this.windowID);
    }
}

final class WindowHiddenEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_HIDDEN;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_HIDDEN);
    }

    override string toString() const {
        return "dsdl2.WindowHiddenEvent(%d)".format(this.windowID);
    }
}

final class WindowExposedEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_EXPOSED;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_EXPOSED);
    }

    override string toString() const {
        return "dsdl2.WindowExposedEvent(%d)".format(this.windowID);
    }
}

final class WindowMovedEvent : WindowEvent {
    this(uint windowID, int[2] xy) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_MOVED;
        this.sdlEvent.window.windowID = windowID;
        this.sdlEvent.window.data1 = xy[0];
        this.sdlEvent.window.data2 = xy[1];
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_MOVED);
    }

    override string toString() const {
        return "dsdl2.WindowMovedEvent(%d, %s)".format(this.windowID, this.xy);
    }

    ref inout(int) x() return inout @property {
        return this.sdlEvent.window.data1;
    }

    ref inout(int) y() return inout @property {
        return this.sdlEvent.window.data2;
    }

    int[2] xy() const @property {
        return [this.sdlEvent.window.data1, this.sdlEvent.window.data2];
    }

    void xy(int[2] newXY) @property {
        this.sdlEvent.window.data1 = newXY[0];
        this.sdlEvent.window.data2 = newXY[1];
    }
}

final class WindowResizedEvent : WindowEvent {
    this(uint windowID, uint[2] size) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_RESIZED;
        this.sdlEvent.window.windowID = windowID;
        this.sdlEvent.window.data1 = size[0].to!int;
        this.sdlEvent.window.data2 = size[1].to!int;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_RESIZED);
    }

    override string toString() const {
        return "dsdl2.WindowResizedEvent(%d, %s)".format(this.windowID, this.size);
    }

    uint width() const @property {
        return this.sdlEvent.window.data1.to!uint;
    }

    void width(uint newWidth) @property {
        this.sdlEvent.window.data1 = newWidth.to!int;
    }

    uint height() const @property {
        return this.sdlEvent.window.data2.to!uint;
    }

    void height(uint newHeight) @property {
        this.sdlEvent.window.data2 = newHeight.to!int;
    }

    uint[2] size() const @property {
        return [
            this.sdlEvent.window.data1.to!uint,
            this.sdlEvent.window.data2.to!uint
        ];
    }

    void size(uint[2] newSize) @property {
        this.sdlEvent.window.data1 = newSize[0].to!int;
        this.sdlEvent.window.data2 = newSize[1].to!int;
    }
}

final class WindowSizeChangedEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_SIZE_CHANGED;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_SIZE_CHANGED);
    }

    override string toString() const {
        return "dsdl2.WindowSizeChangedEvent(%d)".format(this.windowID);
    }
}

final class WindowMinimizedEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_MINIMIZED;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_MINIMIZED);
    }

    override string toString() const {
        return "dsdl2.WindowMinimizedEvent(%d)".format(this.windowID);
    }
}

final class WindowMaximizedEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_MAXIMIZED;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_MAXIMIZED);
    }

    override string toString() const {
        return "dsdl2.WindowMaximizedEvent(%d)".format(this.windowID);
    }
}

final class WindowRestoredEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_RESTORED;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_RESTORED);
    }

    override string toString() const {
        return "dsdl2.WindowRestoredEvent(%d)".format(this.windowID);
    }
}

final class WindowEnterEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_ENTER;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_ENTER);
    }

    override string toString() const {
        return "dsdl2.WindowEnterEvent(%d)".format(this.windowID);
    }
}

final class WindowLeaveEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_LEAVE;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_LEAVE);
    }

    override string toString() const {
        return "dsdl2.WindowLeaveEvent(%d)".format(this.windowID);
    }
}

final class WindowFocusGainedEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_FOCUS_GAINED;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_FOCUS_GAINED);
    }

    override string toString() const {
        return "dsdl2.WindowFocusGainedEvent(%d)".format(this.windowID);
    }
}

final class WindowFocusLostEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_FOCUS_LOST;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_FOCUS_LOST);
    }

    override string toString() const {
        return "dsdl2.WindowFocusLostEvent(%d)".format(this.windowID);
    }
}

final class WindowCloseEvent : WindowEvent {
    this(uint windowID) {
        this.sdlEvent.type = SDL_WINDOWEVENT;
        this.sdlEvent.window.event = SDL_WINDOWEVENT_CLOSE;
        this.sdlEvent.window.windowID = windowID;
    }

    invariant {
        assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_CLOSE);
    }

    override string toString() const {
        return "dsdl2.WindowCloseEvent(%d)".format(this.windowID);
    }
}

static if (sdlSupport >= SDLSupport.v2_0_5) {
    class WindowTakeFocusEvent : WindowEvent {
        this(uint windowID) {
            this.sdlEvent.type = SDL_WINDOWEVENT;
            this.sdlEvent.window.event = SDL_WINDOWEVENT_TAKE_FOCUS;
            this.sdlEvent.window.windowID = windowID;
        }

        invariant {
            assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_TAKE_FOCUS);
        }

        override string toString() const {
            return "dsdl2.WindowTakeFocusEvent(%d)".format(this.windowID);
        }
    }

    class WindowHitTestEvent : WindowEvent {
        this(uint windowID) {
            this.sdlEvent.type = SDL_WINDOWEVENT;
            this.sdlEvent.window.event = SDL_WINDOWEVENT_HIT_TEST;
            this.sdlEvent.window.windowID = windowID;
        }

        invariant {
            assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_HIT_TEST);
        }

        override string toString() const {
            return "dsdl2.WindowHitTestEvent(%d)".format(this.windowID);
        }
    }
}

static if (sdlSupport >= SDLSupport.v2_0_18) {
    class WindowICCProfileChangedEvent : WindowEvent {
        this(uint windowID) {
            this.sdlEvent.type = SDL_WINDOWEVENT;
            this.sdlEvent.window.event = SDL_WINDOWEVENT_ICCPROF_CHANGED;
            this.sdlEvent.window.windowID = windowID;
        }

        invariant {
            assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_ICCPROF_CHANGED);
        }

        override string toString() const {
            return "dsdl2.WindowICCProfileChangedEvent(%d)".format(this.windowID);
        }
    }

    class WindowDisplayChangedEvent : WindowEvent {
        this(uint windowID, uint display) {
            this.sdlEvent.type = SDL_WINDOWEVENT;
            this.sdlEvent.window.event = SDL_WINDOWEVENT_DISPLAY_CHANGED;
            this.sdlEvent.window.windowID = windowID;
            this.sdlEvent.window.data1 = display.to!int;
        }

        invariant {
            assert(this.sdlEvent.window.event == SDL_WINDOWEVENT_DISPLAY_CHANGED);
        }

        override string toString() const {
            return "dsdl2.WindowDisplayChangedEvent(%d)".format(this.windowID, this.display);
        }

        ref inout(int) display() return inout @property {
            return this.sdlEvent.window.data1;
        }
    }
}

final class SysWMEvent : Event {
    this(SDL_SysWMmsg* msg) @system {
        this.sdlEvent.type = SDL_SYSWMEVENT;
        this.sdlEvent.syswm.msg = msg;
    }

    @trusted invariant {
        assert(this.sdlEvent.syswm.msg !is null);
    }

    override string toString() const @trusted {
        return "dsdl2.SysWMEvent(0x%x)".format(this.msg);
    }

    ref inout(SDL_SysWMmsg*) msg() return inout @property @system {
        return this.sdlEvent.syswm.msg;
    }
}

abstract class KeyboardEvent : Event {
    invariant {
        assert(this.sdlEvent.type == SDL_KEYDOWN || this.sdlEvent.type == SDL_KEYUP);
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.key.windowID;
    }

    ref inout(ubyte) repeat() return inout @property {
        return this.sdlEvent.key.repeat;
    }

    Scancode scancode() const @property {
        return cast(Scancode) this.sdlEvent.key.keysym.scancode;
    }

    void scancode(Scancode newScancode) @property {
        this.sdlEvent.key.keysym.scancode = cast(SDL_Scancode) newScancode;
    }

    Keycode sym() const @property {
        return cast(Keycode) this.sdlEvent.key.keysym.sym;
    }

    void sym(Keycode newSym) @property {
        this.sdlEvent.key.keysym.sym = cast(SDL_Keycode) newSym;
    }

    Keymod mod() const @property {
        return Keymod(this.sdlEvent.key.keysym.mod);
    }

    void mod(Keymod newMod) @property {
        this.sdlEvent.key.keysym.mod = newMod.sdlKeymod;
    }

    static Event fromSDL(SDL_Event sdlEvent)
    in {
        assert(sdlEvent.type == SDL_KEYDOWN || sdlEvent.type == SDL_KEYUP);
    }
    do {
        switch (sdlEvent.type) {
        default:
            assert(false);

        case SDL_KEYDOWN:
            return new KeyDownKeyboardEvent(sdlEvent.key.windowID, sdlEvent.key.repeat,
                cast(Scancode) sdlEvent.key.keysym.scancode, cast(Keycode) sdlEvent.key.keysym.sym,
                Keymod(sdlEvent.key.keysym.mod));

        case SDL_KEYUP:
            return new KeyUpKeyboardEvent(sdlEvent.key.windowID, sdlEvent.key.repeat,
                cast(Scancode) sdlEvent.key.keysym.scancode, cast(Keycode) sdlEvent.key.keysym.sym,
                Keymod(sdlEvent.key.keysym.mod));
        }
    }
}

final class KeyDownKeyboardEvent : KeyboardEvent {
    this(uint windowID, ubyte repeat, Scancode scancode, Keycode sym, Keymod mod) {
        this.sdlEvent.type = SDL_KEYDOWN;
        this.sdlEvent.key.windowID = windowID;
        this.sdlEvent.key.repeat = repeat;
        this.sdlEvent.key.keysym.scancode = cast(SDL_Scancode) scancode;
        this.sdlEvent.key.keysym.sym = cast(SDL_Keycode) sym;
        this.sdlEvent.key.keysym.mod = mod.sdlKeymod;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_KEYDOWN);
    }

    override string toString() const {
        return "dsdl2.KeyDownKeyboardEvent(%d, %d, %s, %s, %s)".format(this.windowID, this.repeat, this.scancode,
            this.sym, this.mod);
    }
}

final class KeyUpKeyboardEvent : KeyboardEvent {
    this(uint windowID, ubyte repeat, Scancode scancode, Keycode sym, Keymod mod) {
        this.sdlEvent.type = SDL_KEYUP;
        this.sdlEvent.key.windowID = windowID;
        this.sdlEvent.key.repeat = repeat;
        this.sdlEvent.key.keysym.scancode = cast(SDL_Scancode) scancode;
        this.sdlEvent.key.keysym.sym = cast(SDL_Keycode) sym;
        this.sdlEvent.key.keysym.mod = mod.sdlKeymod;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_KEYUP);
    }

    override string toString() const {
        return "dsdl2.KeyUpKeyboardEvent(%d, %d, %s, %s, %s)".format(this.windowID, this.repeat, this.scancode,
            this.sym, this.mod);
    }
}

final class TextEditingEvent : Event {
    this(uint windowID, string text, size_t start, size_t length)
    in {
        assert(text.length < 32);
    }
    do {
        this.sdlEvent.type = SDL_TEXTEDITING;
        this.sdlEvent.edit.windowID = windowID;
        this.sdlEvent.edit.text[0 .. text.length] = text[];
        this.sdlEvent.edit.start = start.to!int;
        this.sdlEvent.edit.length = length.to!int;
    }

    invariant {
        assert(this.sdlEvent.type == SDL_TEXTEDITING);
    }

    override string toString() const @trusted {
        return "dsdl2.TextEditingEvent(%d, %s, %d, %d)".format(this.windowID,
            [this.text].to!string[1 .. $ - 1], this.start, this.length);
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.edit.windowID;
    }

    string text() const @property @trusted {
        return this.sdlEvent.edit.text.ptr.to!string;
    }

    void text(string newText) @property
    in {
        assert(newText.length < 32);
    }
    do {
        this.sdlEvent.edit.text[0 .. newText.length] = newText[];
    }

    size_t start() const @property {
        return this.sdlEvent.edit.start.to!size_t;
    }

    void start(size_t newStart) @property {
        this.sdlEvent.edit.start = newStart.to!int;
    }

    size_t length() const @property {
        return this.sdlEvent.edit.length.to!size_t;
    }

    void length(size_t newLength) @property {
        this.sdlEvent.edit.length = newLength.to!int;
    }
}

final class TextInputEvent : Event {
    this(uint windowID, string text)
    in {
        assert(text.length < 32);
    }
    do {
        this.sdlEvent.type = SDL_TEXTINPUT;
        this.sdlEvent.edit.windowID = windowID;
        this.sdlEvent.edit.text[0 .. text.length] = text[];
    }

    invariant {
        assert(this.sdlEvent.type == SDL_TEXTINPUT);
    }

    override string toString() const @trusted {
        return "dsdl2.TextInputEvent(%d, %s)".format(this.windowID,
            [this.text].to!string[1 .. $ - 1]);
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.edit.windowID;
    }

    string text() const @property @trusted {
        return this.sdlEvent.edit.text.ptr.to!string;
    }

    void text(string newText) @property
    in {
        assert(newText.length < 32);
    }
    do {
        this.sdlEvent.edit.text[0 .. newText.length] = newText[];
    }
}

static if (sdlSupport >= SDLSupport.v2_0_4) {
    final class KeymapChangedEvent : Event {
        this() {
            this.sdlEvent.type = SDL_KEYMAPCHANGED;
        }

        invariant {
            assert(this.sdlEvent.type == SDL_KEYMAPCHANGED);
        }

        override string toString() const {
            return "dsdl2.KeymapChangedEvent()";
        }
    }
}

final class MouseMotionEvent : Event {
    this(uint windowID, uint which, MouseState state, int[2] xy, int[2] xyRel) {
        this.sdlEvent.type = SDL_MOUSEMOTION;
        this.sdlEvent.motion.windowID = windowID;
        this.sdlEvent.motion.which = which;
        this.sdlEvent.motion.state = state.sdlMouseState;
        this.sdlEvent.motion.x = xy[0];
        this.sdlEvent.motion.y = xy[1];
        this.sdlEvent.motion.xrel = xyRel[0];
        this.sdlEvent.motion.yrel = xyRel[1];
    }

    invariant {
        assert(this.sdlEvent.type == SDL_MOUSEMOTION);
    }

    override string toString() const {
        return "dsdl2.MouseMotionEvent(%d, %d, %s, %s, %s)".format(this.windowID, this.which,
            this.state, this.xy, this.xyRel);
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.motion.windowID;
    }

    ref inout(uint) which() return inout @property {
        return this.sdlEvent.motion.which;
    }

    MouseState state() const @property {
        return MouseState(this.sdlEvent.motion.state);
    }

    void state(MouseState newState) @property {
        this.sdlEvent.motion.state = newState.sdlMouseState;
    }

    ref inout(int) x() return inout @property {
        return this.sdlEvent.motion.x;
    }

    ref inout(int) y() return inout @property {
        return this.sdlEvent.motion.y;
    }

    int[2] xy() const @property {
        return [this.sdlEvent.motion.x, this.sdlEvent.motion.y];
    }

    void xy(int[2] newXY) @property {
        this.sdlEvent.motion.x = newXY[0];
        this.sdlEvent.motion.y = newXY[1];
    }

    ref inout(int) xRel() return inout @property {
        return this.sdlEvent.motion.xrel;
    }

    ref inout(int) yRel() return inout @property {
        return this.sdlEvent.motion.yrel;
    }

    int[2] xyRel() const @property {
        return [this.sdlEvent.motion.xrel, this.sdlEvent.motion.yrel];
    }

    void xyRel(int[2] newXYRel) @property {
        this.sdlEvent.motion.xrel = newXYRel[0];
        this.sdlEvent.motion.yrel = newXYRel[1];
    }
}

abstract class MouseButtonEvent : Event {
    invariant {
        assert(this.sdlEvent.type == SDL_MOUSEBUTTONDOWN || this.sdlEvent.type == SDL_MOUSEBUTTONUP);
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.button.windowID;
    }

    ref inout(uint) which() return inout @property {
        return this.sdlEvent.button.which;
    }

    MouseButton button() const @property {
        return cast(MouseButton) this.sdlEvent.button.button;
    }

    void button(MouseButton newButton) @property {
        this.sdlEvent.button.button = cast(ubyte) newButton;
    }

    ref inout(ubyte) clicks() return inout @property {
        static if (sdlSupport >= SDLSupport.v2_0_2) {
            return this.sdlEvent.button.clicks;
        }
        else {
            return this.sdlEvent.button.padding1;
        }
    }

    ref inout(int) x() return inout @property {
        return this.sdlEvent.button.x;
    }

    ref inout(int) y() return inout @property {
        return this.sdlEvent.button.y;
    }

    int[2] xy() const @property {
        return [this.sdlEvent.button.x, this.sdlEvent.button.y];
    }

    void xy(int[2] newXY) @property {
        this.sdlEvent.button.x = newXY[0];
        this.sdlEvent.button.y = newXY[1];
    }

    static Event fromSDL(SDL_Event sdlEvent)
    in {
        assert(sdlEvent.type == SDL_MOUSEBUTTONDOWN || sdlEvent.type == SDL_MOUSEBUTTONUP);
    }
    do {
        switch (sdlEvent.type) {
        default:
            assert(false);

        case SDL_MOUSEBUTTONDOWN:
            static if (sdlSupport >= SDLSupport.v2_0_2) {
                return new MouseButtonDownEvent(sdlEvent.button.windowID, sdlEvent.button.which,
                    cast(MouseButton) sdlEvent.button.button, sdlEvent.button.clicks,
                    [sdlEvent.button.x, sdlEvent.button.y]);
            }
            else {
                return new MouseButtonDownEvent(sdlEvent.button.windowID, sdlEvent.button.which,
                    cast(MouseButton) sdlEvent.button.button, 1,
                    [sdlEvent.button.x, sdlEvent.button.y]);
            }

        case SDL_MOUSEBUTTONUP:
            static if (sdlSupport >= SDLSupport.v2_0_2) {
                return new MouseButtonUpEvent(sdlEvent.button.windowID, sdlEvent.button.which,
                    cast(MouseButton) sdlEvent.button.button, sdlEvent.button.clicks,
                    [sdlEvent.button.x, sdlEvent.button.y]);
            }
            else {
                return new MouseButtonUpEvent(sdlEvent.button.windowID, sdlEvent.button.which,
                    cast(MouseButton) sdlEvent.button.button, 1,
                    [sdlEvent.button.x, sdlEvent.button.y]);
            }
        }
    }
}

final class MouseButtonDownEvent : MouseButtonEvent {
    this(uint windowID, uint which, MouseButton button, ubyte clicks, int[2] xy) {
        this.sdlEvent.type = SDL_MOUSEBUTTONDOWN;
        this.sdlEvent.button.windowID = windowID;
        this.sdlEvent.button.which = which;
        this.sdlEvent.button.button = button;
        this.sdlEvent.button.state = SDL_PRESSED;
        static if (sdlSupport >= SDLSupport.v2_0_2) {
            this.sdlEvent.button.clicks = clicks;
        }
        else {
            this.sdlEvent.button.padding1 = clicks;
        }
        this.sdlEvent.button.x = xy[0];
        this.sdlEvent.button.y = xy[1];
    }

    invariant {
        assert(this.sdlEvent.type == SDL_MOUSEBUTTONDOWN);
        assert(this.sdlEvent.button.state == SDL_PRESSED);
    }

    override string toString() const {
        return "dsdl2.MouseButtonDownEvent(%d, %d, %s, %d, %s)".format(this.windowID,
            this.which, this.button, this.clicks, this.xy);
    }
}

final class MouseButtonUpEvent : MouseButtonEvent {
    this(uint windowID, uint which, MouseButton button, ubyte clicks, int[2] xy) {
        this.sdlEvent.type = SDL_MOUSEBUTTONDOWN;
        this.sdlEvent.button.windowID = windowID;
        this.sdlEvent.button.which = which;
        this.sdlEvent.button.button = button;
        this.sdlEvent.button.state = SDL_RELEASED;
        static if (sdlSupport >= SDLSupport.v2_0_2) {
            this.sdlEvent.button.clicks = clicks;
        }
        else {
            this.sdlEvent.button.padding1 = clicks;
        }
        this.sdlEvent.button.x = xy[0];
        this.sdlEvent.button.y = xy[1];
    }

    invariant {
        assert(this.sdlEvent.type == SDL_MOUSEBUTTONDOWN);
        assert(this.sdlEvent.button.state == SDL_RELEASED);
    }

    override string toString() const {
        return "dsdl2.MouseButtonUpEvent(%d, %d, %s, %d, %s)".format(this.windowID,
            this.which, this.button, this.clicks, this.xy);
    }
}

final class MouseWheelEvent : Event {
    static if (sdlSupport >= SDLSupport.v2_0_18) {
        this(uint windowID, uint which, int[2] xy, MouseWheel direction = MouseWheel.normal,
            float[2] preciseXY = [0.0, 0.0]) {
            this.sdlEvent.type = SDL_MOUSEWHEEL;
            this.sdlEvent.wheel.windowID = windowID;
            this.sdlEvent.wheel.which = which;
            this.sdlEvent.wheel.x = xy[0];
            this.sdlEvent.wheel.y = xy[1];
            this.sdlEvent.wheel.direction = cast(uint) direction;
            this.sdlEvent.wheel.preciseX = preciseXY[0];
            this.sdlEvent.wheel.preciseY = preciseXY[1];
        }
    }
    else static if (sdlSupport >= SDLSupport.v2_0_4) {
        this(uint windowID, uint which, int[2] xy, MouseWheel direction = MouseWheel.normal) {
            this.sdlEvent.type = SDL_MOUSEWHEEL;
            this.sdlEvent.wheel.windowID = windowID;
            this.sdlEvent.wheel.which = which;
            this.sdlEvent.wheel.x = xy[0];
            this.sdlEvent.wheel.y = xy[1];
            this.sdlEvent.wheel.direction = cast(uint) direction;
        }
    }
    else {
        this(uint windowID, uint which, int[2] xy) {
            this.sdlEvent.type = SDL_MOUSEWHEEL;
            this.sdlEvent.wheel.windowID = windowID;
            this.sdlEvent.wheel.which = which;
            this.sdlEvent.wheel.x = xy[0];
            this.sdlEvent.wheel.y = xy[1];
        }
    }

    invariant {
        assert(this.sdlEvent.type == SDL_MOUSEWHEEL);
    }

    ref inout(uint) windowID() return inout @property {
        return this.sdlEvent.wheel.windowID;
    }

    override string toString() const {
        static if (sdlSupport >= SDLSupport.v2_0_18) {
            return "dsdl2.MouseWheelEvent(%d, %d, %s, %s, %s)".format(this.windowID, this.which,
                this.xy, this.direction, this.preciseXY);
        }
        else static if (sdlSupport >= SDLSupport.v2_0_4) {
            return "dsdl2.MouseWheelEvent(%d, %d, %s, %s)".format(this.windowID, this.which, this.xy,
                this.direction);
        }
        else {
            return "dsdl2.MouseWheelEvent(%d, %d, %s)".format(this.windowID, this.which, this.xy);
        }
    }

    ref inout(uint) which() return inout @property {
        return this.sdlEvent.wheel.which;
    }

    ref inout(int) x() return inout @property {
        return this.sdlEvent.wheel.x;
    }

    ref inout(int) y() return inout @property {
        return this.sdlEvent.wheel.y;
    }

    int[2] xy() const @property {
        return [this.sdlEvent.wheel.x, this.sdlEvent.wheel.y];
    }

    void xy(int[2] newXY) @property {
        this.sdlEvent.wheel.x = newXY[0];
        this.sdlEvent.wheel.y = newXY[1];
    }

    static if (sdlSupport >= SDLSupport.v2_0_4) {
        MouseWheel direction() const @property {
            return cast(MouseWheel) this.sdlEvent.wheel.direction;
        }

        void direction(MouseWheel newDirection) @property {
            this.sdlEvent.wheel.direction = cast(uint) newDirection;
        }
    }

    static if (sdlSupport >= SDLSupport.v2_0_18) {
        ref inout(float) preciseX() return inout @property {
            return this.sdlEvent.wheel.preciseX;
        }

        ref inout(float) preciseY() return inout @property {
            return this.sdlEvent.wheel.preciseY;
        }

        float[2] preciseXY() const @property {
            return [this.sdlEvent.wheel.preciseX, this.sdlEvent.wheel.preciseY];
        }

        void preciseXY(float[2] newXY) @property {
            this.sdlEvent.wheel.preciseX = newXY[0];
            this.sdlEvent.wheel.preciseY = newXY[1];
        }
    }
}
