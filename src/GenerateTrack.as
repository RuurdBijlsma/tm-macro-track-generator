class Generate {
    MacroPart@[]@ allParts = {};
    CGameCtnEditorCommon@ editor;
    CGameCtnApp@ app;
    Generate() {
        @allParts = GetMacroParts();
        @app = GetApp();
        @editor = cast<CGameCtnEditorCommon>(app.Editor);
    }

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
        Create::CutMap();

        auto starts = FilterParts(EPartType::Start);
        auto parts = FilterParts(EPartType::Part);
        auto start = starts[0];
        auto part = parts[1];
        print("Trying to connect start: " + start.name + " + part: " + part.name);

        auto startPos = FindStartPosition(start.macroblock);
        editor.PluginMapType.PlaceMacroblock_AirMode(start.macroblock, startPos.position, startPos.direction);
        auto startExitPos = ToAbsolutePosition(start.macroblock, startPos, start.exit);

        auto partEntrancePos = DirectedPosition(startExitPos.x, startExitPos.y, startExitPos.z, startExitPos.direction);
        // shift 1 forward to get entrance position of next part
        partEntrancePos.MoveForward();
        print("part entrance pos: " + partEntrancePos.ToString());
        print("part rel start pos: " + part.entrance.ToString());
        auto partPlacementDirection = CGameEditorPluginMap::ECardinalDirections((partEntrancePos.direction - part.entrance.direction + 4) % 4);
        print(tostring(partPlacementDirection));

        // we need different behaviour depending on the value of partPlacementDirection
        auto northArrow = DirectedPosition::Subtract(partEntrancePos, part.entrance);
        print("northArrow: " + northArrow.ToString());
    }

    DirectedPosition@ ToAbsolutePosition(CGameCtnMacroBlockInfo@ macroblock, DirectedPosition@ mbPosition, DirectedPosition@ relativePosition) {
        DirectedPosition@ result = null;
        DirectedPosition@ northArrow = Create::GetNorthArrow(macroblock, mbPosition);
        return DirectedPosition::Add(northArrow, relativePosition);
    }

    MacroPart@[]@ FilterParts(const EPartType &in type) {
        MacroPart@[]@ filtered = {};
        for(uint i = 0; i < allParts.Length; i++) {
            if(allParts[i].type == type) {
                filtered.InsertLast(allParts[i]);
            }
        }
        // ShuffleParts(filtered);
        return filtered;
    }














    // bool PlacePart(DirectedPosition@ connectPoint = null) {
    //     EPartType type;
    //     if(connectPoint is null) {
    //         type = EPartType::Start;
    //     } else {
    //         type = EPartType::Part;
    //     }
    //     MacroPart@[]@ possibleParts = FilterParts(type);
    //     bool finished = false;

    //     for(uint i = 0; i < possibleParts.Length; i++) {
    //         auto part = possibleParts[i];
    //         if(type == EPartType::Start) {
    //             @connectPoint = FindStartPosition(part.macroblock);
    //             if(connectPoint is null) 
    //                 continue;
    //         }
    //         auto placePoint = ToRelativePosition(connectPoint, part.entrance);
    //         auto canPlace = editor.PluginMapType.CanPlaceMacroblock(part.macroblock, connectPoint.position, connectPoint.direction);
    //         if(!canPlace) 
    //             continue;
    //         auto placed = editor.PluginMapType.PlaceMacroblock_AirMode(part.macroblock, connectPoint.position, connectPoint.direction);
    //         if(!placed)
    //             continue;
    //         auto newConnectPoint = ToRelativePosition(connectPoint, part.entrance);
    //         if(newConnectPoint.direction == CGameEditorPluginMap::ECardinalDirections::North)
    //             newConnectPoint.z += 1;
    //         else if(newConnectPoint.direction == CGameEditorPluginMap::ECardinalDirections::East)
    //             newConnectPoint.x -= 1;
    //         else if(newConnectPoint.direction == CGameEditorPluginMap::ECardinalDirections::South)
    //             newConnectPoint.z -= 1;
    //         else if(newConnectPoint.direction == CGameEditorPluginMap::ECardinalDirections::West)
    //             newConnectPoint.x += 1;
    //         finished = PlacePart(newConnectPoint);
    //         if(finished) {
    //             break;
    //         } else {
    //             // editor.PluginMapType.Undo();
    //             return false;
    //         }
    //     }
        
    //     return finished;
    // }
};