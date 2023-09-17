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

    // Creates a simple 800x600 window in the center of the screen, as well as its associated GPU renderer
    auto window = new dsdl2.Window("My Window", [dsdl2.WindowPos.centered, dsdl2.WindowPos.centered], [800, 600]);
    auto renderer = new dsdl2.Renderer(window, flags:
        [dsdl2.RendererFlag.accelerated, dsdl2.RendererFlag.presentVSync]);

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

        // Clears the screen with white
        renderer.drawColor = dsdl2.Color(255, 255, 255);
        renderer.clear();

        // Draws a filled red box at the center of the screen
        renderer.drawColor = dsdl2.Color(255, 0, 0);
        renderer.fillRect(dsdl2.Rect(350, 250, 100, 100));

        renderer.present();
    }

    // Quits SDL
    dsdl2.quit();
}
