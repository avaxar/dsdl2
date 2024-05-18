/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.rect;
@safe:

import bindbc.sdl;
import dsdl2.sdl;
import dsdl2.frect;

import std.conv : to;
import std.format : format;
import std.typecons : Nullable, nullable;

/++
 + D struct that wraps `SDL_Point` containing 2D integer coordinate pair
 +
 + `dsdl2.Point` stores signed `int`eger `x` and `y` coordinate points. This wrapper also implements vector-like
 + operator overloading.
 +/
struct Point {
    SDL_Point sdlPoint; /// Internal `SDL_Point` struct

    this() @disable;

    /++
     + Constructs a `dsdl2.Point` from a vanilla `SDL_Point` from bindbc-sdl
     +
     + Params:
     +   sdlPoint = the `dsdl2.Point` struct
     +/
    this(SDL_Point sdlPoint) {
        this.sdlPoint = sdlPoint;
    }

    /++
     + Constructs a `dsdl2.Point` by feeding in an `x` and `y` pair
     +
     + Params:
     +   x = x coordinate point
     +   y = y coordinate point
     +/
    this(int x, int y) {
        this.sdlPoint.x = x;
        this.sdlPoint.y = y;
    }

    /++
     + Constructs a `dsdl2.Point` by feeding in an array of `x` and `y`
     +
     + Params:
     +   xy = x and y coordinate point array
     +/
    this(int[2] xy) {
        this.sdlPoint.x = xy[0];
        this.sdlPoint.y = xy[1];
    }

    static if (sdlSupport >= SDLSupport.v2_0_10) {
        /++
         + Constructs a `dsdl2.Point` from a `dsdl2.FPoint` (from SDL 2.0.10)
         +
         + Params:
         +   fpoint = `dsdl2.FPoint` whose attributes are to be copied
         +/
        this(FPoint fpoint) {
            this.sdlPoint.x = fpoint.x.to!int;
            this.sdlPoint.y = fpoint.y.to!int;
        }
    }

    /++
     + Unary element-wise operation overload template
     +/
    Point opUnary(string op)() const {
        return Point(mixin(op ~ "this.x"), mixin(op ~ "this.y"));
    }

    /++
     + Binary element-wise operation overload template
     +/
    Point opBinary(string op)(const Point other) const {
        return Point(mixin("this.x" ~ op ~ "other.x"), mixin("this.y" ~ op ~ "other.y"));
    }

    /++
     + Binary operation overload template with scalars
     +/
    Point opBinary(string op)(int scalar) const if (op == "*" || op == "/") {
        return Point(mixin("this.x" ~ op ~ "scalar"), mixin("this.y" ~ op ~ "scalar"));
    }

    /++
     + Element-wise operator assignment overload
     +/
    ref inout(Point) opOpAssign(string op)(const Point other) return inout {
        mixin("this.x" ~ op ~ "=other.x");
        mixin("this.y" ~ op ~ "=other.y");
        return this;
    }

    /++
     + Operator assignment overload with scalars
     +/
    ref inout(Point) opOpAssign(string op)(const int scalar) return inout if (op == "*" || op == "/") {
        mixin("this.x" ~ op ~ "=scalar");
        mixin("this.y" ~ op ~ "=scalar");
        return this;
    }

    /++
     + Formats the `dsdl2.Point` into its construction representation: `"dsdl2.Point(<x>, <y>)"`
     +
     + Returns: the formatted `string`
     +/
    string toString() const {
        return "dsdl2.Point(%d, %d)".format(this.x, this.y);
    }

    /++
     + Proxy to the X value of the `dsdl2.Point`
     +
     + Returns: X value of the `dsdl2.Point`
     +/
    ref inout(int) x() return inout @property {
        return this.sdlPoint.x;
    }

    /++
     + Proxy to the Y value of the `dsdl2.Point`
     +
     + Returns: Y value of the `dsdl2.Point`
     +/
    ref inout(int) y() return inout @property {
        return this.sdlPoint.y;
    }

    /++
     + Static array proxy of the `dsdl2.Point`
     +
     + Returns: array of `x` and `y`
     +/
    ref inout(int[2]) array() return inout @property @trusted {
        return *cast(inout(int[2]*))&this.sdlPoint;
    }
}
///
unittest {
    auto a = dsdl2.Point(1, 2);
    auto b = a + a;
    assert(b == dsdl2.Point(2, 4));

    auto c = a * 2;
    assert(b == c);
}

