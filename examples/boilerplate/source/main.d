@safe:

import std.stdio;
static import dsdl2;

void main() {
    dsdl2.loadSO();
    dsdl2.init();
    writeln("Version of SDL used: ", dsdl2.getVersion());

    auto surf = new dsdl2.Surface([800, 600], dsdl2.PixelFormat.rgb24);

    ubyte[] arr = [0b00001111, 0b11110000];
    auto pal = new dsdl2.Palette([dsdl2.Color(1, 1, 1), dsdl2.Color(2, 2, 2)]);
    auto yess = new dsdl2.Surface(arr, [8, 2], 1, 1, pal);

    writeln(yess.getAt([0, 0]));
    writeln(yess.getAt([7, 0]));
    writeln(yess.getAt([0, 1]));
    writeln(yess.getAt([7, 1]));

    auto surface = new dsdl2.Surface([100, 100], dsdl2.PixelFormat.rgba32);
    surface.fill(dsdl2.Color(24, 24, 24));
    surface.fillRect(dsdl2.Rect(25, 25, 50, 50), dsdl2.Color(42, 42, 42));

    writeln(surface.getAt([0, 0]));
    writeln(surface.getAt([50, 50]));

    dsdl2.quit();
}
