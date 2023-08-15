@safe:

import std.stdio;
static import dsdl2;

int main() {
    dsdl2.loadSO();
    dsdl2.init();

    writeln("Version of SDL used: ", dsdl2.getVersion());
    writeln("List of drivers: ", dsdl2.getVideoDrivers());
    writeln("Used driver: ", dsdl2.getCurrentVideoDriver());

    auto window = new dsdl2.Window("My Window", [
        dsdl2.WindowPos.centered, dsdl2.WindowPos.centered
    ], [800, 600]);

    auto surface = new dsdl2.Surface([128, 128], window.surface.pixelFormat);
    surface.fill(dsdl2.Color(255, 0, 0));

    while (true) {
        while (auto event = dsdl2.pollEvent()) {
            if (cast(dsdl2.QuitEvent) event) {
                dsdl2.quit();
                return 0;
            }
        }

        ubyte val = cast(ubyte) dsdl2.getTicks();
        window.surface.fill(dsdl2.Color(val, val, val));
        if (window.mouseFocused) {
            window.surface.blit(dsdl2.Point(window.mousePosition), surface);
        }

        window.update();
    }
}
