string[]@ availableTags = {"FullSpeed", "Tech", "Mixed", "Nascar", "Dirt", "Grass", "Ice", "Plastic", "Water", "Road Bump", "RPG", "Race"};

enum EConnector {
    Platform,
    DirtRoad,
    Bobsleigh,
    Bump,
    Decowall
};

enum EPartType {
    Start,
    Finish,
    Part,
    Multilap,
};

enum EDifficulty {
    Beginner, // ez cotd
    Intermediate, // hard cotd
    Advanced, // tmgl
    Expert // crazy
};

class MacroPartDetails {
    DirectedPosition@ entrance = DirectedPosition();
    DirectedPosition@ exit = DirectedPosition();
    string[]@ embeddedItems = {};

    EConnector entranceConnector = EConnector::Platform;
    EConnector exitConnector = EConnector::Platform;

    // user input
    string name = "";
    string[]@ tags = {};
    int enterSpeed = 100;
    int exitSpeed = 200;
    int duration = 10;
    bool respawnable = false;
    EPartType type = EPartType::Part;
    EDifficulty difficulty = EDifficulty::Intermediate;
};