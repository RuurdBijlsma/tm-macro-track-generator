enum EConnector {
    Platform,
    RoadTech,
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
    Beginner,
    Intermediate,
    Advanced,
    Expert
};

string[]@ availableTags = { "Tech", "Dirt", "Bobsleigh", "Grass", "Ice", "Plastic", "Water", "Sausage", "Platform", "FullSpeed", "Nascar", "Transitional", "RPG"};
EConnector[]@ availableConnectors = {EConnector::Platform, EConnector::RoadTech, EConnector::RoadDirt, EConnector::RoadIce, EConnector::RoadBump, EConnector::DecoWall};
EPartType[]@ availableTypes = {EPartType::Start, EPartType::Finish, EPartType::Part, EPartType::Multilap};
EDifficulty[]@ availableDifficulties = {EDifficulty::Beginner, EDifficulty::Intermediate, EDifficulty::Advanced, EDifficulty::Expert};

class MacroPart {
    CGameCtnMacroBlockInfo@ macroblock = null;
    string folder = "";

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
    EDifficulty difficulty = EDifficulty::Beginner;

    MacroPart() {
        author = GetLocalLogin();
    }

    string get_ID() {
        return macroblock.IdName;
    }

    bool get_HasCustomItems() {
        for(uint i = 0; i < embeddedItems.Length; i++) {
            if(embeddedItems[i].ToLower().EndsWith(".item.gbx"))
                return true;
        }
        return false;
    }

    bool get_HasCustomBlocks() {
        for(uint i = 0; i < embeddedItems.Length; i++) {
            if(embeddedItems[i].ToLower().EndsWith(".block.gbx"))
                return true;
        }
        return false;
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
        // 0        1       2       3       4       5                   6           7               8       9           10          11      12          13      14          
        // version, name, author, entrance, exit, entranceConnector, exitConnector, embeddedItems, tags, enterSpeed, exitSpeed, duration, respawnable, type, difficulty
        return string::Join({
            version,
            name.Replace(MacroPart::DetailSeparator, ''),
            author.Replace(MacroPart::DetailSeparator, ''),
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
            tostring(int(type)),
            tostring(int(difficulty))
        }, MacroPart::DetailSeparator);
    }

    MemoryBuffer GetItemBuffer(const string &in relItemPath) {
        string input = macroblock.Description;
        auto versionParts = input.Split(MacroPart::DetailSeparator);
        auto version = versionParts[0];
        MemoryBuffer buffer = MemoryBuffer();
        if(versionParts.Length < 1)
            return buffer;
        auto index = embeddedItems.Find(relItemPath);
        if(index == -1) {
            warn("Requested relItemPath not in embeddedItems");
            return buffer;
        }
        if(version == "1") {
            auto baseParts = input.Split(MacroPart::BaseSeparator);
            if(baseParts.Length < 2) return buffer;
            auto base64Strings = baseParts[1].Split(MacroPart::DetailSeparator);
            if(base64Strings.Length != embeddedItems.Length) {
                warn("Mismatch between base64 strings and embedded items length");
                return buffer;
            }
            buffer.WriteFromBase64(base64Strings[index]);
            return buffer;
        }
        return buffer;
    }

    int3 GetFarBound(DirectedPosition@ placePos) {
        auto size = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
        int maxX, maxZ;
        if(placePos.direction == CGameEditorPluginMap::ECardinalDirections::East || placePos.direction == CGameEditorPluginMap::ECardinalDirections::West) {
            maxX = placePos.x + size.z - 1; // if east or west
            maxZ = placePos.z + size.x - 1; // if east or west
        } else {
            maxX = placePos.x + size.x - 1; // if north or south
            maxZ = placePos.z + size.z - 1; // if north or south
        }
        return int3(maxX, placePos.y + size.y - 1, maxZ);
    }
};

namespace MacroPart {
auto DetailSeparator = "|";
auto BaseSeparator = "|||||";

MacroPart@ FromMacroblock(CGameCtnMacroBlockInfo@ macroblock) {
    string input = macroblock.Description;
    auto versionParts = input.Split(DetailSeparator);
    if(versionParts.Length < 1)
        return null;
    auto result = MacroPart();
    @result.macroblock = macroblock;
    auto version = versionParts[0];

    if(version == "1") {
        auto details = input.Split(BaseSeparator)[0].Split(DetailSeparator);
        if(details.Length != 15){
            warn("Invalid MacroPart");
            return null;
        }
        result.name = details[1];
        result.author = details[2];
        @result.entrance = DirectedPosition::FromString(details[3]);
        @result.exit = DirectedPosition::FromString(details[4]);
        result.entranceConnector = EConnector(Text::ParseInt(details[5]));
        result.exitConnector = EConnector(Text::ParseInt(details[6]));
        result.embeddedItems = details[7].Split(":");
        string[] tags = details[8].Split(":");
        // filter invalid tags
        for(int i = int(tags.Length) - 1; i >= 0; i--) {
            if(availableTags.Find(tags[i]) == -1)
                tags.RemoveAt(i);
        }
        result.tags = tags;
        result.enterSpeed = Text::ParseInt(details[9]);
        result.exitSpeed = Text::ParseInt(details[10]);
        result.duration = Text::ParseInt(details[11]);
        result.respawnable = details[12] == 'true';
        result.type = EPartType(Text::ParseInt(details[13]));
        result.difficulty = EDifficulty(Text::ParseInt(details[14]));
    } else {
        warn("MacroPart version not supported.");
        // MacroPart@ a = null;
        // print(a.name);
    }

    return result;
}
}