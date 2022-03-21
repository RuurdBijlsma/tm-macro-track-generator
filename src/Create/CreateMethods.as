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
    AirMode,
    Failed
};

EState state = EState::Idle;
string editingFilename = "";
int editStage = 0;
bool isEditing = false;
bool isEditingEntranceExit = false;
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
        if(!isEditingEntranceExit)
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
                    Generate::selectedTabIndex = 2;
                    Generate::windowOpen = true;
                    if(editor.CurrentMacroBlockInfo !is null)
                        @Parts::selectedPart = MTG::PartFromID(editor.CurrentMacroBlockInfo.IdName);
                } else if(customButton.action == "generate") {;
                    Generate::selectedTabIndex = 0;
                    Generate::windowOpen = !Generate::windowOpen;
                } else if(customButton.action == "clear") {
                    MTG::ClearMap();
                } else {
                    warn("This button action wasn't implemented");
                }
                print("Mouse button return true 1");
                return true;
            }
        }

    auto isFreeLook = editor.PluginMapType.EditMode == CGameEditorPluginMap::EditMode::FreeLook;
    if(state == EState::SelectPlacement && button == 0 && down && !isFreeLook) {
        auto v = PlaceUserMacroblockAtCursor();
        if(v)
            print("Mouse button return true 2");
        return v;
    }

    if(state == EState::AirMode && button == 0 && down && !isFreeLook && editor.CurrentMacroBlockInfo !is null) {
        auto coord = int3(editor.PluginMapType.CursorCoord.x, editor.PluginMapType.CursorCoord.y, editor.PluginMapType.CursorCoord.z);
        auto placed = editor.PluginMapType.PlaceMacroblock_AirMode(editor.CurrentMacroBlockInfo, coord, editor.PluginMapType.CursorDir);
        if(placed) {
            state = EState::Idle;
        }
        print("Mouse button return true 3");
        return true;
    }

    if(state == EState::SelectEntrance && button == 0 && down && !isFreeLook) {
        auto coord = editor.PluginMapType.CursorCoord;
        auto absEntrance = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.entrance = MTG::ToRelativePosition(partDetails.macroblock, macroPlace, absEntrance);
        print("Entrance relative: " + partDetails.entrance.ToPrintString());
        state = EState::SelectExit;
        TMUI::windowColor = vec4(35./255, 1./255, 1./255, 1);
        print("Mouse button return true 4");
        return true;
    }
    if(state == EState::SelectExit && button == 0 && down && !isFreeLook) {
        auto coord = editor.PluginMapType.CursorCoord;
        auto absExit = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.exit = MTG::ToRelativePosition(partDetails.macroblock, macroPlace, absExit);
        print("Exit relative: " + partDetails.exit.ToPrintString());
        editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
        TMUI::windowColor = TMUI::baseWindowColor;

        if(isEditingEntranceExit) {
            state = EState::Idle;
            SaveMacroPart(partDetails, false);
            Generate::selectedTabIndex = 2;
            Parts::PickMacroblock(partDetails.macroblock);
            @Parts::selectedPart = null;
            PlaceBackMap();
            print("Mouse button return true 5");
            return true;
        }

        // Detect items in macroblock
        auto anchoredObjects = editor.Challenge.AnchoredObjects;
        @partDetails.embeddedItems = {};
        for(uint i = 0; i < anchoredObjects.Length; i++) {
            auto itemPath = anchoredObjects[i].ItemModel.IdName;
            if(itemPath.ToLower().EndsWith(".item.gbx") && partDetails.embeddedItems.Find(itemPath) == -1){
                partDetails.embeddedItems.InsertLast(itemPath);
            }
        }
        auto blocks = editor.Challenge.Blocks;
        for(uint i = 0; i < blocks.Length; i++) {
            auto article = cast<CGameCtnArticle@>(blocks[i].BlockInfo.ArticlePtr);
            if(article is null || article.BlockItem_ItemModelArticle is null) continue;
            auto blockPath = article.BlockItem_ItemModelArticle.IdName;
            if(blockPath.ToLower().EndsWith(".block.gbx") && partDetails.embeddedItems.Find(blockPath) == -1)
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
            CheckItemsExist();
        }
        Generate::selectedTabIndex = 3;
        Generate::windowOpen = true;
        print("Mouse button return true 6");
        return true;
    }

    return false;
}

