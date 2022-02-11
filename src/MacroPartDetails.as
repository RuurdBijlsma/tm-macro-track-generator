enum EConnector {
    Platform,
    RoadDirt,
    RoadIce,
    RoadBump,
    DecoWall
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

string[]@ availableTags = {"FullSpeed", "Tech", "Mixed", "Nascar", "Dirt", "Bobsleigh", "Grass", "Ice", "Plastic", "Water", "Road Bump", "RPG", "Race"};
EConnector[]@ availableConnectors = {EConnector::Platform, EConnector::RoadDirt, EConnector::RoadIce, EConnector::RoadBump, EConnector::DecoWall};
EPartType[]@ availableTypes = {EPartType::Start, EPartType::Finish, EPartType::Part, EPartType::Multilap};
EDifficulty[]@ availableDifficulties = {EDifficulty::Beginner, EDifficulty::Intermediate, EDifficulty::Advanced, EDifficulty::Expert};

class MacroPartDetails {
    string name = "";
    string author = "";
    DirectedPosition@ entrance = DirectedPosition();
    DirectedPosition@ exit = DirectedPosition();
    EConnector entranceConnector = EConnector::Platform;
    EConnector exitConnector = EConnector::Platform;
    string[]@ embeddedItems = {};
    string[]@ tags = {};

    int enterSpeed = 100;
    int exitSpeed = 200;
    int duration = 10;
    bool respawnable = false;
    EPartType type = EPartType::Part;
    EDifficulty difficulty = EDifficulty::Intermediate;

    MacroPartDetails() {
        author = GetLocalLogin();
    }

    void AddTags(string[]@ newTags) {
        for(uint i = 0; i < newTags.Length; i++) {
            auto newTag = newTags[i];
            if(tags.Find(newTag) == -1) 
                tags.InsertLast(newTag);
        }
    }

    string ToString() {
        string version = "1";
        // Version 1 order: 
        // version, name, author, entrance, exit, entranceConnector, exitConnector, embeddedItems, tags, enterSpeed, exitSpeed, duration, respawnable, type, difficulty
        return string::Join({
            version,
            name.Replace('|', ''),
            author.Replace('|', ''),
            entrance.ToString(),
            exit.ToString(),
            tostring(int(entranceConnector)),
            tostring(int(exitConnector)),
            string::Join(embeddedItems, ':'),
            string::Join(tags, ':'),
            tostring(enterSpeed),
            tostring(exitSpeed),
            tostring(duration),
            tostring(respawnable),
            tostring(type),
            tostring(int(difficulty)),
        }, "|");
    }
};