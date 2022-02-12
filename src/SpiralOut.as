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
        switch(leg){
            case 0: ++x; if(x  == layer)  ++leg;                break;
            case 1: ++y; if(y  == layer)  ++leg;                break;
            case 2: --x; if(-x == layer)  ++leg;                break;
            case 3: --y; if(-y == layer){ leg = 0; ++layer; }   break;
        }
    }
};