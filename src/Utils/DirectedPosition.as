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
DirectedPosition@ Add(DirectedPosition@ pos1, DirectedPosition@ pos2) {
    if(pos1 is null || pos2 is null) return null;
    auto newDirection = CGameEditorPluginMap::ECardinalDirections((pos1.direction + pos2.direction) % 4);

    if(pos1.direction == CGameEditorPluginMap::ECardinalDirections::North) {
        return DirectedPosition(
            pos1.x + pos2.x,
            pos1.y + pos2.y,
            pos1.z + pos2.z,
            newDirection
        );
    }
    if(pos1.direction == CGameEditorPluginMap::ECardinalDirections::East) {
        return DirectedPosition(
            pos1.x - pos2.z,
            pos1.y + pos2.y,
            pos1.z + pos2.x,
            newDirection
        );
    }
    if(pos1.direction == CGameEditorPluginMap::ECardinalDirections::South) {
        return DirectedPosition(
            pos1.x - pos2.x,
            pos1.y + pos2.y,
            pos1.z - pos2.z,
            newDirection
        );
    }
    if(pos1.direction == CGameEditorPluginMap::ECardinalDirections::West) {
        // print("ADD");
        // print("pos1: " + pos1.ToString());
        // print("pos2: " + pos2.ToString());
        return DirectedPosition(
            pos1.x + pos2.z,
            pos1.y + pos2.y,
            pos1.z - pos2.x,
            newDirection
        );
    }
    return null;
}
DirectedPosition@ Subtract(DirectedPosition@ pos1, DirectedPosition@ pos2) {
    if(pos1 is null || pos2 is null) return null;
    auto newDirection = CGameEditorPluginMap::ECardinalDirections((pos1.direction - pos2.direction + 4) % 4);

    if(pos2 == CGameEditorPluginMap::ECardinalDirections::North) {
        return DirectedPosition(
            pos1.x - pos2.x,
            pos1.y - pos2.y,
            pos1.z - pos2.z,
            newDirection
        );
    }
    if(pos2 == CGameEditorPluginMap::ECardinalDirections::East) {
        return DirectedPosition(
            pos1.z - pos2.z,
            pos1.y - pos2.y,
            pos2.x - pos1.x,
            newDirection
        );
    }
    if(pos2 == CGameEditorPluginMap::ECardinalDirections::South) {
        return DirectedPosition(
            pos2.x - pos1.x,
            pos1.y - pos2.y,
            pos2.z - pos1.z,
            newDirection
        );
    }
    if(pos2 == CGameEditorPluginMap::ECardinalDirections::West) {
        return DirectedPosition(
            pos2.z - pos1.z,
            pos1.y - pos2.y,
            pos1.x - pos2.x,
            newDirection
        );
    }
    return null;
}

DirectedPosition@ FromString(string input) {
    auto parts = input.Split(",");
    int x = Text::ParseInt(parts[0]);
    int y = Text::ParseInt(parts[1]);
    int z = Text::ParseInt(parts[2]);
    auto direction = CGameEditorPluginMap::ECardinalDirections(Text::ParseInt(parts[3]));
    return DirectedPosition(x, y, z, direction);
}
}