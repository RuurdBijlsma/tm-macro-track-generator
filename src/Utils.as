// unused
vec2 RotatePoint(vec2 pivot, float angle, vec2 point) {
    float s = Math::Sin(angle);
    float c = Math::Cos(angle);

    // translate point back to origin:
    point.x -= pivot.x;
    point.y -= pivot.y;

    // rotate point
    float xNew = point.x * c - point.y * s;
    float yNew = point.x * s + point.y * c;

    // translate point back:
    point.x = xNew + pivot.x;
    point.y = yNew + pivot.y;
    return point;
}