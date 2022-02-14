namespace Generate {

// Get MacroParts from macro folder
MacroPart@[] GetMacroParts() {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
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
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    auto mapSize = editor.Challenge.Size;
    auto macroblockSize = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    auto placeDir = CGameEditorPluginMap::ECardinalDirections::West;
    auto startX = (mapSize.x / 2) - macroblockSize.x;
    auto startZ = (mapSize.z / 2) - macroblockSize.z;
    auto spiral = SpiralOut();

    while(true) {
        auto x = startX + spiral.x;
        auto z = startZ + spiral.y;
        for(uint y = 0; y < mapSize.y; y++) {
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
    auto macroParts = GetMacroParts();
    if(macroParts.Length == 0) {
        warn("No MacroParts found to generate a track with!");
        return;
    }
    
    for(uint i = 0; i < macroParts.Length; i++) {
        print(macroParts[i].ToString());
    }

    MacroPart@[] startParts;
    MacroPart@[] parts;
    MacroPart@[] finishParts;
    for(uint i = 0; i < macroParts.Length; i++) {
        if(macroParts[i].type == EPartType::Start) {
            startParts.InsertLast(macroParts[i]);
        } else if(macroParts[i].type == EPartType::Part) {
            parts.InsertLast(macroParts[i]);
        } else if(macroParts[i].type == EPartType::Finish) {
            finishParts.InsertLast(macroParts[i]);
        }
    }

    print("startParts.length: " + startParts.Length);
    print("parts.length: " + parts.Length);
    print("finishParts.length: " + finishParts.Length);
    ShuffleParts(parts);
}

void RenderInterface() {
    
}

}