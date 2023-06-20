@safe:

import std.stdio;
static import dsdl2;

void main() {
    dsdl2.loadSO();
    dsdl2.init();
    writeln("Version of SDL used: ", dsdl2.getVersion());

    auto surf = new dsdl2.Surface([800, 600], dsdl2.PixelFormat.rgb24);

    ubyte[] arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    auto yess = new dsdl2.Surface(arr, [2, 2], 8, dsdl2.PixelFormat.rgba32);

    writeln(yess.getAt([1, 1]));
    yess.setAt([1, 1], dsdl2.Color(42, 69, 42, 69));
    writeln(yess.getAt([1, 1]));

    dsdl2.quit();
}
