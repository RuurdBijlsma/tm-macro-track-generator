namespace Generate {

MacroPart@[]@ allParts = {};

void Initialize() {
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

void GenerateTrack() {
    if(allParts.Length == 0) {
        warn("No MacroParts found to generate a track with!");
        return;
    }

    // clear map for testing
    editor.PluginMapType.RemoveAllBlocks();

    // Random::SetSeed("OPENPLANET");
    // PlacePart();

    auto starts = FilterParts(EPartType::Start);
}

MacroPart@[]@ FilterParts(const EPartType &in type) {
    MacroPart@[]@ filtered = {};
    for(uint i = 0; i < allParts.Length; i++) {
        if(allParts[i].type == type) {
            filtered.InsertLast(allParts[i]);
        }
    }
    ShuffleParts(filtered);
    return filtered;
}

bool PlacePart(DirectedPosition@ connectPoint = null, int mbPlaced = 0) {
    EPartType type;
    if(connectPoint is null) {
        type = EPartType::Start;
    } else {
        type = mbPlaced > 2 ? EPartType::Finish: EPartType::Part;
    }
    MacroPart@[]@ possibleParts = FilterParts(type);
    bool finished = false;

    for(uint i = 0; i < possibleParts.Length; i++) {
        auto part = possibleParts[i];
        DirectedPosition@ placePos = null;
        if(type == EPartType::Start) {
            @placePos = FindStartPosition(part.macroblock);
            if(placePos is null) 
                continue;
        } else {
            print("connectPoint: " + connectPoint.ToPrintString());
            auto northArrow = MTG::GetNorthArrowFromRelativePosition(connectPoint, part.entrance);
            print("northArrow: " + northArrow.ToPrintString());
            @placePos = MTG::NorthArrowToCursor(part.macroblock, northArrow);
            print("placePos: " + placePos.ToPrintString());
        }
        auto canPlace = editor.PluginMapType.CanPlaceMacroblock(part.macroblock, placePos.position, placePos.direction);
        print("Can place " + part.name + " at " + placePos.ToPrintString() + "?: " + canPlace + ". mbPlaced = " + mbPlaced);
        if(!canPlace) 
            continue;
        auto placed = editor.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, placePos.position, placePos.direction);
        if(!placed)
            continue;
        if(type == EPartType::Finish) {
            return true;
        }
        auto partEntrancePos = MTG::ToAbsolutePosition(part.macroblock, placePos, part.exit);
        partEntrancePos.MoveForward();
        finished = PlacePart(partEntrancePos, mbPlaced + 1);
        if(finished) {
            print("Finished!");
            break;
        } else {
            print("Removing!");
            editor.PluginMapType.RemoveMacroblock(part.macroblock, placePos.position, placePos.direction);
        }
    }
    
    return finished;
}

}