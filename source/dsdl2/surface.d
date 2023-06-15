/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org/, MIT License)
 +/

module dsdl2.surface;

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.pixel;
import dsdl2.rect;

/++ 
 + A D class that wraps `SDL_Surface` storing a 2D image in pixels with a `width` and `height`, each pixel stored
 + in the RAM according to a certain `dsdl2.PixelFormat`.
 +/
final class Surface {
    SDL_Surface* _sdlSurface = null;

    /++ 
     + Constructs a `dsdl2.Surface` from a vanilla `SDL_Surface*` from bindbc-sdl
     + 
     + Params:
     +   sdlSurface = the `SDL_Surface` pointer to manage
     +/
    this(SDL_Surface* sdlSurface)
    in {
        assert(sdlSurface !is null);
    }
    do {
        this._sdlSurface = sdlSurface;
    }

    ~this() {
        SDL_FreeSurface(this._sdlSurface);
    }

    invariant {
        assert(this._sdlSurface !is null);
    }
}
