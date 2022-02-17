namespace Create {
    
enum EState {
    Idle,
    SelectBlocks,
    SelectPlacement,
    SelectEntrance,
    SelectExit,
    ConfirmItems,
    EnterDetails,
    SavedConfirmation,
    Failed
};

EState state = EState::Idle;
bool isEditing = false;
bool copiedMap = false;
bool changedSaveAsFilename = false;

DirectedPosition@ macroPlace = null;
MacroPart@ partDetails = null;
string mbPath = "";

EPartType entranceType = EPartType::Part;
EPartType exitType = EPartType::Part;


bool OnKeyPress(bool down, VirtualKey key) {
    if(state == EState::SelectPlacement && key == VirtualKey::V && down) {
        return PlaceUserMacroblockAtCursor();
    }

    return false;
}

bool OnMouseButton(bool down, int button, int x, int y) {
    auto isFreeLook = editor.PluginMapType.EditMode == CGameEditorPluginMap::EditMode::FreeLook;
    if(!isEditing && state == EState::SelectPlacement && button == 0 && down && !isFreeLook) {
        return PlaceUserMacroblockAtCursor();
    }

    if(state == EState::SelectEntrance && button == 0 && down && !isFreeLook) {
        auto coord = editor.PluginMapType.CursorCoord;
        auto absEntrance = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.entrance = MTG::ToRelativePosition(partDetails.macroblock, macroPlace, absEntrance);
        print("Entrance relative: " + partDetails.entrance.ToPrintString());
        state = EState::SelectExit;
        windowColor = vec4(35./255, 1./255, 1./255, 1);
        return true;
    }
    if(state == EState::SelectExit && button == 0 && down && !isFreeLook) {
        auto coord = editor.PluginMapType.CursorCoord;
        auto absExit = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.exit = MTG::ToRelativePosition(partDetails.macroblock, macroPlace, absExit);
        print("Exit relative: " + partDetails.exit.ToPrintString());

        editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
        // Detect items in macroblock
        auto anchoredObjects = editor.Challenge.AnchoredObjects;
        for(uint i = 0; i < anchoredObjects.Length; i++) {
            auto itemPath = anchoredObjects[i].ItemModel.IdName;
            if(itemPath.EndsWith(".Item.Gbx") && partDetails.embeddedItems.Find(itemPath) == -1){
                partDetails.embeddedItems.InsertLast(itemPath);
            }
        }
        auto blocks = editor.Challenge.Blocks;
        for(uint i = 0; i < blocks.Length; i++) {
            auto article = cast<CGameCtnArticle@>(blocks[i].BlockInfo.ArticlePtr);
            if(article is null || article.BlockItem_ItemModelArticle is null) continue;
            auto blockPath = article.BlockItem_ItemModelArticle.IdName;
            if(blockPath.EndsWith(".Block.Gbx") && partDetails.embeddedItems.Find(blockPath) == -1)
                partDetails.embeddedItems.InsertLast(blockPath);
        }
        if(copiedMap) {
            // get back original map & remove placed macroblock
            editor.PluginMapType.Undo();
        } else {
            // remove placed macroblock
            editor.PluginMapType.Undo();
            editor.PluginMapType.Redo();
        }

        // clear any accidentally selected coords
        editor.PluginMapType.CustomSelectionCoords.RemoveRange(0, editor.PluginMapType.CustomSelectionCoords.Length);
        editor.PluginMapType.HideCustomSelection();
        // set type from detected blocks
        partDetails.type = entranceType;
        if(exitType != EPartType::Part)
            partDetails.type = exitType;
        if(partDetails.embeddedItems.Length == 0) {
            state = EState::EnterDetails;
        } else {
            state = EState::ConfirmItems;
        }
        windowColor = baseWindowColor;
        return true;
    }

    return false;
}

bool BlockFitsInDirection(CGameCtnBlock@ block,  CGameCtnBlockInfo@ otherBlock, CGameEditorPluginMap::ECardinalDirections direction) {
    if(block is null || otherBlock is null) return false;
    editor.PluginMapType.GetConnectResults(block, otherBlock);
    auto results = editor.PluginMapType.ConnectResults;
    for(uint i = 0; i < results.Length; i++) {
        if(results[i].Dir == direction) {
            if(results[i].CanPlace)
                return true;
            break;
        }
    }
    return false;
}

EConnector GetConnector(CGameCtnBlock@ block, CGameEditorPluginMap::ECardinalDirections cursorDirection, bool isExit = false) {
    if(block is null) return EConnector::Platform;
    auto blockInfo = block.BlockInfo;
    if(blockInfo is null || !blockInfo.PageName.Contains('/')) return EConnector::Platform;

    // Try finding connection result with GetConnectResults
    CGameCtnBlockInfo@[] testBlocks = {
        editor.PluginMapType.GetBlockModelFromName('RoadTechStraight'),
        editor.PluginMapType.GetBlockModelFromName('RoadDirtStraight'),
        editor.PluginMapType.GetBlockModelFromName('RoadBumpStraight'),
        editor.PluginMapType.GetBlockModelFromName('RoadIceStraight'),
        editor.PluginMapType.GetBlockModelFromName('PlatformTechBase')
    };
    EConnector[] correspondingConnectors = {
        EConnector::Platform,
        EConnector::RoadDirt,
        EConnector::RoadBump,
        EConnector::RoadIce,
        EConnector::Platform
    };
    for(uint i = 0; i < testBlocks.Length; i++) {
        auto reverseDirection = CGameEditorPluginMap::ECardinalDirections((cursorDirection + 2) % 4);
        auto fit = BlockFitsInDirection(block, testBlocks[i], isExit ? cursorDirection : reverseDirection);
        if(fit) 
            return correspondingConnectors[i];
    }

    // If nothing was found, try finding connection result by looking at block type
    auto rootPage = string(blockInfo.PageName).Split('/')[0];
    if(rootPage == 'RoadDirt')
        return EConnector::RoadDirt;
    if(rootPage == 'RoadBump')
        return EConnector::RoadBump;
    if(rootPage == 'RoadIce')
        return EConnector::RoadIce;
    if(rootPage == 'Walls')
        return EConnector::DecoWall;

    // all other types are platform (road/platform/technics/terrain/water)
    return EConnector::Platform;
}

string[]@ GetTags(CGameCtnBlockInfo@ blockInfo) {
    string[]@ result = {};
    if(blockInfo is null || !blockInfo.PageName.Contains('/')) return result;
    auto rootPage = string(blockInfo.PageName).Split('/')[0];
    if(rootPage == 'RoadTech')
        result.InsertLast("Tech");
    if(rootPage == 'RoadDirt')
        result.InsertLast("Dirt");
    if(rootPage == 'RoadBump') {
        result.InsertLast("Tech");
        result.InsertLast("Road Bump");
    }
    if(rootPage == 'RoadIce') {
        result.InsertLast("Bobsleigh");
        result.InsertLast("Ice");
    }
    if(rootPage == 'PlatformTech')
        result.InsertLast("FullSpeed");
    if(rootPage == 'PlatformDirt')
        result.InsertLast("Dirt");
    if(rootPage == 'PlatformIce')
        result.InsertLast("Ice");
    if(rootPage == 'PlatformGrass')
        result.InsertLast("Grass");
    if(rootPage == 'PlatformPlastic')
        result.InsertLast("Plastic");
    if(rootPage == 'Water')
        result.InsertLast("Water");
    if(rootPage == 'Walls')
        result.InsertLast("Tech");
    return result;
}

bool PlaceUserMacroblockAtCursor() {
    if(isEditing) {
        if(editor.CurrentMacroBlockInfo is null) 
            return false;
        @partDetails = MacroPart::FromMacroblock(editor.CurrentMacroBlockInfo);
        if(partDetails is null) {
            warn("MacroPart selected for editing is invalid.");
            @partDetails = MacroPart();
            @partDetails.macroblock = editor.CurrentMacroBlockInfo;
        }
    }
    print("Click place!");
    auto coord = editor.PluginMapType.CursorCoord;
    @macroPlace = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
    // placeusermacroblock changes state, so this doesn't get repeatedly called
    PlaceUserMacroblock(macroPlace);
    return true;
}

void PlaceUserMacroblock(DirectedPosition@ dirPos) {
    copiedMap = MTG::CutMap();
    if(dirPos is null) {
        state = EState::Failed;
        failureReason = "Failed to find placement position for macro.";
        warn("Failed to place macro!");
    } else {
        editor.PluginMapType.PlaceMacroblock_AirMode(partDetails.macroblock, dirPos.position, dirPos.direction);
        state = EState::SelectEntrance;
        windowColor = vec4(1./255, 30./255, 1./255, 1);
    }
}

void SelectNewMacroblock() {
    auto maxWait = 1000;
    while(true) {
        auto mbPathW = wstring("Stadium\\" + mbPath.Replace('/', '\\')) + ".Macroblock.Gbx";
        print(mbPathW);
        auto mb = editor.PluginMapType.GetMacroblockModelFromFilePath(mbPathW);
        print("Mb isnull? " + (mb is null));
        if(maxWait-- < 0) {
            failureReason = "Failed to get newly saved macroblock";
            state = EState::Failed;
            break;
        }
        if(mb !is null) {
            state = EState::SelectPlacement;
            @partDetails.macroblock = mb;
            break;
        };
        yield();
    }
}

void RenameMacroblock(CGameCtnMacroBlockInfo@ macroblock, string newName) {
    if(macroblock is null) return;
    string oldRelPath = macroblock.IdName;
    print("oldPath: " + oldRelPath);
    macroblock.IdName = "Stadium\\" + macroPartFolder + "\\" + newName + ".Macroblock.Gbx";
    print("newPath: " + macroblock.IdName);
    editor.PluginMapType.SaveMacroblock(macroblock);
    auto oldPath = MTG::GetBlocksFolder() + oldRelPath;
    if(IO::FileExists(oldPath)) {
        print("Deleting " + oldPath);
        IO::Delete(oldPath);
    }
}

void SaveMacroPart(MacroPart@ part) {
    string base64Items = "";
    for(uint i = 0; i < part.embeddedItems.Length; i++) {
        auto relItemPath = part.embeddedItems[i];
        auto itemPath = MTG::GetItemsFolder() + relItemPath;
        print("itemPath: " + itemPath);
        IO::File file(itemPath);
        file.Open(IO::FileMode::Read);
        auto buffer = file.Read(file.Size());
        file.Close();
        // base64 does not use |, so use it as separator again
        if(i != 0) base64Items += MacroPart::DetailSeparator;
        base64Items += buffer.ReadToBase64(buffer.GetSize());
    }
    part.macroblock.Description = part.ToString() + MacroPart::BaseSeparator + base64Items;
    editor.PluginMapType.SaveMacroblock(part.macroblock);
    RenameMacroblock(part.macroblock, "MTG-" + part.author + "-" + part.name);
}

}