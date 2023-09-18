@safe:

import std.stdio;
import std.math;
import std.random;

static import dsdl2;

void main() {
    dsdl2.loadSO();
    dsdl2.init();

    auto window = new dsdl2.Window("Pong", [
        dsdl2.WindowPos.undefined, dsdl2.WindowPos.undefined
    ], [800, 600]);

    auto rand = Random(unpredictableSeed());

    float playerSpeed = 300.0;
    auto playerA = dsdl2.FRect(10, 250, 10, 100);
    auto playerB = dsdl2.FRect(780, 250, 10, 100);

    float ballSpeed = 300.0;
    float ballDirection = uniform(-PI, PI, rand);
    auto ball = dsdl2.FRect(390, 290, 20, 20);

    bool running = true;
    float lastTick = dsdl2.getTicks() / 1000.0;
    float deltaTime = 0.0;

    // Game loop
    while (running) {
        dsdl2.pumpEvents();
        while (auto event = dsdl2.pollEvent()) {
            if (cast(dsdl2.QuitEvent) event) {
                running = false;
                break;
            }
        }

        // Updates movement from the keyboard
        auto keys = dsdl2.getKeyboardState();
        // W and S for player A
        if (keys[dsdl2.Scancode.w]) {
            playerA.y -= playerSpeed * deltaTime;
        }
        if (keys[dsdl2.Scancode.s]) {
            playerA.y += playerSpeed * deltaTime;
        }
        // Up and down arrows for player B
        if (keys[dsdl2.Scancode.up]) {
            playerB.y -= playerSpeed * deltaTime;
        }
        if (keys[dsdl2.Scancode.down]) {
            playerB.y += playerSpeed * deltaTime;
        }

        // Updates the ball's movement from its direction
        ball.x += sin(ballDirection) * ballSpeed * deltaTime;
        ball.y -= cos(ballDirection) * ballSpeed * deltaTime;

        // Clamps both players' positions to not be out of the screen
        if (playerA.y < 10) {
            playerA.y = 10;
        }
        if (playerA.y > window.height - playerA.height - 10) {
            playerA.y = window.height - playerA.height - 10;
        }
        if (playerB.y < 10) {
            playerB.y = 10;
        }
        if (playerB.y > window.height - playerB.height - 10) {
            playerB.y = window.height - playerB.height - 10;
        }

        // Bounces the ball from the walls
        if (ball.y < 0) {
            ball.y = 0;
            ballDirection = PI - ballDirection;
        }
        if (ball.y > window.height - ball.height) {
            ball.y = window.height - ball.height;
            ballDirection = PI - ballDirection;
        }

        // Bounds the ball from the paddles
        if (ball.hasIntersection(playerA)) {
            ballDirection = -ballDirection + uniform(-1.0, 1.0, rand); // Adds minor direction shift
            ball.x = playerA.x + playerA.width;
        }
        if (ball.hasIntersection(playerB)) {
            ballDirection = -ballDirection + uniform(-1.0, 1.0, rand);
            ball.x = playerB.x - ball.width;
        }

        // If the ball hits the left or right side of the screen, reset the game
        if (ball.x < 0 || ball.x + ball.width > window.width) {
            ball.point = dsdl2.FPoint((window.width - ball.width) / 2,
                (window.size[1] - ball.height) / 2);
            ballDirection = uniform(0.0, 2.0 * PI, rand);
        }

        // Clears the screen
        window.surface.fill(dsdl2.Color(0, 0, 0));

        // Draws both of the players' paddles and the ball
        window.surface.fillRect(dsdl2.Rect(playerA), dsdl2.Color(255, 0, 0)); // Player A -> Red
        window.surface.fillRect(dsdl2.Rect(playerB), dsdl2.Color(0, 0, 255)); // Player B -> Blue
        window.surface.fillRect(dsdl2.Rect(ball), dsdl2.Color(255, 255, 255)); // Ball -> White

        window.update();
        deltaTime = dsdl2.getTicks() / 1000.0 - lastTick;
        lastTick += deltaTime;
    }

    dsdl2.quit();
}
