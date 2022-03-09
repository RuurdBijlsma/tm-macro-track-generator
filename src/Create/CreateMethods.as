namespace Create {
    
enum EState {
    Idle,
    EditBlocks,
    SelectBlocks,
    SelectPlacement,
    SelectEntrance,
    SelectExit,
    ConfirmItems,
    EnterDetails,
    SavedConfirmation,
    AirMode,
    Failed
};

EState state = EState::Idle;
string editingFilename = "";
bool isEditing = false;
bool copiedMap = false;
bool changedSaveAsFilename = false;

DirectedPosition@ macroPlace = null;
MacroPart@ partDetails = null;
string mbPath = "";

EPartType entranceType = EPartType::Part;
EPartType exitType = EPartType::Part;
// for select entrance/exit UI:
CGameCtnBlock@ blockInfo = null;
string[]@ detectedTags = null;

void Update() {
    auto app = GetApp();
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    if(state == EState::SelectBlocks || state == EState::EditBlocks){
        // wait for macroblock save
        auto currentFrame = app.BasicDialogs.Dialogs.CurrentFrame;
        if(currentFrame !is null && currentFrame.IdName == 'FrameDialogSaveAs') {
            if(!changedSaveAsFilename) {
                changedSaveAsFilename = true;
                startnew(SelectNewMacroblock);
            }
        }
    }
    if(state == EState::SelectEntrance || state == EState::SelectExit) {
        bool entrance = state == EState::SelectEntrance;
        auto c = editor.PluginMapType.CursorCoord;
        @blockInfo = editor.PluginMapType.GetBlock(int3(c.x, c.y, c.z));

        if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection)
            editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
        
        EConnector connector = EConnector::Platform;
        EPartType type = EPartType::Part;
        @detectedTags = null;
        if(blockInfo !is null) {
            connector = GetConnector(blockInfo, editor.PluginMapType.CursorDir);
            @detectedTags = GetTags(blockInfo.BlockInfo);
            partDetails.AddTags(detectedTags);
            if(entrance && blockInfo.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::Start) {
                type = EPartType::Start;
            } else if(!entrance && blockInfo.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::Finish) {
                type = EPartType::Finish;
            } else if(blockInfo.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::StartFinish) {
                type = EPartType::Multilap;
            } else {
                type = EPartType::Part;
            }
        }
        if(entrance){
            entranceType = type;
            partDetails.entranceConnector = connector;
        } else {
            exitType = type;
            partDetails.exitConnector = connector;
        }
    }
}

bool OnKeyPress(bool down, VirtualKey key) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;

    if(state == EState::AirMode && key == VirtualKey::V && down) {
        if(editor.CurrentMacroBlockInfo is null) 
            return false;
        auto coord = editor.PluginMapType.CursorCoord;
        auto placed = editor.PluginMapType.PlaceMacroblock_AirMode(editor.CurrentMacroBlockInfo, int3(coord.x, coord.y, coord.z), editor.PluginMapType.CursorDir);
        if(placed) 
            state = EState::Idle;
    }

    if(state == EState::AirMode && key == VirtualKey::Escape) {
        state = EState::Idle;
        return true;
    }

    return false;
}

