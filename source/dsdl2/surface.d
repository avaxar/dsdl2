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

final class Surface {
    SDL_Surface* _sdlSurface = null;

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
