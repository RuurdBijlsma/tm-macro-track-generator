namespace Generate {

bool initialized = false;
MacroPart@[]@ allParts = {};
MacroPart@[]@ filteredParts = {};
bool isGenerating = false;
int lastYield = 0;
int startCount = 0;
int partCount = 0;
int finishCount = 0;
int usedPartsCount = 0;
dictionary@ usedParts = null;
dictionary@ filterReasons = null;
bool lastGenerateFailed = false;
bool canceled = false;
int generatedMapDuration = 0;
int triedParts = 0;
string[]@ deletedParts = {};

void ResetState() {
    @allParts = {};
    @filteredParts = {};
    @usedParts = null;
    @filterReasons = null;
    @deletedParts = {};
}

void Initialize() {
    @allParts = {};
    @filteredParts = {};
    @usedParts = null;
    @allParts = GetMacroParts();
    CheckEmbeddedItems();
    UpdateFilteredParts();
}

MacroPart@[] ExploreNode(CGameCtnArticleNodeDirectory@ node, string folder = "") {
    MacroPart@[] macroParts = {};
    if(node is null) return macroParts;
    for(uint i = 0; i < node.ChildNodes.Length; i++) {
        auto childNode = node.ChildNodes[i];
        if(node.ChildNodes[i].IsDirectory) {
            auto newFolder = folder == "" ? string(childNode.Name) : folder + "/" + childNode.Name;
            auto newParts = ExploreNode(cast<CGameCtnArticleNodeDirectory@>(childNode), newFolder);
            for(uint j = 0; j < newParts.Length; j++) {
                macroParts.InsertLast(newParts[j]);
            }
        } else {
            auto articleNode = cast<CGameCtnArticleNodeArticle@>(childNode);
            if(articleNode is null) continue;
            auto macroblock = cast<CGameCtnMacroBlockInfo@>(articleNode.Article.LoadedNod);
            if(macroblock is null) continue;
            if(macroblock.IdName.EndsWith("temp_MTG.Macroblock.Gbx")) continue;
            if(deletedParts.Find(macroblock.IdName) != -1) continue;
            auto macroPart = MacroPart::FromMacroblock(macroblock);
            if(macroPart is null) continue;
            macroPart.folder = folder;
            macroParts.InsertLast(macroPart);
        }
    }
    return macroParts;
}

// Get MacroParts from macro folder
MacroPart@[] GetMacroParts() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return {};
    initialized = true;
    auto inventory = editor.PluginMapType.Inventory;
    auto rootNodes = inventory.RootNodes;
    MacroPart@[] macroParts = {};
    for(uint i = 0; i < rootNodes.Length; i++) {
        auto node = cast<CGameCtnArticleNodeDirectory@>(rootNodes[i]);
        if(node is null) continue;
        for(uint j = 0; j < node.ChildNodes.Length; j++) {
            if(node.ChildNodes[j].Name == macroPartFolder) {
                macroParts = ExploreNode(cast<CGameCtnArticleNodeDirectory@>(node.ChildNodes[j]));
                break;
            }
        }
    }

    return macroParts;
}

void CheckEmbeddedItems() {
    // If user is still in the process of answering the prompt, don't check again
    if(TMDialog::promptOpen) return;
    auto missingBlock = false;
    string[]@ missingItems = {};
    for(uint i = 0; i < allParts.Length; i++) {
        auto part = allParts[i];
        for(uint j = 0; j < part.embeddedItems.Length; j++) {
            auto relItemPath = part.embeddedItems[j];
            auto itemPath = MTG::GetItemsFolder() + relItemPath;
            if(!IO::FileExists(itemPath)) {
                // print("Part: " + part.ID + ", item: " + relItemPath);
                if(relItemPath.ToLower().EndsWith(".block.gbx"))
                    missingBlock = true;
                if(missingItems.Find(relItemPath) == -1) {
                    auto buffer = part.GetItemBuffer(relItemPath);
                    print("Buffer size: " + buffer.GetSize());
                    if(buffer.GetSize() == 0) {
                        warn("Invalid buffer! Can't get item: " + relItemPath);
                        continue;
                    }
                    missingItems.InsertLast(relItemPath);
                    
                    auto folderParts = relItemPath.Split("\\");
                    auto folder = relItemPath.SubStr(0, relItemPath.Length - folderParts[folderParts.Length - 1].Length);
                    // print("Folder: " + folder);
                    print("Buffer Size: " + buffer.GetSize());
                    // create folders recursive
                    MTG::CreateFolderRecursive(MTG::GetItemsFolder(), folder);
                    print("ItemPath: " + itemPath);
                    IO::File f(itemPath);
                    // print("Filemode: " + tostring(f.GetMode()));
                    f.Open(IO::FileMode::Write);
                    f.Write(buffer);
                    f.Close();
                }
            }
        }
    }
    if(missingBlock) {
        print("One of the missing items is a block, restart is required to use them");
        // restart is needed
        auto app = GetApp();
        auto editor = Editor();
        if(editor is null || editor.PluginMapType is null) return;
        TMDialog::Alert("Some MacroParts contain custom items or blocks which are not yet loaded.", "Restart the game to be able to use these parts");
    } else if(missingItems.Length > 0) {
        print("MIssing items? : " + missingItems.Length);
#if DEPENDENCY_ITEMEXCHANGE
    print("DEPENDENCY DETECTED");
    startnew(AskImportItems, missingItems);
#else
    print("DEPENDENCY NOT HERE");
    TMDialog::Alert("Some MacroParts contain custom items or blocks which are not yet loaded.", "Restart the game to be able to use these parts");
#endif
    }
}

