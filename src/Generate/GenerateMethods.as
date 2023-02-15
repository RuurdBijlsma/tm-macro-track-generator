namespace Generate {

class PlacedPart{
    MacroPart@ part; DirectedPosition@ position; int3 min; int3 max;
    PlacedPart(MacroPart@ part, DirectedPosition@ position, const int3 &in min, const int3 &in max) {
        @this.part = part;
        @this.position = position;
        this.min = min;
        this.max = max;
    }
};

string generateFailureReason = "";
bool initialized = false;
MacroPart@[]@ allParts = {};
MacroPart@[]@ filteredParts = {};
PlacedPart@[]@ generatedTrack = {};
bool isGenerating = false;
int lastYield = 0;
int startCount = 0;
int partCount = 0;
int finishCount = 0;
int usedPartsCount = 0;
dictionary@ usedParts = null;
dictionary@ filterReasons = null;
dictionary@ partsEntranceConnections = null;
dictionary@ partsExitConnections = null;
bool lastGenerateFailed = false;
bool canceled = false;
int generatedMapDuration = 0;
int triedParts = 0;
string[]@ deletedParts = {};
dictionary@ folders = null;
Parts::PartFolderTuple@[] rows = {};

void ResetState() {
    @allParts = {};
    @filteredParts = {};
    @folders = {};
    @usedParts = null;
    @partsEntranceConnections = null;
    @partsExitConnections = null;
    @generatedTrack = {};
    @filterReasons = null;
    @deletedParts = {};
    rows = {};
}

void Initialize() {
    @allParts = {};
    @filteredParts = {};
    @usedParts = null;
    @partsEntranceConnections = null;
    @partsExitConnections = null;
    @generatedTrack = {};
    @folders = {};
    @allParts = GetMacroParts();
    CheckEmbeddedItems();
    UpdateFilteredParts();
    CreatePartsListRows();
}

void CreatePartsListRows() {
    rows = {};
    auto folders = Generate::folders.GetKeys();
    auto rootIndex = folders.Find("");
    if(rootIndex != -1) {
        // Show parts not in folder first
        folders.RemoveAt(rootIndex);
        folders.InsertAt(0, "");
    }
    for(uint i = 0; i < folders.Length; i++) {
        auto folder = folders[i];
        MacroPart@[]@ parts;
        if(Generate::folders.Get(folder, @parts)) {
            if(folder != "") {
                auto folderTup = Parts::PartFolderTuple();
                folderTup.folder = folder;
                rows.InsertLast(folderTup);
            }

            for(uint j = 0; j < parts.Length; j++) {
                auto partTup = Parts::PartFolderTuple();
                @partTup.part = parts[j];
                rows.InsertLast(partTup);
            }
        }
    }
}

MacroPart@[] ExploreNode(CGameCtnArticleNodeDirectory@ node, const string &in folder = "") {
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
            
            MacroPart@[]@ parts = {};
            if(!folders.Exists(folder)) {
                folders.Set(folder, parts);
            } 
            @parts = cast<MacroPart@[]@>(folders[folder]);
            parts.InsertLast(macroPart);
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
            auto childNode = cast<CGameCtnArticleNodeDirectory@>(node.ChildNodes[j]);
            if(childNode is null) continue;
            for(uint k = 0; k < childNode.ChildNodes.Length; k++) {
                auto grandChildNode = cast<CGameCtnArticleNodeDirectory@>(childNode.ChildNodes[k]);
                if(grandChildNode is null) continue;
                if(grandChildNode.Name == macroPartFolder) {
                    macroParts = ExploreNode(grandChildNode);
                    break;
                }
            }
        }
    }

    return macroParts;
}

void CheckEmbeddedItems() {
    // If user is still in the process of answering the prompt, don't check again
    if(TMDialog::promptOpen) {
        warn("TMDialog::promptOpen");
        return;
    };
    if(allParts.Length == 0) {
        warn("All parts length = 0");
    };

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
                    if(buffer.GetSize() == 0) {
                        warn("Invalid buffer! Can't get item: " + relItemPath);
                        continue;
                    }
                    missingItems.InsertLast(relItemPath);
                    
                    auto folderParts = relItemPath.Split("\\");
                    auto folder = relItemPath.SubStr(0, relItemPath.Length - folderParts[folderParts.Length - 1].Length);
                    // print("Folder: " + folder);
                    // create folders recursive
                    MTG::CreateFolderRecursive(MTG::GetItemsFolder(), folder);
                    print("Part ID: " + part.ID + ", ItemPath: " + itemPath);
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
// #if DEPENDENCY_ITEMEXCHANGE
//     print("DEPENDENCY DETECTED");
//     startnew(AskImportItems, missingItems);
// #else
    print("DEPENDENCY NOT HERE");
    TMDialog::Alert("Some MacroParts contain custom items or blocks which are not yet loaded.", "Restart the game to be able to use these parts");
// #endif
    }
}