bool OnMouseButton(bool down, int button, int x, int y) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;

    if(button == 0 && down)
        for(uint i = 0; i < Button::list.Length; i++) {
            auto customButton = Button::list[i];
            if(customButton.isHovered) {
                if(customButton.action == "create") {
                    CreateNewMacroPart();
                } else if(customButton.action == "cancel") {
                    CleanUp();
                    state = EState::Idle;
                } else if(customButton.action == "airmode") {
                    state = EState::AirMode;
                } else if(customButton.action == "edit") {
                    EditExistingMacroPart();
                } else if(customButton.action == "generate") {
                    Generate::selectedTabIndex = 0;
                    Generate::windowOpen = !Generate::windowOpen;
                } else if(customButton.action == "clear") {
                    MTG::ClearMap();
                } else {
                    warn("This button action wasn't implemented");
                }
                return true;
            }
        }

    auto isFreeLook = editor.PluginMapType.EditMode == CGameEditorPluginMap::EditMode::FreeLook;
    if(state == EState::SelectPlacement && button == 0 && down && !isFreeLook) {
        return PlaceUserMacroblockAtCursor();
    }

    if(state == EState::SelectEntrance && button == 0 && down && !isFreeLook) {
        auto coord = editor.PluginMapType.CursorCoord;
        auto absEntrance = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.entrance = MTG::ToRelativePosition(partDetails.macroblock, macroPlace, absEntrance);
        print("Entrance relative: " + partDetails.entrance.ToPrintString());
        state = EState::SelectExit;
        Generate::windowColor = vec4(35./255, 1./255, 1./255, 1);
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
        PlaceBackMap();
        // set type from detected blocks
        partDetails.type = entranceType;
        if(exitType != EPartType::Part)
            partDetails.type = exitType;
        if(partDetails.embeddedItems.Length == 0) {
            state = EState::EnterDetails;
        } else {
            state = EState::ConfirmItems;
        }
        Generate::windowColor = Generate::baseWindowColor;
        Generate::selectedTabIndex = 3;
        Generate::windowOpen = true;
        return true;
    }

    return false;
}

void CleanUp() {
    if(state == EState::AirMode) return;
    auto tempMacroblock = MTG::GetBlocksFolder() + macroPartFolder + "\\temp_MTG.Macroblock.Gbx";
    if(IO::FileExists(tempMacroblock)) {
        print("Clean up " + tempMacroblock);
        IO::Delete(tempMacroblock);
    }
    PlaceBackMap();
    Generate::windowColor = Generate::baseWindowColor;
}

void PlaceBackMap() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    if(copiedMap) {
        // get back original map & remove placed macroblock
        editor.PluginMapType.Undo();
    } else {
        // remove placed macroblock
        editor.PluginMapType.Undo();
        editor.PluginMapType.Redo();
    }
}

void CreateNewMacroPart() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    Generate::selectedTabIndex = 3;
    // Reset variables
    @partDetails = MacroPart();
    if(editor.Challenge !is null && editor.Challenge.AuthorNickName != "") {
        partDetails.author = editor.Challenge.AuthorNickName;
        print("author name: " + partDetails.author);
    }
    copiedMap = false;
    @macroPlace = null;
    changedSaveAsFilename = false;

    editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CopyPaste;
    isEditing = false;
    state = EState::SelectBlocks;
}

// Edit whatever MacroPart is selected by cursor now
void EditExistingMacroPart() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    Generate::selectedTabIndex = 3;
    // Reset variables
    @partDetails = null;
    copiedMap = false;
    @macroPlace = null;
    changedSaveAsFilename = false;
    editingFilename = "";

    isEditing = true;
    state = EState::SelectPlacement;
}

bool BlockFitsInDirection(CGameCtnBlock@ block,  CGameCtnBlockInfo@ otherBlock, CGameEditorPluginMap::ECardinalDirections direction) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;
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
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return EConnector::Platform;
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
        EConnector::RoadTech,
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
    if(rootPage == 'RoadTech')
        return EConnector::RoadTech;
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
        result.InsertLast("Sausage");
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
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;
    if(isEditing) {
        if(editor.CurrentMacroBlockInfo is null) 
            return false;
        @partDetails = MacroPart::FromMacroblock(editor.CurrentMacroBlockInfo);
        if(editor.Challenge !is null && editor.Challenge.AuthorNickName != "") {
            partDetails.author = editor.Challenge.AuthorNickName;
            print("author name: " + partDetails.author);
        }
        if(partDetails is null) {
            warn("MacroPart selected for editing is invalid.");
            @partDetails = MacroPart();
            @partDetails.macroblock = editor.CurrentMacroBlockInfo;
        }
        editingFilename = partDetails.macroblock.IdName;
    }
    print("Click place!");
    auto coord = editor.PluginMapType.CursorCoord;
    @macroPlace = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
    // placeusermacroblock changes state, so this doesn't get repeatedly called
    PlaceUserMacroblock(macroPlace);
    return true;
}

