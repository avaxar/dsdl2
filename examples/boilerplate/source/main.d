@safe:

import std.stdio;
static import dsdl2;

void main() {
    // SDL initialization
    dsdl2.loadSO();
    dsdl2.init();

    // Prints backend information
    writeln("Version of SDL used: ", dsdl2.getVersion());
    writeln("List of drivers: ", dsdl2.getVideoDrivers());
    writeln("Used driver: ", dsdl2.getCurrentVideoDriver());

    // Creates a simple 800x600 window in the center of the screen
    auto window = new dsdl2.Window("My Window", [dsdl2.WindowPos.centered, dsdl2.WindowPos.centered], [800, 600]);

    // The application loop
    bool running = true;
    while (running) {
        // Gets incoming events
        while (auto event = dsdl2.pollEvent()) {
            // On quit
            if (cast(dsdl2.QuitEvent) event) {
                running = false;
            }
        }

        // Fills the screen with white
        window.surface.fill(dsdl2.Color(255, 255, 255));
        window.update();
    }

    // Quits SDL
    dsdl2.quit();
}