// void AskImportItems(ref@ missingItems) {
//     auto items = cast<string[]@>(missingItems);
//     print("All missing items can be imported!");
//     TMDialog::Confirm(
//         "Some MacroParts contain custom items which are not yet loaded.", 
//         "Import " + items.Length + " item"+(items.Length == 1 ? "" : "s")+" now using the ItemExchange plugin? Restarting the game also loads the items.", 
//         "Import now", "No");
//     while(TMDialog::promptOpen) yield();
//     print("Prompt closed with answer: " + TMDialog::promptResult);
//     if(TMDialog::promptResult) {
//         ItemExchange::ImportUnloadedItems();
//     }
// }

MacroPart@[]@ GlobalFilterParts() {
    startCount = 0;
    partCount = 0;
    finishCount = 0;
    MacroPart@[]@ filtered = {};
    @usedParts = GetUsedPartsDictionary();
    usedPartsCount = 0;
    @filterReasons = GetFilterReasonsDictionary();
    @partsEntranceConnections = GetConnectionsDictionary();
    @partsExitConnections = GetConnectionsDictionary();

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
        int entrance = 0;
        int exit = 0;
        // todo, create dictionary here of part->how many connection options that part has
        // for fancy algorithms
        for(uint j = 0; j < parts.Length; j++) {
            auto otherPart = parts[j];
            if(part.type == EPartType::Finish || CanPartConnect(part, otherPart))
                exit++;
            if(part.type == EPartType::Start || CanPartConnect(otherPart, part))
                entrance++;
            // if(canConnectToOthers && othersCanConnectTo)
            //     break;
        }
        partsEntranceConnections[part.ID] = entrance;
        partsExitConnections[part.ID] = exit;
        // if no other part (including itsself) can connect to this part, then filter it out
        return entrance == 0 || exit == 0;
}

void UpdateFilteredParts() {
    @filteredParts = GlobalFilterParts();
    if(filteredParts.Length == 0) {
        warn("Because of the set filters, there are no MacroParts to generate a track with!");
    }
}

CGameCtnEditorCommon@ editorHandle = null;
void GenerateTrack() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    if(isGenerating) return;
    auto now = Time::Now;

    if(allParts.Length == 0) {
        warn("No MacroParts found to generate a track with!");
        return;
    }
    lastGenerateFailed = false;
    @editorHandle = editor;
    
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


    bool success = PlacePart();
    if(success) {
        auto forceBefore = editor.PluginMapType.ForceMacroblockColor;
        auto colorBefore = editor.PluginMapType.NextMapElemColor;
        // color map and check for deleted blocks
        bool valid = RePlaceTrack();
        if(!valid) {
            generateFailureReason = "Some blocks along the route were destroyed.";
            success = false;
            Warn("Some blocks along the route were accidentally destroyed.");
        }
        editor.PluginMapType.ForceMacroblockColor = forceBefore;
        editor.PluginMapType.NextMapElemColor = colorBefore;
    } else {
        generateFailureReason = "Track failed to generate!";
    }

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
    @editorHandle = null;

    print("Generating track took " + (Time::Now - now) + "ms");
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

dictionary GetConnectionsDictionary() {
    dictionary result;
    for(uint i = 0; i < allParts.Length; i++) {
        result.Set(allParts[i].ID, 0);
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
    bool placed;
    if(GenOptions::airMode) {
        placed = editorHandle.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, placePos.position, placePos.direction);
    } else {
        placed = editorHandle.PluginMapType.PlaceMacroblock_NoTerrain_NoUnvalidate(part.macroblock, placePos.position, placePos.direction);
    }
    if(placed) {
        generatedTrack.InsertLast(PlacedPart(part, placePos, placePos.position, part.GetFarBound(placePos)));
        usedParts[part.ID] = int(usedParts[part.ID]) + 1;
        usedPartsCount++;
        generatedMapDuration += part.duration;
    }
    return placed;
}

void UnPlace(MacroPart@ part, DirectedPosition@ placePos) {
    editorHandle.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
    
    generatedTrack.RemoveLast();
    usedParts[part.ID] = int(usedParts[part.ID]) - 1;
    usedPartsCount--;
    generatedMapDuration -= part.duration;
}

