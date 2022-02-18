namespace Generate {

MacroPart@[]@ allParts = {};
MacroPart@[]@ filteredParts = {};

void Initialize() {
    GenOptions::Initialize();
    @allParts = GetMacroParts();
}

// Get MacroParts from macro folder
MacroPart@[] GetMacroParts() {
    print("Editor is null? " + (editor is null));
    auto pluginMapType = editor.PluginMapType;
    auto inventory = pluginMapType.Inventory;
    auto rootNodes = inventory.RootNodes;
    MacroPart@[] macroParts = {};
    for(uint i = 0; i < rootNodes.Length; i++) {
        auto node = cast<CGameCtnArticleNodeDirectory>(rootNodes[i]);
        if(node is null) continue;
        for(uint j = 0; j < node.ChildNodes.Length; j++) {
            if(node.ChildNodes[j].Name == macroPartFolder){
                auto mbFolder = cast<CGameCtnArticleNodeDirectory@>(node.ChildNodes[j]);
                for(uint k = 0; k < mbFolder.ChildNodes.Length; k++) {
                    auto articleNode = cast<CGameCtnArticleNodeArticle@>(mbFolder.ChildNodes[k]);
                    if(articleNode is null) continue;
                    print(articleNode.Article.IdName);
                    auto macroblock = cast<CGameCtnMacroBlockInfo@>(articleNode.Article.LoadedNod);
                    if(macroblock is null) continue;
                    if(macroblock.IdName.StartsWith("temp_")) continue;
                    auto macroPart = MacroPart::FromMacroblock(macroblock);
                    if(macroPart is null) continue;
                    macroParts.InsertLast(macroPart);
                }
            }
        }
    }

    return macroParts;
}

DirectedPosition@ FindStartPosition(CGameCtnMacroBlockInfo@ macroblock) {
    auto mapSize = editor.Challenge.Size;
    auto macroblockSize = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    auto placeDir = CGameEditorPluginMap::ECardinalDirections::South;
    auto startX = mapSize.x / 2 - macroblockSize.x / 2;
    auto startY = mapSize.y / 2 - macroblockSize.y / 2;
    auto startZ = mapSize.z / 2 - macroblockSize.z / 2;
    auto spiral = SpiralOut();

    while(true) {
        auto x = startX + spiral.x;
        auto z = startZ + spiral.y;
        for(uint y = startY; y < mapSize.y; y++) {
            auto placePoint = DirectedPosition(x, y, z, placeDir);
            auto canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, placePoint.position, placePoint.direction);
            if(canPlace) 
                return placePoint;
        }
        for(uint y = startY - 1; y > 0; y--) {
            auto placePoint = DirectedPosition(x, y, z, placeDir);
            auto canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, placePoint.position, placePoint.direction);
            if(canPlace) 
                return placePoint;
        }
        spiral.GoNext();
        if(spiral.layer > int(mapSize.x)) {
            warn("Could not find starting position for track");
            break;
        }
    }

    return null;
}

MacroPart@[]@ GlobalFilterParts() {
    bool hasStart = false;
    bool hasFinish = false;
    MacroPart@[]@ filtered = {};
    for(uint i = 0; i < allParts.Length; i++) {
        auto part = allParts[i];
        if(part.type != EPartType::Start) {
            if(part.enterSpeed > GenOptions::maxSpeed || part.enterSpeed < GenOptions::minSpeed) {
                warn("Removing part " + part.name + " by filter: speed entrance");
                continue;
            }
        }
        if(part.type != EPartType::Finish) 
            if(part.exitSpeed > GenOptions::maxSpeed || part.exitSpeed < GenOptions::minSpeed) {
                warn("Removing part " + part.name + " by filter: speed exit");
                continue;
            }
        if(!GenOptions::allowCustomItems && part.HasCustomItems){
            warn("Removing part " + part.name + " by filter: HasCustomItems");
            continue;
        }
        if(!GenOptions::allowCustomBlocks && part.HasCustomBlocks){
            warn("Removing part " + part.name + " by filter: HasCustomBlocks");
            continue;
        }
        bool partHasIncludeTag = false;
        bool partHasExcludeTag = false;
        for(uint j = 0; j < part.tags.Length; j++) {
            if(GenOptions::includeTags.Find(part.tags[j]) != -1) {
                partHasIncludeTag = true;
            }
            if(GenOptions::excludeTags.Find(part.tags[j]) != -1) {
                partHasExcludeTag = true;
                break;
            }
        }
        if(partHasExcludeTag){
            warn("Removing part " + part.name + " by filter: partHasExcludeTag");
            continue;
        }
        if(!partHasIncludeTag){
            warn("Removing part " + part.name + " by filter: partHasIncludeTag");
            continue;
        }
        if(GenOptions::difficulties.Find(part.difficulty) == -1){
            warn("Removing part " + part.name + " by filter: difficulties");
            continue;
        }
        if(GenOptions::author != "" && GenOptions::author != part.author){
            warn("Removing part " + part.name + " by filter: author");
            continue;
        }
        if(GenOptions::respawnable && !part.respawnable){
            warn("Removing part " + part.name + " by filter: respawnable");
            continue;
        }
        if(part.type == EPartType::Start)
            hasStart = true;
        if(part.type == EPartType::Finish)
            hasFinish = true;
        filtered.InsertLast(part);
    }
    if(!hasStart) 
        warn("There are no start parts that fit the given filter.");
    if(!hasFinish)
        warn("There are no finish parts that fit the given filter.");
    return filtered;
}

