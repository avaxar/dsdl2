@safe:

import std.stdio;
static import dsdl2;

void main() {
    dsdl2.loadSO();
    dsdl2.init();
    writeln("Version of SDL used: ", dsdl2.getVersion());

    dsdl2.Window window = new dsdl2.Window("bruh", [
        dsdl2.WindowPos.centered, dsdl2.WindowPos.centered
    ], [800, 600]);
    window.surface.fill(dsdl2.Color(255, 0, 0));
    window.update();

    while (true) {
    }

    // dsdl2.quit();
}