bool PlacePart(DirectedPosition@ connectPoint = null, MacroPart@ previousPart = null) {
    if(canceled) return false;
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
        type = generatedMapDuration + 3 > GenOptions::desiredMapLength ? EPartType::Finish: EPartType::Part;
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
            }
            if(placePos is null) {
                warn("placePos is null!, part = " + part.ID);
                break;
            }
            triedParts++;
            bool placed = Place(part, placePos);
            if(!placed)
                break;
            if(GenOptions::ensureTrackIntegrity) {
                // Fix track in case it broke
                bool valid = CheckPartPlacement(part, placePos);
                if(!valid) { 
                    UnPlace(part, placePos);
                    break;
                }
            }
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

// Check for broken parts near recently placed part
// returns true if a broken part was found and replaced
bool CheckPartPlacement(MacroPart@ part, DirectedPosition@ placePos) {
    auto now = Time::Now;
    PlacedPart@[]@ intersectingParts = {};

    // Unplace every block with intersecting bounding box
    for(uint i = 0; i < generatedTrack.Length; i++) {
        auto gt = generatedTrack[i];
        auto intersects = MTG::IntersectsBounds(gt.min, gt.max, placePos.position, part.GetFarBound(placePos));
        if(intersects) {
            editorHandle.PluginMapType.RemoveMacroblock(gt.part.macroblock, gt.position.position, gt.position.direction);
            intersectingParts.InsertLast(gt);
            if(GenOptions::animate) yield();
        }
    }

    // Place every block with intersecting bounding box
    for(uint i = 0; i < intersectingParts.Length; i++) {
        auto gt = intersectingParts[i];

        bool placed;
        if(GenOptions::airMode) {
            placed = editorHandle.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, placePos.position, placePos.direction);
        } else {
            placed = editorHandle.PluginMapType.PlaceMacroblock_NoTerrain_NoUnvalidate(part.macroblock, placePos.position, placePos.direction);
        }
        if(GenOptions::animate) yield();
        if(!placed) {
            warn("[CHECK] Found problem while placing track part, part: " + gt.part.ID + ", pos: " + gt.position.ToString());
            return false;
        }
    }
    print("Checked "+intersectingParts.Length+" parts, " + (Time::Now - now) + "ms");
    return true;
}

// Fix broken parts and color the track
bool RePlaceTrack() {
    auto now = Time::Now;
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;
    if(generatedTrack.Length < 2) return false;

    CGameEditorPluginMap::EMapElemColor color;
    if(GenOptions::color == 6) { // random color
        color = CGameEditorPluginMap::EMapElemColor(availableColors[Random::Int(0, availableColors.Length)]);
    } else {
        color = CGameEditorPluginMap::EMapElemColor(GenOptions::color);
    }
    editor.PluginMapType.ForceMacroblockColor = GenOptions::forceColor;

    // Unplace
    for(uint i = 0; i < generatedTrack.Length; i++) {
        auto part = generatedTrack[i].part;
        auto placePos = generatedTrack[i].position;
        editor.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
        if(GenOptions::animate) sleep(30);
    }

    // Place
    int currentDuration = 0;
    for(uint i = 0; i < generatedTrack.Length; i++) {
        auto part = generatedTrack[i].part;
        auto placePos = generatedTrack[i].position;
        
        if(GenOptions::forceColor) {
            if(GenOptions::autoColoring) {
                auto percentage = Math::Clamp(float(currentDuration + part.duration / 2) / float(GenOptions::desiredMapLength), 0, .999999);
                color = CGameEditorPluginMap::EMapElemColor(availableColors[1 + int((availableColors.Length - 2) * percentage)]);
            }
            editor.PluginMapType.NextMapElemColor = color;
        }
        currentDuration += part.duration;

        bool placed;
        if(GenOptions::airMode) {
            placed = editor.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, placePos.position, placePos.direction);
        } else {
            placed = editor.PluginMapType.PlaceMacroblock_NoTerrain_NoUnvalidate(part.macroblock, placePos.position, placePos.direction);
        }
        if(!placed) {
            warn("[REPLACE] Oops something went wrong replacing each track part, part: " + part.ID + ", pos: " + placePos.ToString());
            return false;
        }
        if(GenOptions::animate) 
            sleep(30);
    }
    print("Replaced track " + (Time::Now - now) + "ms");
    return true;
}

}