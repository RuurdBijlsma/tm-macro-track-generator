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

class SpiralOut{
    int layer;
    int leg;
    int x, y; //read these as output from next, do not modify.
    
    SpiralOut() {
        layer = 1;
        leg = 0;
        x = 0;
        y = 0;
    }

    void GoNext(){
        switch(leg) {
            case 0: ++x; if(x  == layer)  ++leg;                break;
            case 1: ++y; if(y  == layer)  ++leg;                break;
            case 2: --x; if(-x == layer)  ++leg;                break;
            case 3: --y; if(-y == layer){ leg = 0; ++layer; }   break;
        }
    }
};