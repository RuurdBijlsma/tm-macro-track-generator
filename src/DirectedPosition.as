class DirectedPosition{
    int3 position;
    CGameEditorPluginMap::ECardinalDirections direction;
    DirectedPosition(int x = 0, int y = 0, int z = 0, CGameEditorPluginMap::ECardinalDirections direction = CGameEditorPluginMap::ECardinalDirections::North) {
        this.position = int3(x, y, z);
        this.direction = direction;
    }

    int get_x() {return position.x;}
    void set_x(int x) {position.x = x;}
    int get_y() {return position.y;}
    void set_y(int y) {position.y = y;}
    int get_z() {return position.z;}
    void set_z(int z) {position.z = z;}

    string ToPrintString() {
        return "[" + x + ", " + y + ", " + z + "], direction = " + tostring(direction);
    }

    string ToString() {
        return x + "," + y + "," + z + "," + int(direction);
    }
};