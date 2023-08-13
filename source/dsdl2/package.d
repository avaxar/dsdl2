/++
 + An object-oriented wrapper for SDL2 in the D programming language utilizing high level programming constructs,
 + accompanied with the $(LINK2 https://code.dlang.org/packages/bindbc-sdl, bindbc-sdl) binding.
 +
 + Use:
 + The recommended way of using this library in your project is to add it to your dub project. dsdl2 has been
 + published in the $(LINK2 https://code.dlang.org/packages/dsdl2, dub package registry). A simple `dub add dsdl2`
 + would do.
 +
 + Development:
 + This library is actively maintained over on its $(LINK2 https://github.com/avaxar/dsdl2, GitHub repository).
 + Voluntary contributions in improving and fixing the library are welcome.
 +
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2;

public:
import dsdl2.blend;
import dsdl2.clipboard;
import dsdl2.display;
import dsdl2.pixels;
import dsdl2.rect;
import dsdl2.renderer;
import dsdl2.sdl;
import dsdl2.surface;
import dsdl2.video;
import dsdl2.window;
