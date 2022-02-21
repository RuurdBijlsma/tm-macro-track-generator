namespace Generate {

bool initialized = false;
MacroPart@[]@ allParts = {};
MacroPart@[]@ filteredParts = {};
bool isGenerating = false;
int lastYield = 0;
int startCount = 0;
int partCount = 0;
int finishCount = 0;
dictionary@ usedParts = null;
bool lastGenerateFailed = false;
bool canceled = false;
int generatedMapDuration = 0;

void Initialize() {
    @allParts = GetMacroParts();
    UpdateFilteredParts();
}

// Get MacroParts from macro folder
MacroPart@[] GetMacroParts() {
    initialized = true;
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
    startCount = 0;
    partCount = 0;
    finishCount = 0;
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
            if(GenOptions::includeTags.Length == 0 || GenOptions::includeTags.Find(part.tags[j]) != -1) {
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
            startCount++;
        if(part.type == EPartType::Finish)
            finishCount++;
        if(part.type == EPartType::Part)
            partCount++;
        filtered.InsertLast(part);
    }
    if(startCount == 0) 
        warn("There are no start parts that fit the given filter.");
    if(finishCount == 0)
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
    if(isGenerating) return;

    if(allParts.Length == 0) {
        warn("No MacroParts found to generate a track with!");
        return;
    }
    
    Random::seedEnabled = GenOptions::useSeed;
    if(GenOptions::useSeed)
        Random::SetSeed(GenOptions::seed);

    isGenerating = true;
    Initialize();
    @usedParts = GetUsedPartsDictionary();
    generatedMapDuration = 0;

    print("Found " + filteredParts.Length + " available parts after global filter is applied.");

    // clear map for testing
    MTG::ClearMap();

    lastYield = Time::Now;
    bool success = PlacePart();
    if(canceled) {
        print("was canceled");
        canceled = false;
        success = true;
    }
    lastGenerateFailed = !success;
    if(!success) {
        warn("Failed to create route :(");
    }

    isGenerating = false;
}

dictionary GetUsedPartsDictionary() {
    dictionary result;
    for(uint i = 0; i < filteredParts.Length; i++) {
        result.Set(filteredParts[i].ID, 0);
    }
    return result;
}

MacroPart@[]@ FilterParts(int speed, const EPartType &in type) {
    MacroPart@[]@ filtered = {};
    for(uint i = 0; i < filteredParts.Length; i++) {
        auto part = filteredParts[i];
        if(part.type != type)
            continue;
        if(GenOptions::considerSpeed && Math::Abs(part.enterSpeed - speed) > GenOptions::maxSpeedVariation)
            continue;
        if(GenOptions::reuse == EReuse::NoReuse && int(usedParts[part.ID]) != 0)
            continue;
        filtered.InsertLast(part);
    }
    ShuffleParts(filtered);
    if(GenOptions::reuse == EReuse::PreferNoReuse) {
        filtered = Sort::SortParts(filtered, usedParts);
    }
    return filtered;
}

bool PlacePart(DirectedPosition@ connectPoint = null, int incomingSpeed = 0) {
    if(canceled) return false;
    auto now = Time::Now;
    // prevent crash due to timeout
    if(GenOptions::animate || now - lastYield > 150){
        lastYield = now;
        yield();
    }
    EPartType type;
    if(connectPoint is null) {
        type = EPartType::Start;
    } else {
        type = generatedMapDuration + 7 > GenOptions::desiredMapLength ? EPartType::Finish: EPartType::Part;
    }
    MacroPart@[]@ possibleParts = FilterParts(incomingSpeed, type);
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
        // print("Can place " + part.name + " at " + placePos.ToPrintString() + "?: " + canPlace + ". duration = " + generatedMapDuration);
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
        usedParts[part.ID] = int(usedParts[part.ID]) + 1;
        generatedMapDuration += part.duration;
        finished = PlacePart(partEntrancePos, part.exitSpeed);
        if(finished) {
            break;
        } else if(!canceled) {
            // print("Removing!");
            if(GenOptions::animate)
                yield();
            generatedMapDuration -= part.duration;
            usedParts[part.ID] = int(usedParts[part.ID]) - 1;
            editor.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
        }
    }
    
    return finished;
}

}