/++
 + D struct that wraps `SDL_Rect` representing a rectangle of integer 2D coordinate and dimension
 +
 + `dsdl2.Rect` stores signed `int`eger `x` and `y` coordinate points, as well as `w`idth and `h`eight which
 + specifies the rectangle's dimension. `x` and `y` symbolize the top-left coordinate of the rectangle, and
 + the `w`idth and `h`eight extend to the positive plane of both axes.
 +/
struct Rect {
    SDL_Rect sdlRect; /// Internal `SDL_Rect` struct

    this() @disable;

    /++
     + Constructs a `dsdl2.Rect` from a vanilla `SDL_Rect` from bindbc-sdl
     +
     + Params:
     +   sdlRect = the `SDL_Rect` struct
     +/
    this(SDL_Rect sdlRect) {
        this.sdlRect = sdlRect;
    }

    /++
     + Constructs a `dsdl2.Rect` by feeding in the `x`, `y`, `width`, and `height` of the rectangle
     +
     + Params:
     +   x = top-left x coordinate point of the rectangle
     +   y = top-left y coordinate point of the rectangle
     +   width = rectangle width
     +   height = rectangle height
     +/
    this(int x, int y, int width, int height) {
        this.sdlRect.x = x;
        this.sdlRect.y = y;
        this.sdlRect.w = width;
        this.sdlRect.h = height;
    }

    /++
     + Constructs a `dsdl2.Rect` by feeding in a `dsdl2.Point` as the `x` and `y`, then `width` and `height` of the
     + rectangle
     +
     + Params:
     +   point = top-left point of the rectangle
     +   width = rectangle width
     +   height = rectangle height
     +/
    this(Point point, int width, int height) {
        this.sdlRect.x = point.x;
        this.sdlRect.y = point.y;
        this.sdlRect.w = width;
        this.sdlRect.h = height;
    }

    static if (sdlSupport >= SDLSupport.v2_0_10) {
        /++
         + Constructs a `dsdl2.Rect` from a `dsdl2.FRect` (from SDL 2.0.10)
         +
         + Params:
         +   frect = `dsdl2.FRect` whose attributes are to be copied
         +/
        this(FRect frect) {
            this.sdlRect.x = frect.x.to!int;
            this.sdlRect.y = frect.y.to!int;
            this.sdlRect.w = frect.width.to!int;
            this.sdlRect.h = frect.height.to!int;
        }
    }

    /++
     + Binary operation overload template to move rectangle's position by an `offset` as a `dsdl2.Point`
     +/
    Rect opBinary(string op)(const Point offset) const if (op == "+" || op == "-") {
        return Rect(Point(mixin("this.x" ~ op ~ "offset.x"), mixin("this.y" ~ op ~ "offset.y")), this.w, this.h);
    }

    /++
     + Operator assignment overload template to move rectangle's position in-place by an `offset` as a `dsdl2.Point`
     +/
    ref inout(Point) opOpAssign(string op)(const Point offset) return inout if (op == "+" || op == "-") {
        mixin("this.x" ~ op ~ "=offset.x");
        mixin("this.y" ~ op ~ "=offset.y");
        return this;
    }

    /++
     + Formats the `dsdl2.Rect` into its construction representation: `"dsdl2.Rect(<x>, <y>, <w>, <h>)"`
     +
     + Returns: the formatted `string`
     +/
    string toString() const {
        return "dsdl2.Rect(%d, %d, %d, %d)".format(this.x, this.y, this.width, this.height);
    }

    /++
     + Proxy to the X value of the `dsdl2.Rect`
     +
     + Returns: X value of the `dsdl2.Rect`
     +/
    ref inout(int) x() return inout @property {
        return this.sdlRect.x;
    }

    /++
     + Proxy to the Y value of the `dsdl2.Rect`
     +
     + Returns: Y value of the `dsdl2.Rect`
     +/
    ref inout(int) y() return inout @property {
        return this.sdlRect.y;
    }

    /++
     + Proxy to the `dsdl2.Point` containing the `x` and `y` value of the `dsdl2.Rect`
     +
     + Returns: reference to the `dsdl2.Point` structure
     +/
    ref inout(Point) point() return inout @property @trusted {
        return *cast(inout(Point*))&this.sdlRect.x;
    }

    /++
     + Proxy to the width of the `dsdl2.Rect`
     +
     + Returns: width of the `dsdl2.Rect`
     +/
    ref inout(int) width() return inout @property {
        return this.sdlRect.w;
    }

    /++
     + Proxy to the height of the `dsdl2.Rect`
     +
     + Returns: height of the `dsdl2.Rect`
     +/
    ref inout(int) height() return inout @property {
        return this.sdlRect.h;
    }

