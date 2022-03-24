namespace MTG {

bool IntersectsBounds(const int3 &in minA, const int3 &in maxA, const int3 &in minB, const int3 &in maxB) {
    return (minA.x <= maxB.x && maxA.x >= minB.x) 
        && (minA.y <= maxB.y && maxA.y >= minB.y) 
        && (minA.z <= maxB.z && maxA.z >= minB.z);
}

void CheckMacroParts() {
    auto mbsPath = MTG::GetBlocksFolder() + "Stadium\\" + macroPartFolder + "\\";
    if(IO::FolderExists(mbsPath)){
        return;
    }
    IO::CreateFolder(mbsPath);
    // copy parts over
    IO::FileSource indexFile("./MacroParts/index.txt");
    while(true) {
        auto line = indexFile.ReadLine();
        if(line == "") break;
        try {
            IO::FileSource partFile = IO::FileSource(".\\MacroParts\\" + line);
            auto buffer = partFile.Read(partFile.Size());
            auto lineParts = line.Split("\\");
            auto fileType = lineParts[0];
            auto relFile = line.SubStr(fileType.Length);
            print("RelFile: " + relFile);
            auto relFolder = relFile.SubStr(0, relFile.Length - lineParts[lineParts.Length - 1].Length);
            if(fileType == "Parts") {
                print("Copying MacroPart from zip: " + relFile);
                if(!IO::FolderExists(mbsPath + relFolder))
                    CreateFolderRecursive(mbsPath, relFolder);
                IO::File toFile(mbsPath + relFile, IO::FileMode::Write);
                toFile.Write(buffer);
                toFile.Close();
            } else if(fileType == "Items") {
                print("Copying Item from zip: " + relFile);
                auto itemsPath = GetItemsFolder();
                if(!IO::FolderExists(itemsPath + relFolder))
                    CreateFolderRecursive(itemsPath, relFolder);
                IO::File toFile(itemsPath + relFile, IO::FileMode::Write);
                toFile.Write(buffer);
                toFile.Close();
            }
        } catch {
            warn("Invalid part in parts-index.txt: " + line);
        }
    }
    TMDialog::Alert("You need to restart the game before being able to generate random tracks.", "Included parts must be loaded into the editor, which requires a restart.");
}

MacroPart@ PartFromID(string ID) {
    for(uint i = 0; i < Generate::allParts.Length; i++) {
        if(Generate::allParts[i].ID == ID) {
            return Generate::allParts[i];
        }
    }
    return null;
}

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
        print("Map has been cut!");
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
    if(macroblock.GeneratedBlockInfo is null) {
        return null;
    }
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

void CreateFolderRecursive(string basePath, string createPath){
    string separator = "/";
    basePath.Replace("\\", separator);
    createPath.Replace("\\", separator);
    // remove double //
    while(basePath.Contains(separator + separator)){
        basePath = basePath.Replace(separator + separator, separator);
    }
    while(createPath.Contains(separator + separator)){
        createPath = createPath.Replace(separator + separator, separator);
    }
    // Format path to the following template
    // basePath: C://Users/Ruurd/ (ends with separator)
    // createPath: OpenplanetNext/Plugins/lib (no separator at start or end)
    if(basePath.EndsWith(separator)){
        basePath = basePath.SubStr(0, basePath.Length - 1);
    }
    if(createPath.StartsWith(separator)) {
        createPath = createPath.SubStr(1);
    }
    if(createPath.EndsWith(separator)) {
        createPath = createPath.SubStr(0, createPath.Length - 1);
    }
    auto parts = createPath.Split(separator);

    string path = basePath;
    for(uint i = 0; i < parts.Length; i++) {
        if(!IO::FolderExists(path + separator + parts[i])) {
            IO::CreateFolder(path + separator + parts[i]);
        }
        path += separator + parts[i];
    }
}
}