void CheckItemsExist() {
    string[]@ dontExistItems = {};
    for(uint i = 0; i < partDetails.embeddedItems.Length; i++) {
        auto relItemPath = partDetails.embeddedItems[i];
        auto itemPath = MTG::GetItemsFolder() + relItemPath;
        print("Checking item exists: " + itemPath);
        if(!IO::FileExists(itemPath)) {
            dontExistItems.InsertLast(itemPath);
        }
    }
    if(dontExistItems.Length > 0) {
        Fail("The following embedded items don't exist on the disk: \n* " + string::Join(dontExistItems, "\n* "));
    }
}

void ResetState() {
    editStage = 0;
    @blockInfo = null;
    @detectedTags = null;
    entranceType = EPartType::Part;
    exitType = EPartType::Part;
    mbPath = "";
    @partDetails = null;
    @macroPlace = null;
    changedSaveAsFilename = false;
    copiedMap = false;
    isEditing = false;
    isEditingEntranceExit = false;
    editingFilename = "";
    state = EState::Idle;
}

void CleanUp() {
    print("Cleanup called");
    auto tempMacroblock = MTG::GetBlocksFolder() + "Stadium\\" + macroPartFolder + "\\temp_MTG.Macroblock.Gbx";
    if(IO::FileExists(tempMacroblock)) {
        print("Clean up " + tempMacroblock);
        IO::Delete(tempMacroblock);
    }
    TMUI::windowColor = TMUI::baseWindowColor;

    if(state != EState::EditBlocks && state != EState::SelectEntrance && state != EState::SelectExit) return;
    print("Placing back map!");
    PlaceBackMap();
}

void Fail(string reason) {
    ResetState();
    state = EState::Failed;
    failureReason = reason;
    Generate::selectedTabIndex = 3;
    Generate::windowOpen = true;
    Warn(reason);
}

void PlaceBackMap() {
    print("Place back map called!");
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
    ResetState();
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    Generate::selectedTabIndex = 3;
    @partDetails = MacroPart();
    auto app = GetApp();
    auto network = cast<CTrackManiaNetwork@>(app.Network);
    if(network !is null && network.PlayerInfo !is null && network.PlayerInfo.Name != "") {
        partDetails.author = network.PlayerInfo.Name;
        print("author name: " + partDetails.author);
    }

    editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CopyPaste;
    isEditing = false;
    state = EState::SelectBlocks;
}

// Edit whatever MacroPart is selected by cursor now
void EditExistingMacroPart() {
    ResetState();
    Generate::selectedTabIndex = 3;

    isEditing = true;
    state = EState::SelectPlacement;
}

void EditEntranceExit() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    if(editor.CurrentMacroBlockInfo is null) return;

    ResetState();
    isEditingEntranceExit = true;
    state = EState::SelectPlacement;
    Generate::selectedTabIndex = 3;
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

string[]@ DetectMapTags() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return {};
    auto blocks = editor.PluginMapType.ClassicBlocks;
    string[]@ resultingTags = {};
    for(uint i = 0; i < blocks.Length; i++) {
        auto newTags = GetTags(blocks[i].BlockInfo);
        for(uint j = 0; j < newTags.Length; j++) {
            if(resultingTags.Find(newTags[j]) == -1)
                resultingTags.InsertLast(newTags[j]);
        }
    }
    return resultingTags;
}

string[]@ GetTags(CGameCtnBlockInfo@ blockInfo) {
    string[]@ result = {};
    if(blockInfo is null || !blockInfo.PageName.Contains('/')) return result;
    auto rootPage = string(blockInfo.PageName).Split('/')[0];
    if(rootPage == 'RoadTech')
        result.InsertLast("Tech");
    if(rootPage == 'RoadDirt')
        result.InsertLast("Dirt");
    if(rootPage == 'RoadBump')
        result.InsertLast("Sausage");
    if(rootPage == 'RoadIce') {
        result.InsertLast("Bobsleigh");
        result.InsertLast("Ice");
    }
    if(rootPage == 'PlatformTech') {
        result.InsertLast("Platform");
        result.InsertLast("Tech");
    }
    if(rootPage == 'PlatformDirt') {
        result.InsertLast("Platform");
        result.InsertLast("Dirt");
    }
    if(rootPage == 'PlatformIce') {
        result.InsertLast("Platform");
        result.InsertLast("Ice");
    }
    if(rootPage == 'PlatformGrass') {
        result.InsertLast("Platform");
        result.InsertLast("Grass");
    }
    if(rootPage == 'PlatformPlastic') {
        result.InsertLast("Platform");
        result.InsertLast("Plastic");
    }
    if(rootPage == 'RoadWater') {
        result.InsertLast("Water");
        if(blockInfo.Name.Contains("Platform")) {
            result.InsertLast("Platform");
        }
    }
    if(rootPage == 'Walls')
        result.InsertLast("Tech");
    return result;
}

