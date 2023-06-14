import std.stdio;
static import dsdl2;

void main() {
	dsdl2.loadSO();
    dsdl2.init();
    writeln("Version of SDL used: ", dsdl2.getVersion());

    auto a = dsdl2.FPoint(1.0, 2.0);
    auto b = a + a;
    assert(b == dsdl2.FPoint(2.0, 4.0));

    auto c = a * 2.0;
    assert(b == c);

    auto rect1 = dsdl2.FRect(-2.0, -2.0, 3.0, 3.0);
    auto rect2 = dsdl2.FRect(-1.0, -1.0, 3.0, 3.0);

    assert(rect1.collide(rect2));
    assert(rect1.intersect(rect2).get == dsdl2.FRect(-1.0, -1.0, 2.0, 2.0));

    dsdl2.quit();
}

