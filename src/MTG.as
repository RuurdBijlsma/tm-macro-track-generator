namespace MTG {

void ClearMap() {
    auto editor = Editor();
    if(editor is null) return;    
    editor.PluginMapType.RemoveAllBlocks();
    // there may be items left in the map, remove as follows:
    if(editor.Challenge.AnchoredObjects.Length > 0) {
        auto placeMode = editor.PluginMapType.PlaceMode;
        CutMap();
        editor.PluginMapType.PlaceMode = placeMode;
    }
}

string GetTrackmaniaFolder() {
    return IO::FromUserGameFolder("");
}

string GetItemsFolder() { return IO::FromUserGameFolder("Items\\"); }

string GetBlocksFolder() { return IO::FromUserGameFolder("Blocks\\"); }

bool CutMap() {
    auto editor = Editor();
    if(editor is null) return false;
    editor.PluginMapType.CopyPaste_SelectAll();
    if(editor.PluginMapType.CopyPaste_GetSelectedCoordsCount() != 0) {
        editor.PluginMapType.CopyPaste_Cut();
        return true;
    }
    return false;
}

DirectedPosition@ GetNorthArrowFromRelativePosition(DirectedPosition@ absPosition, DirectedPosition@ relativePosition) {
    // absPosition is absolute position of entrance or exit of MacroPart
    // relativePosition is part.entrance or part.exit
    // we need different behaviour depending on the value of partPlacementDirection
    auto partPlacementDirection = CGameEditorPluginMap::ECardinalDirections((absPosition.direction - relativePosition.direction + 4) % 4);
    // north arrow is different depending on part placement direction, so calculation of north arrow also has to change
    if(partPlacementDirection == CGameEditorPluginMap::ECardinalDirections::South) {
        return DirectedPosition(
            absPosition.x + relativePosition.x,
            absPosition.y - relativePosition.y,
            absPosition.z + relativePosition.z,
            partPlacementDirection
        );
    } else if(partPlacementDirection == CGameEditorPluginMap::ECardinalDirections::West) {
        return DirectedPosition(
            absPosition.x - relativePosition.z,
            absPosition.y - relativePosition.y,
            absPosition.z + relativePosition.x,
            partPlacementDirection
        );
    } else if(partPlacementDirection == CGameEditorPluginMap::ECardinalDirections::East) {
        return DirectedPosition(
            absPosition.x + relativePosition.z,
            absPosition.y - relativePosition.y,
            absPosition.z - relativePosition.x,
            partPlacementDirection
        );
    } else if(partPlacementDirection == CGameEditorPluginMap::ECardinalDirections::North) {
        return DirectedPosition(
            absPosition.x - relativePosition.x,
            absPosition.y - relativePosition.y,
            absPosition.z - relativePosition.z,
            partPlacementDirection
        );
    }
    return null;
}

DirectedPosition@ NorthArrowToCursor(CGameCtnMacroBlockInfo@ macroblock, DirectedPosition@ northArrow) {
    auto size = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    if(northArrow.direction == CGameEditorPluginMap::ECardinalDirections::North) {
        return northArrow;
    }
    if(northArrow.direction == CGameEditorPluginMap::ECardinalDirections::East) {
        // without the +1 the cursor placement would be outside the box of the macroblock, which is incorrect
        return DirectedPosition(northArrow.x - size.z + 1, northArrow.y, northArrow.z, northArrow.direction);
    }
    if(northArrow.direction == CGameEditorPluginMap::ECardinalDirections::South) {
        // without the +1 the cursor placement would be outside the box of the macroblock, which is incorrect
        return DirectedPosition(northArrow.x - size.x + 1, northArrow.y, northArrow.z - size.z + 1, northArrow.direction);
    }
    if(northArrow.direction == CGameEditorPluginMap::ECardinalDirections::West) {
        // without the +1 the cursor placement would be outside the box of the macroblock, which is incorrect
        return DirectedPosition(northArrow.x, northArrow.y, northArrow.z - size.x + 1, northArrow.direction);
    }
    return null;
}

DirectedPosition@ ToAbsolutePosition(CGameCtnMacroBlockInfo@ macroblock, DirectedPosition@ mbPosition, DirectedPosition@ relativePosition) {
    DirectedPosition@ result = null;
    DirectedPosition@ northArrow = GetNorthArrow(macroblock, mbPosition);
    return DirectedPosition::Add(northArrow, relativePosition);
}

DirectedPosition@ GetNorthArrow(CGameCtnMacroBlockInfo@ macroblock, DirectedPosition@ mbPosition) {
    auto size = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::North) {
        return mbPosition;
    }
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::East) {
        // without the -1 the north arrow placement would be outside the box of the macroblock, which is incorrect
        return DirectedPosition(mbPosition.x + size.z - 1, mbPosition.y, mbPosition.z, mbPosition.direction);
    }
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::South) {
        // without the -1 the north arrow placement would be outside the box of the macroblock, which is incorrect
        return DirectedPosition(mbPosition.x + size.x - 1, mbPosition.y, mbPosition.z + size.z - 1, mbPosition.direction);
    }
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::West) {
        // without the -1 the north arrow placement would be outside the box of the macroblock, which is incorrect
        return DirectedPosition(mbPosition.x, mbPosition.y, mbPosition.z + size.x - 1, mbPosition.direction);
    }
    return null;
}

// get position of cursor position relative to macroblock's north arrow
DirectedPosition@ ToRelativePosition(CGameCtnMacroBlockInfo@ macroblock, DirectedPosition@ mbPosition, DirectedPosition@ cursor) {
    auto size = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    DirectedPosition@ northArrow = GetNorthArrow(macroblock, mbPosition);
    return DirectedPosition::Subtract(cursor, northArrow);
}

}