void SetMacroPartFromCursor() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;

    @partDetails = MacroPart::FromMacroblock(editor.CurrentMacroBlockInfo);
    auto app = GetApp();
    auto network = cast<CTrackManiaNetwork@>(app.Network);
    if(network !is null && network.PlayerInfo !is null && network.PlayerInfo.Name != "") {
        partDetails.author = network.PlayerInfo.Name;
        print("author name: " + partDetails.author);
    }
    if(partDetails is null) {
        warn("MacroPart selected for editing is invalid.");
        @partDetails = MacroPart();
        @partDetails.macroblock = editor.CurrentMacroBlockInfo;
    }
}

bool PlaceUserMacroblockAtCursor() {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return false;
    if((isEditing || isEditingEntranceExit)) {
        if(editor.CurrentMacroBlockInfo is null) 
            return false;
        SetMacroPartFromCursor();
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
        Fail("Failed to find placement position for MacroPart.");
    } else {
        editor.PluginMapType.PlaceMacroblock_AirMode(partDetails.macroblock, dirPos.position, dirPos.direction);
        if(isEditingEntranceExit) {
            state = EState::SelectEntrance;
            TMUI::windowColor = vec4(1./255, 30./255, 1./255, 1);
        } else if(isEditing && editStage == 0) {
            editStage = 1;
            state = EState::EditBlocks;
            editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
        } else {
            partDetails.AddTags(DetectMapTags());
            state = EState::SelectEntrance;
            TMUI::windowColor = vec4(1./255, 30./255, 1./255, 1);
        }
    }
}

void SelectNewMacroblock() {
    auto app = GetApp();
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    int maxUps = 5;
    while(app.BasicDialogs.DialogSaveAs_Path != "Stadium\\") {
        print("Doing hierarchy up, because path = " + app.BasicDialogs.DialogSaveAs_Path);
        app.BasicDialogs.DialogSaveAs_HierarchyUp();
        if(maxUps-- <= 0) {
            Fail("Couldn't find macroblock save path, check where macroparts are being saved, it should be Blocks\\Stadium\\");
            CleanUp();
            return;
        }
    }
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
            Fail("Failed to get newly saved macroblock");
            CleanUp();
            break;
        }
        if(mb !is null) {
            if(mb.IsGround) {
                Fail("The selection was connected to the ground, isn't usable for MacroParts.");
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
                break;
            }
            @partDetails.macroblock = mb;
            if(isEditing) {
                PlaceUserMacroblock(macroPlace);
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

string RenameMacroblock(CGameCtnMacroBlockInfo@ macroblock, string newName) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return "";
    // todo: if mb name is already in format: macropartfolder \\ newName(n).Macroblock.Gbx, then dont delete
    if(macroblock is null) return "";
    string newPath = "";
    if(isEditing && editingFilename != "") {
        newPath = editingFilename;
    } else {
        int i = 0;
        while(true) {
            string overwriteProtection = i == 0 ? "" : "(" + i + ")";
            newPath = "Stadium\\" + macroPartFolder + "\\" + newName + overwriteProtection + ".Macroblock.Gbx";
            if(newPath == macroblock.IdName) { // old path was already in proper format, no need to rename
                return newPath;
            }
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
    if(macroblock.IdName != oldPath)
        DeleteMacroblock(oldPath);
    return newPath;
}

string SaveMacroPart(MacroPart@ part, bool rename = true) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return "";
    string base64Items = "";
    for(uint i = 0; i < part.embeddedItems.Length; i++) {
        auto relItemPath = part.embeddedItems[i];
        auto itemPath = MTG::GetItemsFolder() + relItemPath;
        print("itemPath: " + itemPath);
        if(!IO::FileExists(itemPath)) {
            Fail("Embedded item: " + itemPath + " file doesn't exist! Can't save MacroPart.");
            return "";
        }
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
    string id = "";
    if(rename)
        id = RenameMacroblock(part.macroblock, "MTG-" + part.author + "-" + part.name);
    else
        id = part.macroblock.IdName;
    Generate::Initialize();
    return id;
}

}