void AskImportItems(ref@ missingItems) {
    auto items = cast<string[]@>(missingItems);
    print("All missing items can be imported!");
    TMDialog::Confirm(
        "Some MacroParts contain custom items which are not yet loaded.", 
        "Import " + items.Length + " item"+(items.Length == 1 ? "" : "s")+" now using the ItemExchange plugin? Restarting the game also loads the items.", 
        "Import now", "No");
    while(TMDialog::promptOpen) yield();
    print("Prompt closed with answer: " + TMDialog::promptResult);
    if(TMDialog::promptResult) {
        ItemExchange::ImportUnloadedItems();
    }
}

MacroPart@[]@ GlobalFilterParts() {
    startCount = 0;
    partCount = 0;
    finishCount = 0;
    MacroPart@[]@ filtered = {};
    @usedParts = GetUsedPartsDictionary();
    usedPartsCount = 0;
    @filterReasons = GetFilterReasonsDictionary();

    for(uint i = 0; i < allParts.Length; i++) {
        auto part = allParts[i];
        if(GenOptions::disabledParts.Find(part.ID) != -1) {
            filterReasons[part.ID] = "Part is disabled";
            continue;
        }
        auto isInDisabledFolder = false;
        for(uint j = 0; j < GenOptions::disabledFolders.Length; j++) {
            auto folder = GenOptions::disabledFolders[j];
            if(part.folder.StartsWith(folder)) {
                isInDisabledFolder = true;
                break;
            }
        }
        if(isInDisabledFolder) {
            filterReasons[part.ID] = "Part is in disabled set";
            continue;
        }
        if(GenOptions::disabledFolders.Find(part.folder) != -1) {
            filterReasons[part.ID] = "Part is disabled";
            continue;
        }
        if(part.type != EPartType::Start) {
            if(part.enterSpeed > GenOptions::maxSpeed || part.enterSpeed < GenOptions::minSpeed) {
                filterReasons[part.ID] = "Min or max speed filter: enter speed = " + part.enterSpeed;
                continue;
            }
        }
        if(part.type != EPartType::Finish) 
            if(part.exitSpeed > GenOptions::maxSpeed || part.exitSpeed < GenOptions::minSpeed) {
                filterReasons[part.ID] = "Min or max speed filter: exit speed = " + part.exitSpeed;
                continue;
            }
        if(!GenOptions::allowCustomItems && part.HasCustomItems) {
            filterReasons[part.ID] = "Part has custom items";
            continue;
        }
        if(!GenOptions::allowCustomBlocks && part.HasCustomBlocks) {
            filterReasons[part.ID] = "Part has custom blocks";
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
            continue;
        }
        if(!partHasIncludeTag){
            filterReasons[part.ID] = "Part does not include any of the required tags";
            continue;
        }
        if(GenOptions::difficulties.Find(part.difficulty) == -1) {
            filterReasons[part.ID] = "Part difficulty not in the difficulty filter";
            continue;
        }
        if(GenOptions::author != "" && GenOptions::author != part.author) {
            filterReasons[part.ID] = "Author mismatch";
            continue;
        }
        if(GenOptions::respawnable && !part.respawnable) {
            filterReasons[part.ID] = "Part is not respawnable";
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
    for(int i = int(filtered.Length - 1); i >= 0; i--) {
        auto part = filtered[i];
        if(IsUnconnectable(part, filtered)) {
            if(part.type == EPartType::Start)
                startCount--;
            if(part.type == EPartType::Finish)
                finishCount--;
            filterReasons[part.ID] = "Part can't connect to any other available parts";
            filtered.RemoveAt(i);
        }
    }
    if(startCount == 0) 
        warn("There are no start parts that fit the given filter.");
    if(finishCount == 0)
        warn("There are no finish parts that fit the given filter.");
        
    print("global filter");
    return filtered;
}

bool IsUnconnectable(MacroPart@ part, MacroPart@[]@ parts) {
        bool canConnectToOthers = false;
        bool othersCanConnectTo = false;
        // todo, create dictionary here of part->how many connection options that part has
        // for fancy algorithms
        for(uint j = 0; j < parts.Length; j++) {
            auto otherPart = parts[j];
            if(part.type == EPartType::Finish || (!canConnectToOthers && CanPartConnect(part, otherPart))) 
                canConnectToOthers = true;
            if(part.type == EPartType::Start || (!othersCanConnectTo && CanPartConnect(otherPart, part))) 
                othersCanConnectTo = true;
            if(canConnectToOthers && othersCanConnectTo)
                break;
        }
        // if no other part (including itsself) can connect to this part, then filter it out
        return !canConnectToOthers || !othersCanConnectTo;
}

void UpdateFilteredParts() {
    @filteredParts = GlobalFilterParts();
    if(filteredParts.Length == 0) {
        warn("Because of the set filters, there are no MacroParts to generate a track with!");
    }
}

void GenerateTrack() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
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

    generatedMapDuration = 0;
    triedParts = 0;

    print("Found " + filteredParts.Length + " available parts after global filter is applied.");

    // clear map for testing
    if(GenOptions::clearMap)
        MTG::ClearMap();

    lastYield = Time::Now;

    auto forceBefore = editor.PluginMapType.ForceMacroblockColor;
    auto colorBefore = editor.PluginMapType.NextMapElemColor;

    bool success = PlacePart();

    editor.PluginMapType.ForceMacroblockColor = forceBefore;
    editor.PluginMapType.NextMapElemColor = colorBefore;

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
    if(allParts is null){
        warn("allParts is null! shouldn't happen!");
        return result;
    }
    for(uint i = 0; i < allParts.Length; i++) {
        result.Set(allParts[i].ID, "");
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

MacroPart@[]@ FilterParts(MacroPart@ previousPart, const EPartType &in type) {
    MacroPart@[]@ filtered = {};
    for(uint i = 0; i < filteredParts.Length; i++) {
        auto part = filteredParts[i];
        if(part.type != type)
            continue;
        if(previousPart !is null && !CanPartConnect(previousPart, part)) 
            continue;
        filtered.InsertLast(part);
    }
    ShuffleParts(filtered);
    if(GenOptions::reuse == EReuse::PreferNoReuse) {
        filtered = Sort::SortParts(filtered, usedParts);
    }
    return filtered;
}

bool CanPartConnect(MacroPart@ partA, MacroPart@ partB) {
    if(GenOptions::noRepeats && partA.ID == partB.ID)
        return false;
    if(partB.type != EPartType::Start && GenOptions::considerSpeed && Math::Abs(partA.exitSpeed - partB.enterSpeed) > GenOptions::maxSpeedVariation)
        return false;
    if(partA.exitConnector != partB.entranceConnector)
        return false;
    if(GenOptions::reuse == EReuse::NoReuse && int(usedParts[partB.ID]) != 0)
        return false;
    if(filteredParts.Length > 0 && usedPartsCount > 0) {
        float meanPartUse = float(usedPartsCount) / filteredParts.Length;
        if(GenOptions::reuse == EReuse::PreferNoReuse && int(usedParts[partB.ID]) > meanPartUse * 3)
            return false;
    }
    return true;
}

bool Place(MacroPart@ part, DirectedPosition@ placePos) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;
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
        usedPartsCount++;
        generatedMapDuration += part.duration;
    }
    return placed;
}

void UnPlace(MacroPart@ part, DirectedPosition@ placePos) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    editor.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
    generatedMapDuration -= part.duration;
    usedParts[part.ID] = int(usedParts[part.ID]) - 1;
    usedPartsCount--;
}

bool PlacePart(DirectedPosition@ connectPoint = null, MacroPart@ previousPart = null) {
    if(canceled) return false;
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;
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
        type = generatedMapDuration + 7 > GenOptions::desiredMapLength ? EPartType::Finish: EPartType::Part;
    }
    auto possibleParts = FilterParts(previousPart, type);
    // print("possible parts length: " + possibleParts.Length);
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
                if(placePos is null) break;
                print("Test start pos: " + placePos.ToPrintString());
            }
            if(placePos is null) {
                warn("placePos is null!, part = " + part.ID);
                break;
            }
            triedParts++;
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
            finished = PlacePart(partEntrancePos, part);
            if(!finished && !canceled) {
                UnPlace(part, placePos);
                // print("Removing!");
                if(GenOptions::animate)
                    yield();
            }
            if(type != EPartType::Start || finished || canceled)
                break;
        }
        if(finished || canceled) break;
    }
    
    return finished;
}

}