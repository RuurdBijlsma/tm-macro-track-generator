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
dictionary@ filterReasons = null;
bool lastGenerateFailed = false;
bool canceled = false;
int generatedMapDuration = 0;
string[]@ deletedParts = {};

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
                    if(macroblock.IdName.EndsWith("temp_MTG.Macroblock.Gbx")) continue;
                    if(deletedParts.Find(macroblock.IdName) != -1) continue;
                    auto macroPart = MacroPart::FromMacroblock(macroblock);
                    if(macroPart is null) continue;
                    macroParts.InsertLast(macroPart);
                }
            }
        }
    }

    return macroParts;
}

MacroPart@[]@ GlobalFilterParts() {
    startCount = 0;
    partCount = 0;
    finishCount = 0;
    MacroPart@[]@ filtered = {};
    @filterReasons = GetFilterReasonsDictionary();

    for(uint i = 0; i < allParts.Length; i++) {
        auto part = allParts[i];
        if(part.type != EPartType::Start) {
            if(part.enterSpeed > GenOptions::maxSpeed || part.enterSpeed < GenOptions::minSpeed) {
                filterReasons[part.ID] = "Min or max speed filter: enter speed = " + part.enterSpeed;
                warn("Removing part " + part.name + " by filter: speed entrance");
                continue;
            }
        }
        if(part.type != EPartType::Finish) 
            if(part.exitSpeed > GenOptions::maxSpeed || part.exitSpeed < GenOptions::minSpeed) {
                filterReasons[part.ID] = "Min or max speed filter: exit speed = " + part.exitSpeed;
                warn("Removing part " + part.name + " by filter: speed exit");
                continue;
            }
        if(!GenOptions::allowCustomItems && part.HasCustomItems) {
            filterReasons[part.ID] = "Part has custom items";
            warn("Removing part " + part.name + " by filter: HasCustomItems");
            continue;
        }
        if(!GenOptions::allowCustomBlocks && part.HasCustomBlocks) {
            filterReasons[part.ID] = "Part has custom blocks";
            warn("Removing part " + part.name + " by filter: HasCustomBlocks");
            continue;
        }
        bool partHasIncludeTag = false;
        bool partHasExcludeTag = false;
        string illegalTag = "";
        for(uint j = 0; j < part.tags.Length; j++) {
            if(GenOptions::includeTags.Length == 0 || GenOptions::includeTags.Find(part.tags[j]) != -1) {
                partHasIncludeTag = true;
            }
            if(GenOptions::excludeTags.Find(part.tags[j]) != -1) {
                partHasExcludeTag = true;
                illegalTag = part.tags[j];
                break;
            }
        }
        if(partHasExcludeTag){
            filterReasons[part.ID] = "Part includes illegal tag: " + illegalTag;
            warn("Removing part " + part.name + " by filter: partHasExcludeTag");
            continue;
        }
        if(!partHasIncludeTag){
            filterReasons[part.ID] = "Part does not include any of the required tags";
            warn("Removing part " + part.name + " by filter: partHasIncludeTag");
            continue;
        }
        if(GenOptions::difficulties.Find(part.difficulty) == -1) {
            filterReasons[part.ID] = "Part difficulty not in the difficulty filter";
            warn("Removing part " + part.name + " by filter: difficulties");
            continue;
        }
        if(GenOptions::author != "" && GenOptions::author != part.author) {
            filterReasons[part.ID] = "Author mismatch";
            warn("Removing part " + part.name + " by filter: author");
            continue;
        }
        if(GenOptions::respawnable && !part.respawnable) {
            filterReasons[part.ID] = "Part is not respawnable";
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
    if(GenOptions::clearMap)
        MTG::ClearMap();

    lastYield = Time::Now;
    bool success = PlacePart();
    
    // bool success = true;
    // auto possibleParts = FilterParts(0, EPartType::Start);
    // auto starts = StartPositionGenerator(possibleParts[0]);
    // while(true) {
    //     auto pos = starts.Next();
    //     print(pos.ToPrintString());
    //     if(pos is null)
    //         break;
    // }


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

dictionary GetFilterReasonsDictionary() {
    dictionary result;
    for(uint i = 0; i < filteredParts.Length; i++) {
        result.Set(filteredParts[i].ID, "");
    }
    return result;
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

bool Place(MacroPart@ part, DirectedPosition@ placePos) {
    bool placed;
    if(GenOptions::forceColor) {
        editor.PluginMapType.ForceMacroblockColor = true;
        auto color = GenOptions::color;
        if(GenOptions::autoColoring) {
            auto percentage = Math::Clamp(float(generatedMapDuration) / float(GenOptions::desiredMapLength), 0, .999999);
            color = availableColors[1 + int((availableColors.Length - 1) * percentage)];
        }
        editor.PluginMapType.NextMapElemColor = color;
    } else {
        editor.PluginMapType.ForceMacroblockColor = false;
    }
    if(GenOptions::airMode) {
        placed = editor.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, placePos.position, placePos.direction);
    } else {
        placed = editor.PluginMapType.PlaceMacroblock(part.macroblock, placePos.position, placePos.direction);
    }
    if(placed) {
        usedParts[part.ID] = int(usedParts[part.ID]) + 1;
        generatedMapDuration += part.duration;
    }
    return placed;
}

void UnPlace(MacroPart@ part, DirectedPosition@ placePos) {
    editor.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
    generatedMapDuration -= part.duration;
    usedParts[part.ID] = int(usedParts[part.ID]) - 1;
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
    auto possibleParts = FilterParts(incomingSpeed, type);
    bool finished = false;

    DirectedPosition@ placePos = null;
    StartPositionGenerator@ starts = null;
    for(uint i = 0; i < possibleParts.Length; i++) {
        auto part = possibleParts[i];
        if(type == EPartType::Start) {
            @starts = StartPositionGenerator(part);
        } else {
            auto northArrow = MTG::GetNorthArrowFromRelativePosition(connectPoint, part.entrance);
            @placePos = MTG::NorthArrowToCursor(part.macroblock, northArrow);
        }
        while(true) {
            if(type == EPartType::Start) {
                @placePos = starts.Next();
                print("Test start pos: " + placePos.ToPrintString());
                if(placePos is null) break;
            }
            bool canPlace = editor.PluginMapType.CanPlaceMacroblock_NoDestruction(part.macroblock, placePos.position, placePos.direction);
            // print("Can place " + part.name + " at " + placePos.ToPrintString() + "?: " + canPlace + ". duration = " + generatedMapDuration);
            if(!canPlace) 
                break;
            bool placed = Place(part, placePos);
            if(!placed)
                break;
            if(type == EPartType::Finish)
                return true;
            auto partEntrancePos = MTG::ToAbsolutePosition(part.macroblock, placePos, part.exit);
            partEntrancePos.MoveForward();
            finished = PlacePart(partEntrancePos, part.exitSpeed);
            if(!finished && !canceled) {
                UnPlace(part, placePos);
                // print("Removing!");
                if(GenOptions::animate)
                    yield();
            }
            if(type != EPartType::Start || finished || canceled)
                break;
        }
        if(finished) break;
    }
    
    return finished;
}

}