void PlaceUserMacroblock(DirectedPosition@ dirPos) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    copiedMap = MTG::CutMap();
    if(dirPos is null) {
        CleanUp();
        state = EState::Failed;
        failureReason = "Failed to find placement position for macro.";
        Warn("Failed to place macro!");
    } else {
        editor.PluginMapType.PlaceMacroblock_AirMode(partDetails.macroblock, dirPos.position, dirPos.direction);
        if(isEditing) {
            state = EState::EditBlocks;
            editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
        } else {
            state = EState::SelectEntrance;
            Generate::windowColor = vec4(1./255, 30./255, 1./255, 1);
        }
    }
}

void SelectNewMacroblock() {
    auto app = GetApp();
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    auto maxWait = 500;
    mbPath = macroPartFolder + "\\temp_MTG";
    app.BasicDialogs.String = mbPath;
    yield();
    app.BasicDialogs.DialogSaveAs_OnValidate();
    yield();
    app.BasicDialogs.DialogSaveAs_OnValidate();
    yield();
    yield();
    while(true) {
        auto mbPathW = wstring("Stadium\\" + mbPath.Replace('/', '\\')) + ".Macroblock.Gbx";
        print(mbPathW);
        auto mb = editor.PluginMapType.GetMacroblockModelFromFilePath(mbPathW);
        print("Mb isnull? " + (mb is null));
        if(maxWait-- < 0) {
            failureReason = "Failed to get newly saved macroblock";
            state = EState::Failed;
            CleanUp();
            break;
        }
        if(mb !is null) {
            @partDetails.macroblock = mb;
            if(isEditing) {
                state = EState::SelectEntrance;
            } else {
                state = EState::SelectPlacement;
            }
            break;
        };
        yield();
    }
}

void DeleteMacroblock(const string &in relPath) {
    auto path = MTG::GetBlocksFolder() + relPath;
    if(IO::FileExists(path)) {
        print("Deleting " + path);
        IO::Delete(path);
    }
    if(Generate::deletedParts.Find(relPath) == -1) {
        Generate::deletedParts.InsertLast(relPath);
    }
}

void RenameMacroblock(CGameCtnMacroBlockInfo@ macroblock, string newName) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    // todo: if mb name is already in format: macropartfolder \\ newName(n).Macroblock.Gbx, then dont delete
    if(macroblock is null) return;
    string newPath = "";
    if(isEditing && editingFilename != "") {
        newPath = editingFilename;
    } else {
        int i = 0;
        while(true) {
            string overwriteProtection = i == 0 ? "" : "(" + i + ")";
            newPath = "Stadium\\" + macroPartFolder + "\\" + newName + overwriteProtection + ".Macroblock.Gbx";
            if(newPath == macroblock.IdName) // old path was already in proper format, no need to rename
                return;
            if(!IO::FileExists(MTG::GetBlocksFolder() + newPath))
                break;
            i++;
            print("MacroBlock already exists: " + newPath + ", adding (" + i + ") to end of filename");
        }
    }
    auto oldPath = macroblock.IdName;
    macroblock.IdName = newPath;
    print("newPath: " + macroblock.IdName);
    
    auto delListIndex = Generate::deletedParts.Find(macroblock.IdName);
    // if item is in list of deleted parts, remove it from the list
    if(delListIndex != -1)
        Generate::deletedParts.RemoveAt(delListIndex);
    editor.PluginMapType.SaveMacroblock(macroblock);
    DeleteMacroblock(oldPath);
}

void SaveMacroPart(MacroPart@ part) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
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
    Generate::Initialize();
}

}