void UpdateFilteredParts() {
    @filteredParts = GlobalFilterParts();
    if(filteredParts.Length == 0) {
        warn("Because of the set filters, there are no MacroParts to generate a track with!");
    }
}

void GenerateTrack() {
    Random::seedEnabled = GenOptions::useSeed;
    Random::seedText = GenOptions::seed;
    if(allParts.Length == 0) {
        warn("No MacroParts found to generate a track with!");
        return;
    }
    UpdateFilteredParts();

    print("Found " + filteredParts.Length + " available parts after global filter is applied.");

    // clear map for testing
    editor.PluginMapType.RemoveAllBlocks();

    lastYield = Time::Now;
    auto success = PlacePart();
    if(!success) {
        warn("Failed to create route :(");
    }
}

MacroPart@[]@ FilterParts(int speed, const EPartType &in type, MacroPart@[]@ usedParts) {
    MacroPart@[]@ filtered = {};
    for(uint i = 0; i < filteredParts.Length; i++) {
        auto part = filteredParts[i];
        if(part.type != type)
            continue;
        if(GenOptions::considerSpeed && Math::Abs(part.enterSpeed - speed) > GenOptions::maxSpeedVariation)
            continue;
        if(GenOptions::reuse == EReuse::NoReuse && usedParts.FindByRef(part) != -1)
            continue;
        filtered.InsertLast(part);
    }
    ShuffleParts(filtered);
    if(GenOptions::reuse == EReuse::PreferNoReuse) {
        MacroPart@[]@ usedList = {};
        MacroPart@[]@ unusedList = {};
        for(uint i = 0; i < filtered.Length; i++) {
            auto part = filtered[i];
            if(usedParts.FindByRef(part) != -1){
                usedList.InsertLast(part);
            } else {
                unusedList.InsertLast(part);
            }
        }
        @filtered = {};
        for(uint i = 0; i < unusedList.Length; i++)
            filtered.InsertLast(unusedList[i]);
        for(uint i = 0; i < usedList.Length; i++)
            filtered.InsertLast(usedList[i]);
    }
    return filtered;
}

int lastYield = 0;
bool PlacePart(DirectedPosition@ connectPoint = null, int incomingSpeed = 0, int duration = 0, MacroPart@[] usedParts = {}) {
    auto now = Time::Now;
    // prevent crash due to timeout
    if(GenOptions::animate || now - lastYield > 900){
        lastYield = now;
        yield();
    }
    EPartType type;
    if(connectPoint is null) {
        type = EPartType::Start;
    } else {
        type = duration + 7 > GenOptions::desiredMapLength ? EPartType::Finish: EPartType::Part;
    }
    MacroPart@[]@ possibleParts = FilterParts(incomingSpeed, type, usedParts);
    bool finished = false;

    for(uint i = 0; i < possibleParts.Length; i++) {
        auto part = possibleParts[i];
        DirectedPosition@ placePos = null;
        if(type == EPartType::Start) {
            @placePos = FindStartPosition(part.macroblock);
            if(placePos is null) 
                continue;
        } else {
            auto northArrow = MTG::GetNorthArrowFromRelativePosition(connectPoint, part.entrance);
            @placePos = MTG::NorthArrowToCursor(part.macroblock, northArrow);
        }
        bool canPlace = editor.PluginMapType.CanPlaceMacroblock(part.macroblock, placePos.position, placePos.direction);
        print("Can place " + part.name + " at " + placePos.ToPrintString() + "?: " + canPlace + ". duration = " + duration);
        if(!canPlace) 
            continue;
        bool placed;
        if(GenOptions::airMode) {
            placed = editor.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, placePos.position, placePos.direction);
        } else {
            placed = editor.PluginMapType.PlaceMacroblock(part.macroblock, placePos.position, placePos.direction);
        }
        if(!placed)
            continue;
        if(type == EPartType::Finish) {
            return true;
        }
        auto partEntrancePos = MTG::ToAbsolutePosition(part.macroblock, placePos, part.exit);
        partEntrancePos.MoveForward();
        usedParts.InsertLast(part);
        finished = PlacePart(partEntrancePos, part.exitSpeed, duration + part.duration, usedParts);
        if(finished) {
            print("Finished!");
            break;
        } else {
            print("Removing!");
            if(GenOptions::animate)
                yield();
            usedParts.RemoveLast();
            editor.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
            // return false;
        }
    }
    
    return finished;
}

}