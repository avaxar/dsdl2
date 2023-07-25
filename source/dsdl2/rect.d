/++
 + Authors: Avaxar <avaxar@nekkl.org>
 + Copyright: Copyright © 2023, Avaxar
 + License: $(LINK2 https://mit-license.org, MIT License)
 +/

module dsdl2.rect;
@safe:

import bindbc.sdl;
import dsdl2.sdl;

import std.format : format;
import std.typecons : Nullable, nullable;

/++
 + D struct that wraps `SDL_Point` containing 2D integer coordinate pair
 +
 + `dsdl2.Point` stores signed `int`eger `x` and `y` coordinate points. This wrapper also implements vector-like
 + operator overloading.
 +
 + Examples:
 + ---
 + auto a = dsdl2.Point(1, 2);
 + auto b = a + a;
 + assert(b == dsdl2.Point(2, 4));
 +
 + auto c = a * 2;
 + assert(b == c);
 + ---
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
    ref inout(Point) opOpAssign(string op)(const Point other) inout {
        mixin("this.x" ~ op ~ "=other.x");
        mixin("this.y" ~ op ~ "=other.y");
        return this;
    }

    /++
     + Operator assignment overload with scalars
     +/
    ref inout(Point) opOpAssign(string op)(const int scalar) inout
    if (op == "*" || op == "/") {
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
     + Gets the static array representation of the `dsdl2.Point`
     +
     + Returns: X and Y as an array
     +/
    int[2] array() const @property {
        return [this.sdlPoint.x, this.sdlPoint.y];
    }
}

/++
 + D struct that wraps `SDL_Rect` representing a rectangle of integer 2D coordinate and dimension
 +
 + `dsdl2.Rect` stores signed `int`eger `x` and `y` coordinate points, as well as `w`idth and `h`eight which
 + specifies the rectangle's dimension. `x` and `y` symbolize the top-left coordinate of the rectangle, and
 + the `w`idth and `h`eight extend to the positive plane of both axes.
 +
 + Examples:
 + ---
 + auto rect1 = dsdl2.Rect(-2, -2, 3, 3);
 + auto rect2 = dsdl2.Rect(-1, -1, 3, 3);
 +
 + assert(rect1.hasIntersection(rect2));
 + assert(rect1.intersectRect(rect2).get == dsdl2.Rect(-1, -1, 2, 2));
 + ---
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
     +   x      = top-left x coordinate point of the rectangle
     +   y      = top-left y coordinate point of the rectangle
     +   width  = rectangle width
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
     +   point  = top-left point of the rectangle
     +   width  = rectangle width
     +   height = rectangle height
     +/
    this(Point point, int width, int height) {
        this.sdlRect.x = point.x;
        this.sdlRect.y = point.y;
        this.sdlRect.w = width;
        this.sdlRect.h = height;
    }

    /++
     + Binary operation overload template to move rectangle's position by an `offset` as a `dsdl2.Point`
     +/
    Rect opBinary(string op)(const Point offset) const {
        return Rect(this.xy + offset, this.w, this.h);
    }

    /++
     + Operator assignment overload template to move rectangle's position in-place by an `offset` as a `dsdl2.Point`
     +/
    ref inout(Point) opOpAssign(string op)(const Point offset) inout {
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
     + Gets the `dsdl2.Point` representation for the X and Y of the `dsdl2.Rect`
     +
     + Returns: `dsdl2.Point` with X and Y of the `dsdl2.Rect`
     +/
    Point point() const @property {
        return Point(this.sdlRect.x, this.sdlRect.y);
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
     + Gets the static array representation of the width and height of the `dsdl2.Rect`
     +
     + Returns: width and height as an array
     +/
    int[2] size() const @property {
        return [this.sdlRect.w, this.sdlRect.h];
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
     +   line = set of two `dsdl2.Point`s denoting the start and end coordinates of the line to check its
     +          intersection of with the `dsdl2.Rect`
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

static if (sdlSupport >= SDLSupport.v2_0_10) {
    /++
     + D struct that wraps `SDL_FPoint` (from SDL 2.0.10) containing 2D floating point coordinate pair
     +
     + `dsdl2.FPoint` stores `float`ing point `x` and `y` coordinate points. This wrapper also implements
     + vector-like operator overloading.
     +
     + Examples:
     + ---
     + auto a = dsdl2.FPoint(1.0, 2.0);
     + auto b = a + a;
     + assert(b == dsdl2.FPoint(2.0, 4.0));
     +
     + auto c = a * 2.0;
     + assert(b == c);
     + ---
     +/
    struct FPoint {
        SDL_FPoint sdlFPoint; /// Internal `SDL_FPoint` struct

        this() @disable;

        /++
         + Constructs a `dsdl2.FPoint` from a vanilla `SDL_FPoint` from bindbc-sdl
         +
         + Params:
         +   sdlFPoint = the `dsdl2.FPoint` struct
         +/
        this(SDL_FPoint sdlFPoint) {
            this.sdlFPoint = sdlFPoint;
        }

        /++
         + Constructs a `dsdl2.FPoint` by feeding in an `x` and `y` pair
         +
         + Params:
         +     x = x coordinate point
         +     y = y coordinate point
         +/
        this(float x, float y) {
            this.x = x;
            this.y = y;
        }

        /++
         + Unary element-wise operation overload template
         +/
        FPoint opUnary(string op)() const {
            return FPoint(mixin(op ~ "this.x"), mixin(op ~ "this.y"));
        }

        /++
         + Binary element-wise operation overload template
         +/
        FPoint opBinary(string op)(const FPoint other) const {
            return FPoint(mixin("this.x" ~ op ~ "other.x"), mixin("this.y" ~ op ~ "other.y"));
        }

        /++
         + Binary operation overload template with scalars
         +/
        FPoint opBinary(string op)(float scalar) const if (op == "*" || op == "/") {
            return FPoint(mixin("this.x" ~ op ~ "scalar"), mixin("this.y" ~ op ~ "scalar"));
        }

        /++
         + Element-wise operator assignment overload
         +/
        ref inout(FPoint) opOpAssign(string op)(const FPoint other) inout {
            mixin("this.x" ~ op ~ "=other.x");
            mixin("this.y" ~ op ~ "=other.y");
            return this;
        }

        /++
         + Operator assignment overload with scalars
         +/
        ref inout(FPoint) opOpAssign(string op)(const float scalar) inout
        if (op == "*" || op == "/") {
            mixin("this.x" ~ op ~ "=scalar");
            mixin("this.y" ~ op ~ "=scalar");
            return this;
        }

        /++
         + Formats the `dsdl2.FPoint` into its construction representation: `"dsdl2.FPoint(<x>, <y>)"`
         +
         + Returns: the formatted `string`
         +/
        string toString() const {
            return "dsdl2.FPoint(%f, %f)".format(this.x, this.y);
        }

        /++
         + Proxy to the X value of the `dsdl2.FPoint`
         +
         + Returns: X value of the `dsdl2.Point`
         +/
        ref inout(float) x() return inout @property {
            return this.sdlFPoint.x;
        }

        /++
         + Proxy to the Y value of the `dsdl2.FPoint`
         +
         + Returns: Y value of the `dsdl2.Point`
         +/
        ref inout(float) y() return inout @property {
            return this.sdlFPoint.y;
        }

        /++
         + Gets the static array representation of the `dsdl2.FPoint`
         +
         + Returns: X and Y as an array
         +/
        float[2] array() const @property {
            return [this.sdlFPoint.x, this.sdlFPoint.y];
        }
    }

    /++
     + D struct that wraps `SDL_FRect` (from SDL 2.0.10) representing a rectangle of floating point 2D
     + coordinate and dimension
     +
     + `dsdl2.FRect` stores `float`ing point `x` and `y` coordinate points, as well as `w`idth and `h`eight which
     + specifies the rectangle's dimension. `x` and `y` symbolize the top-left coordinate of the rectangle, and
     + the `w`idth and `h`eight extend to the positive plane of both axes.
     +
     + Examples:
     + ---
     + auto rect1 = dsdl2.FRect(-2.0, -2.0, 3.0, 3.0);
     + auto rect2 = dsdl2.FRect(-1.0, -1.0, 3.0, 3.0);
     +
     + assert(rect1.hasIntersection(rect2));
     + assert(rect1.intersectRect(rect2).get == dsdl2.FRect(-1.0, -1.0, 2.0, 2.0));
     + ---
     +/
    struct FRect {
        SDL_FRect sdlFRect; /// Internal `SDL_FRect` struct

        alias sdlFRect this;

        this() @disable;

        /++
         + Constructs a `dsdl2.FRect` from a vanilla `SDL_FRect` from bindbc-sdl
         +
         + Params:
         +   sdlFRect = the `SDL_FRect` struct
         +/
        this(SDL_FRect sdlFRect) {
            this.sdlFRect = sdlFRect;
        }

        /++
         + Constructs a `dsdl2.FRect` by feeding in the `x`, `y`, `width`, and `height` of the rectangle
         +
         + Params:
         +   x      = top-left x coordinate point of the rectangle
         +   y      = top-left y coordinate point of the rectangle
         +   width  = rectangle width
         +   height = rectangle height
         +/
        this(float x, float y, float width, float height) {
            this.sdlFRect.x = x;
            this.sdlFRect.y = y;
            this.sdlFRect.w = width;
            this.sdlFRect.h = height;
        }

        /++
         + Constructs a `dsdl2.FRect` by feeding in a `dsdl2.FPoint` as the `xy`, then `width` and `height` of
         + the rectangle
         +
         + Params:
         +   point  = top-left point of the rectangle
         +   width  = rectangle width
         +   height = rectangle height
         +/
        this(FPoint point, float width, float height) {
            this.sdlFRect.x = point.x;
            this.sdlFRect.y = point.y;
            this.sdlFRect.w = width;
            this.sdlFRect.h = height;
        }

        /++
         + Binary operation overload template to move rectangle's position by an `offset` as a `dsdl2.FPoint`
         +/
        FRect opBinary(string op)(const FPoint offset) const {
            return FRect(this.point + offset, this.width, this.height);
        }

        /++
         + Operator assignment overload template to move rectangle's position in-place by an `offset` as a
         + `dsdl2.FPoint`
         +/
        ref inout(FPoint) opOpAssign(string op)(const FPoint offset) inout {
            mixin("this.x" ~ op ~ "=offset.x");
            mixin("this.y" ~ op ~ "=offset.y");
            return this;
        }

        /++
         + Formats the `dsdl2.FRect` into its construction representation: `"dsdl2.FRect(<x>, <y>, <w>, <h>)"`
         +
         + Returns: the formatted `string`
         +/
        string toString() const {
            return "dsdl2.FRect(%d, %d, %d, %d)".format(this.x, this.y, this.width, this.height);
        }

        /++
         + Proxy to the X value of the `dsdl2.FRect`
         +
         + Returns: X value of the `dsdl2.FRect`
         +/
        ref inout(float) x() return inout @property {
            return this.sdlFRect.x;
        }

        /++
         + Proxy to the Y value of the `dsdl2.FRect`
         +
         + Returns: Y value of the `dsdl2.FRect`
         +/
        ref inout(float) y() return inout @property {
            return this.sdlFRect.y;
        }

        /++
         + Gets the `dsdl2.FPoint` representation for the X and Y of the `dsdl2.FRect`
         +
         + Returns: `dsdl2.FPoint` with X and Y of the `dsdl2.FRect`
         +/
        FPoint point() const @property {
            return FPoint(this.sdlFRect.x, this.sdlFRect.y);
        }

        /++
         + Proxy to the width of the `dsdl2.FRect`
         +
         + Returns: width of the `dsdl2.FRect`
         +/
        ref inout(float) width() return inout @property {
            return this.sdlFRect.w;
        }

        /++
         + Proxy to the height of the `dsdl2.Rect`
         +
         + Returns: height of the `dsdl2.Rect`
         +/
        ref inout(float) height() return inout @property {
            return this.sdlFRect.h;
        }

        /++
         + Gets the static array representation of the width and height of the `dsdl2.FRect`
         +
         + Returns: width and height as an array
         +/
        float[2] size() const @property {
            return [this.sdlFRect.w, this.sdlFRect.h];
        }

        static if (sdlSupport >= SDLSupport.v2_0_22) {
            /++
             + Wraps `SDL_FRectEmpty` (from SDL 2.0.22) which checks if the `dsdl2.FRect` is an empty rectangle
             +
             + Returns: `true` if it is empty, otherwise `false`
             +/
            bool empty() const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                return SDL_FRectEmpty(&this.sdlFRect);
            }

            /++
             + Wraps `SDL_PointInFRect` (from SDL 2.0.22) which sees whether the coordinate of a `dsdl2.FPoint`
             + is inside the `dsdl2.FRect`
             +
             + Params:
             +   point = the `dsdl2.FPoint` to check its collision of with the `dsdl2.FRect` instance
             + Returns: `true` if it is within, otherwise `false`
             +/
            bool pointInRect(FPoint point) const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                return SDL_PointInFRect(&point.sdlFPoint, &this.sdlFRect);
            }

            /++
             + Wraps `SDL_HasIntersectionF` (from SDL 2.0.22) which sees whether two `dsdl2.FRect`s intersect
             + each other
             +
             + Params:
             +   rect = other `dsdl2.FRect` to check its intersection of with the `dsdl2.FRect`
             + Returns: `true` if both have intersection with each other, otherwise `false`
             +/
            bool hasIntersection(FRect rect) const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                return SDL_HasIntersectionF(&this.sdlFRect, &rect.sdlFRect) == SDL_TRUE;
            }

            /++
             + Wraps `SDL_IntersectFRectAndLine` (from SDL 2.0.22) which sees whether a line intersects with the
             + `dsdl2.FRect`
             +
             + Params:
             +   line = set of two `dsdl2.FPoint`s denoting the start and end coordinates of the line to check
             +          its intersection of with the `dsdl2.FRect`
             + Returns: `true` if it intersects, otherwise `false`
             +/
            bool hasLineIntersection(FPoint[2] line) const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                return SDL_IntersectFRectAndLine(&this.sdlFRect, &line[0].sdlFPoint.x, &line[0].sdlFPoint.y,
                &line[1].sdlFPoint.x, &line[1].sdlFPoint.y) == SDL_TRUE;
            }

            /++
             + Wraps `SDL_IntersectFRect` (from SDL 2.0.22) which attempts to get the rectangle of intersection
             + between two `dsdl2.FRect`s
             +
             + Params:
             +   other = other `dsdl2.FRect` with which the `dsdl2.FRect` is intersected
             + Returns: non-null `Nullable!FRect` instance if intersection is present, otherwise a null one
             +/
            Nullable!FRect intersectRect(FRect other) const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                FRect intersection = void;
                if (SDL_IntersectFRect(&this.sdlFRect, &other.sdlFRect, &intersection.sdlFRect) == SDL_TRUE) {
                    return intersection.nullable;
                }
                else {
                    return Nullable!FRect.init;
                }
            }

            /++
             + Wraps `SDL_IntersectFRectAndLine` (from SDL 2.0.22) which attempts to clip a line segment in the
             + boundaries of the `dsdl2.FRect`
             +
             + Params:
             +   line = set of two `dsdl2.FPoint`s denoting the start and end coordinates of the line to clip from
             +          its intersection with the `dsdl2.FRect`
             + Returns: non-null `Nullable!(FPoint[2])` as the clipped line if there is an intersection,
             +          otherwise a null one
             +/
            Nullable!(FPoint[2]) intersectLine(FPoint[2] line) const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                if (SDL_IntersectFRectAndLine(&this.sdlFRect, &line[0].sdlFPoint.x, &line[0].sdlFPoint.y,
                    &line[1].sdlFPoint.x, &line[1].sdlFPoint.y) == SDL_TRUE) {
                    FPoint[2] intersection = [line[0], line[1]];
                    return intersection.nullable;
                }
                else {
                    return Nullable!(FPoint[2]).init;
                }
            }

            /++
             + Wraps `SDL_UnionFRect` which creates a `dsdl2.FRect` (from SDL 2.0.22) of the minimum size to
             + enclose two given `dsdl2.FRect`s
             +
             + Params:
             +   other = other `dsdl2.FRect` to unify with the `dsdl2.FRect`
             + Returns: `dsdl2.FRect` of the minimum size to enclose the `dsdl2.FRect` and `other`
             +/
            FRect unify(FRect other) const @trusted
            in {
                assert(getVersion() >= Version(2, 0, 22));
            }
            do {
                FRect union_ = void;
                SDL_UnionFRect(&this.sdlFRect, &other.sdlFRect, &union_.sdlFRect);
                return union_;
            }
        }
    }
}
