/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org/, MIT License)
 +/

module dsdl2.surface;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.pixels;
import dsdl2.rect;

/++ 
 + A D class that wraps `SDL_Surface` storing a 2D image in pixels with a `width` and `height`, each pixel stored
 + in the RAM according to a certain `dsdl2.PixelFormat`.
 +/
final class Surface {
    private PixelFormat pixelFormatRef = null;
    @system SDL_Surface* _sdlSurface = null;

    /++ 
     + Constructs a `dsdl2.Surface` from a vanilla `SDL_Surface*` from bindbc-sdl
     + 
     + Params:
     +   sdlSurface = the `SDL_Surface` pointer to manage
     +/
    this(SDL_Surface* sdlSurface) @system
    in {
        assert(sdlSurface !is null);
    }
    do {
        this._sdlSurface = sdlSurface;
    }

    ~this() @trusted {
        SDL_FreeSurface(this._sdlSurface);
    }

    @trusted invariant {
        assert(this._sdlSurface !is null);
    }
}
