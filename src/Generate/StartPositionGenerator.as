class StartPositionGenerator {
    CGameCtnMacroBlockInfo@ macroblock;
    nat3 mapSize;
    int startX;
    int startY;
    int startZ;
    uint resumeI;
    SpiralOut@ spiral;

    int i = 0;
    StartPositionGenerator(MacroPart@ part) {
        auto editor = Editor();
        if(editor is null || editor.PluginMapType is null) return;
        @macroblock = part.macroblock;
        auto macroblockSize = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
        // todo change placdir
        mapSize = editor.Challenge.Size;
        startX = mapSize.x / 2 - macroblockSize.x / 2;
        startY = int(Math::Round(mapSize.y * GenOptions::startHeight));
        startZ = mapSize.z / 2 - macroblockSize.z / 2;
        @spiral = SpiralOut();
        resumeI = 0;
    }

    DirectedPosition@ Next() {
        auto editor = Editor();
        if(editor is null || editor.PluginMapType is null) return null;
        DirectedPosition@ placePoint = null;
        while(true) {
            auto placeDir = CGameEditorPluginMap::ECardinalDirections(i % 4);
            auto x = startX + spiral.x;
            auto z = startZ + spiral.y;
            for(uint i = resumeI; i < mapSize.y * 2; i++) {
                int y = startY + int(Math::Round((i % 2 == 0) ? i * 0.5 : i * -0.5));
                if(y >= int(mapSize.y) || y < 1) continue;
                auto tryPlace = DirectedPosition(x, y, z, placeDir);
                auto canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, tryPlace.position, tryPlace.direction);
                if(canPlace) {
                    resumeI = i + 1;
                    @placePoint = tryPlace;
                    break;
                }
            }
            if(placePoint is null) {
                // couldn't place mb at any height at current x,z coord
                resumeI = 0;
                if(++i % 4 == 0)
                    spiral.GoNext();
            } else {
                break;
            }
            if(spiral.layer > int(mapSize.x)) {
                warn("Could not find starting position for track");
                break;
            }
        }
        return placePoint;
    }
};