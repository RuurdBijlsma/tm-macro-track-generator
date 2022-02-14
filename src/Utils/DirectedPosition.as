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

    void MoveForward(int steps = 1) {
        if(direction == CGameEditorPluginMap::ECardinalDirections::North)
            z += steps;
        else if(direction == CGameEditorPluginMap::ECardinalDirections::East)
            x -= steps;
        else if(direction == CGameEditorPluginMap::ECardinalDirections::South)
            z -= steps;
        else if(direction == CGameEditorPluginMap::ECardinalDirections::West)
            x += steps;
    }
};

namespace DirectedPosition {
DirectedPosition@ FromString(string input) {
    auto parts = input.Split(",");
    int x = Text::ParseInt(parts[0]);
    int y = Text::ParseInt(parts[1]);
    int z = Text::ParseInt(parts[2]);
    auto direction = CGameEditorPluginMap::ECardinalDirections(Text::ParseInt(parts[3]));
    return DirectedPosition(x, y, z, direction);
}
}