    /++
     + Proxy to the size array containing the `width` and `height` of the `dsdl2.Rect`
     +
     + Returns: reference to the static `int[2]` array
     +/
    ref inout(int[2]) size() return inout @property @trusted {
        return *cast(inout(int[2]*))&this.sdlRect.w;
    }

    /++
     + Wraps `SDL_RectEmpty` which checks if the `dsdl2.Rect` is an empty rectangle
     +
     + Returns: `true` if it is empty, otherwise `false`
     +/
    bool empty() const @trusted {
        return SDL_RectEmpty(&this.sdlRect);
    }

    /++
     + Wraps `SDL_PointInRect` which sees whether the coordinate of a `dsdl2.Point` is inside the `dsdl2.Rect`
     +
     + Params:
     +   point = the `dsdl2.Point` to check its collision of with the `dsdl2.Rect` instance
     + Returns: `true` if it is within, otherwise `false`
     +/
    bool pointInRect(Point point) const @trusted {
        return SDL_PointInRect(&point.sdlPoint, &this.sdlRect);
    }

    /++
     + Wraps `SDL_HasIntersection` which sees whether two `dsdl2.Rect`s intersect each other
     +
     + Params:
     +   other = other `dsdl2.Rect` to check its intersection of with the `dsdl2.Rect`
     + Returns: `true` if both have intersection with each other, otherwise `false`
     +/
    bool hasIntersection(Rect other) const @trusted {
        return SDL_HasIntersection(&this.sdlRect, &other.sdlRect) == SDL_TRUE;
    }

    /++
     + Wraps `SDL_IntersectRectAndLine` which sees whether a line intersects with the `dsdl2.Rect`
     +
     + Params:
     +   line = set of two `dsdl2.Point`s denoting the start and end coordinates of the line to check its intersection
     +          of with the `dsdl2.Rect`
     + Returns: `true` if it intersects, otherwise `false`
     +/
    bool hasLineIntersection(Point[2] line) const @trusted {
        return SDL_IntersectRectAndLine(&this.sdlRect, &line[0].sdlPoint.x, &line[0].sdlPoint.y,
                &line[1].sdlPoint.x, &line[1].sdlPoint.y) == SDL_TRUE;
    }

    /++
     + Wraps `SDL_IntersectRect` which attempts to get the rectangle of intersection between two `dsdl2.Rect`s
     +
     + Params:
     +   other = other `dsdl2.Rect` with which the `dsdl2.Rect` is intersected
     + Returns: non-null `Nullable!Rect` instance if intersection is present, otherwise a null one
     +/
    Nullable!Rect intersectRect(Rect other) const @trusted {
        Rect intersection = void;
        if (SDL_IntersectRect(&this.sdlRect, &other.sdlRect, &intersection.sdlRect) == SDL_TRUE) {
            return intersection.nullable;
        }
        else {
            return Nullable!Rect.init;
        }
    }

    /++
     + Wraps `SDL_IntersectRectAndLine` which attempts to clip a line segment in the boundaries of the `dsdl2.Rect`
     +
     + Params:
     +   line = set of two `dsdl2.Point`s denoting the start and end coordinates of the line to clip from
     +          its intersection with the `dsdl2.Rect`
     + Returns: non-null `Nullable!(Point[2])` as the clipped line if there is an intersection, otherwise a null one
     +/
    Nullable!(Point[2]) intersectLine(Point[2] line) const @trusted {
        if (SDL_IntersectRectAndLine(&this.sdlRect, &line[0].sdlPoint.x, &line[0].sdlPoint.y,
                &line[1].sdlPoint.x, &line[1].sdlPoint.y) == SDL_TRUE) {
            Point[2] intersection = [line[0], line[1]];
            return intersection.nullable;
        }
        else {
            return Nullable!(Point[2]).init;
        }
    }

    /++
     + Wraps `SDL_UnionRect` which creates a `dsdl2.Rect` of the minimum size to enclose two given `dsdl2.Rect`s
     +
     + Params:
     +   other = other `dsdl2.Rect` to unify with the `dsdl2.Rect`
     + Returns: `dsdl2.Rect` of the minimum size to enclose the `dsdl2.Rect` and `other`
     +/
    Rect unify(Rect other) const @trusted {
        Rect union_ = void;
        SDL_UnionRect(&this.sdlRect, &other.sdlRect, &union_.sdlRect);
        return union_;
    }
}
///
unittest {
    auto rect1 = dsdl2.Rect(-2, -2, 3, 3);
    auto rect2 = dsdl2.Rect(-1, -1, 3, 3);

    assert(rect1.hasIntersection(rect2));
    assert(rect1.intersectRect(rect2).get == dsdl2.Rect(-1, -1, 2, 2));
}
