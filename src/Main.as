void Main() {
    
}

// todo:
// Try to auto detect entrance and exit connector type (EConnector)
// generate tracks lol

enum ECreateState {
    Idle,
    UserSelectMacro,
    SelectEntrance,
    SelectExit,
    ConfirmItems,
    EnterDetails
};

bool windowOpen = true;
CGameCtnMacroBlockInfo@ selectedMacroBlock = null;
ECreateState state = ECreateState::Idle;
bool copiedMap = false;
bool altIsDown = false;

DirectedPosition@ macroPlace = null;
vec4 baseWindowColor = vec4(.1, .1, .1, 1);
vec4 windowColor = baseWindowColor;
MacroPartDetails@ partDetails = null;


void FocusCam(int x, int y, int z) {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    editor.PluginMapType.Camera.GetLock();
    editor.PluginMapType.CameraTargetPosition.x = x * 32;
    editor.PluginMapType.CameraTargetPosition.y = y * 8;
    editor.PluginMapType.CameraTargetPosition.z = z * 32;
    editor.PluginMapType.CameraVAngle = 0.5;
    editor.PluginMapType.CameraHAngle = -2.7;
    editor.PluginMapType.Camera.ReleaseLock();
}

// get position of cursor position relative to macroblock's north arrow
DirectedPosition@ ToRelativePosition(CGameCtnMacroBlockInfo@ macroblock, DirectedPosition@ mbPosition, DirectedPosition@ cursor) {
    int rotation;
    auto size = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    DirectedPosition result;
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::North) {
        // north arrow = cursor, because mb is placed facing north
        result.x = cursor.x - mbPosition.x;
        result.y = cursor.y - mbPosition.y;
        result.z = cursor.z - mbPosition.z;
        result.direction = cursor.direction;
    }
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::East) {
        // without the -1 the north arrow placement would be outside the box of the macroblock, which is incorrect
        auto northArrow = DirectedPosition(mbPosition.x + size.z - 1, mbPosition.y, mbPosition.z);
        // flip x,z calculation because the macroblock aims east
        result.x = cursor.z - northArrow.z;
        result.y = cursor.y - northArrow.y;
        result.z = northArrow.x - cursor.x;
        result.direction = CGameEditorPluginMap::ECardinalDirections((cursor.direction + 3) % 4);
    }
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::South) {
        // without the -1 the north arrow placement would be outside the box of the macroblock, which is incorrect
        auto northArrow = DirectedPosition(mbPosition.x + size.x - 1, mbPosition.y, mbPosition.z + size.z - 1);
        // mb aims south
        result.x = northArrow.x - cursor.x;
        result.y = cursor.y - northArrow.y;
        result.z = northArrow.z - cursor.z;
        result.direction = CGameEditorPluginMap::ECardinalDirections((cursor.direction + 2) % 4);
    }
    if(mbPosition.direction == CGameEditorPluginMap::ECardinalDirections::West) {
        // without the -1 the north arrow placement would be outside the box of the macroblock, which is incorrect
        auto northArrow = DirectedPosition(mbPosition.x, mbPosition.y, mbPosition.z + size.x - 1);
        // flip x,z calculation because the macroblock aims west
        result.x = northArrow.z - cursor.z;
        result.y = cursor.y - northArrow.y;
        result.z = cursor.x - northArrow.x;
        result.direction = CGameEditorPluginMap::ECardinalDirections((cursor.direction + 1) % 4);
    }
    return result;
}

bool OnKeyPress(bool down, VirtualKey key) {
    if(key == VirtualKey::Menu) {
        altIsDown = down;
    }
    return false;
}

bool OnMouseButton(bool down, int button, int x, int y) {
    if(state == ECreateState::SelectEntrance && button == 0 && down && !altIsDown) {
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorCommon>(app.Editor);
        auto coord = editor.PluginMapType.CursorCoord;
        auto absEntrance = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.entrance = ToRelativePosition(selectedMacroBlock, macroPlace, absEntrance);
        print("Entrance relative: " + partDetails.entrance.ToString());
        state = ECreateState::SelectExit;
        windowColor = vec4(35./255, 1./255, 1./255, 1);
        return true;
    }
    if(state == ECreateState::SelectExit && button == 0 && down && !altIsDown) {
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorCommon>(app.Editor);
        auto coord = editor.PluginMapType.CursorCoord;
        auto absExit = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.exit = ToRelativePosition(selectedMacroBlock, macroPlace, absExit);
        print("Exit relative: " + partDetails.exit.ToString());

        editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Block;
        // Detect items in macroblock
        auto anchoredObjects = editor.Challenge.AnchoredObjects;
        for(uint j = 0; j < anchoredObjects.Length; j++) {
            auto itemPath = anchoredObjects[j].ItemModel.IdName;
            if(itemPath.EndsWith(".Item.Gbx") && partDetails.embeddedItems.Find(itemPath) == -1)
                partDetails.embeddedItems.InsertLast(itemPath);
        }
        if(copiedMap) {
            // get back original map & remove placed macroblock
            editor.PluginMapType.Undo();
        } else {
            // remove placed macroblock
            editor.PluginMapType.Undo();
            editor.PluginMapType.Redo();
        }

        state = ECreateState::ConfirmItems;
        windowColor = baseWindowColor;
        return true;
    }

    return false;
}

DirectedPosition@ FindMacroblockPlacement(CGameCtnMacroBlockInfo@ macroblock) {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    auto mapSize = editor.Challenge.Size;
    auto macroblockSize = macroblock.GeneratedBlockInfo.VariantBaseAir.Size;
    auto placeDir = CGameEditorPluginMap::ECardinalDirections::West;

    // Test placing in center of the map first (to not destroy items in the macroblock)
    auto macroPlace = DirectedPosition(
        mapSize.x / 2 - macroblockSize.x / 2,
        mapSize.y / 2 - macroblockSize.y / 2,
        mapSize.z / 2 - macroblockSize.z / 2,
        placeDir
    );
    auto canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, macroPlace.position, macroPlace.direction);
    if(canPlace) 
        return macroPlace;

    mapSize.x -= macroblockSize.x;
    mapSize.y -= macroblockSize.y;
    mapSize.z -= macroblockSize.z;
    // have same amount of loops regardless of map size (step = 2 for normal sized map)
    int step = (mapSize.x * mapSize.y * mapSize.z) / (48 * 40 * 48) + 1;
    for(uint x = 0; x < mapSize.x; x += step) {
        for(uint y = 0; y < mapSize.y; y += step) {
            for(uint z = 0; z < mapSize.z; z += step) {
                @macroPlace = DirectedPosition(x, y, z, placeDir);
                canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, macroPlace.position, macroPlace.direction);
                if(canPlace) 
                    return macroPlace;
            }
        }
    }
    return null;
}

void RenderInterface() {
    auto app = GetApp();

    UI::PushStyleColor(UI::Col::WindowBg, windowColor);
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(500, 300);
    if(UI::Begin("Create MacroPart", windowOpen)) {

        if(state == ECreateState::Idle) {
            if(UI::Button("Start")) {
                // Reset variables
                @partDetails = MacroPartDetails();
                copiedMap = false;
                @selectedMacroBlock = null;
                @macroPlace = null;

                state = ECreateState::UserSelectMacro;
                auto editor = cast<CGameCtnEditorCommon>(app.Editor);
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Macroblock;
            }
        }
        if(state == ECreateState::UserSelectMacro) {
            UI::Text("Select the macroblock");
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            @selectedMacroBlock = editor.CurrentMacroBlockInfo;
            if(selectedMacroBlock !is null) {
                UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
                UI::TextDisabled('Selected macroblock: "' + selectedMacroBlock.IdName + '"');
                UI::PopTextWrapPos();
            }

            if(selectedMacroBlock !is null && UI::Button("Use selected macroblock")) {
                editor.PluginMapType.CopyPaste_SelectAll();
                print("Count: " + editor.PluginMapType.CopyPaste_GetSelectedCoordsCount());
                if(editor.PluginMapType.CopyPaste_GetSelectedCoordsCount() != 0) {
                    editor.PluginMapType.CopyPaste_Cut();
                    copiedMap = true;
                }
                @macroPlace = FindMacroblockPlacement(selectedMacroBlock);
                if(macroPlace is null) {
                    state = ECreateState::Idle;
                    warn("Failed to place macro!");
                } else {
                    editor.PluginMapType.PlaceMacroblock_AirMode(selectedMacroBlock, macroPlace.position, macroPlace.direction);
                    FocusCam(macroPlace.x, macroPlace.y, macroPlace.z);
                    state = ECreateState::SelectEntrance;
                    windowColor = vec4(1./255, 30./255, 1./255, 1);
                }
            }
        }

        if(state == ECreateState::SelectEntrance) {
            UI::TextDisabled("Hiding the map to make selection easier, it will come back!");
            UI::Text("Select position the car enters this part");
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection) {
                print("Setting placemode");
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
            }
        }

        if(state == ECreateState::SelectExit) {
            UI::TextDisabled("Hiding the map to make selection easier, it will come back!");
            UI::Text("Select position the car exits this part");
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection)
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
        }

        if(state == ECreateState::ConfirmItems) {
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            UI::Text("Embedding the following items in the macroblock");
            UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
            UI::TextDisabled('It is recommended to only embed items from preset location: "zzz_ImportedItems/SetName/ItemName.Item.Gbx" when sharing parts.');
            UI::PopTextWrapPos();
            UI::BeginChild("CustomItemsList", vec2(UI::GetWindowContentRegionWidth(), 150));
            for(int i = int(partDetails.embeddedItems.Length) - 1; i >= 0; i--) {
                if(UI::RedButton(Icons::Trash)) {
                    partDetails.embeddedItems.RemoveAt(i);
                }
                UI::SameLine();
                UI::Text(partDetails.embeddedItems[i]);
            }
            UI::EndChild();

            if(UI::Button("Confirm items")) {
                state = ECreateState::EnterDetails;
            }
        }

        if(state == ECreateState::EnterDetails) {
            UI::Text("Enter MacroPart information");
            // UI::SetKeyboardFocusHere();
            partDetails.name = UI::InputText("Name", partDetails.name);

            if(UI::BeginCombo("Type", tostring(partDetails.type))) {
                if(UI::Selectable("Start", partDetails.type == EPartType::Start)) 
                    partDetails.type = EPartType::Start;
                if(UI::Selectable("Part", partDetails.type == EPartType::Part)) 
                    partDetails.type = EPartType::Part;
                if(UI::Selectable("Finish", partDetails.type == EPartType::Finish)) 
                    partDetails.type = EPartType::Finish;
                if(UI::Selectable("Multilap", partDetails.type == EPartType::Multilap)) 
                    partDetails.type = EPartType::Multilap;
                UI::EndCombo();
            }

            string tagsString = "";
            if(partDetails.tags.Length == 0) {
                tagsString = "No tags selected";
            }
            for(uint i = 0; i < partDetails.tags.Length; i++) {
                if(i != 0) tagsString += ", ";
                tagsString += partDetails.tags[i];
            }
            if(UI::BeginCombo("Tags", tagsString)) {
                for(uint i = 0; i < availableTags.Length; i++) {
                    int foundIndex = partDetails.tags.Find(availableTags[i]);
                    if(UI::Selectable(availableTags[i], foundIndex != -1)) {
                        if(foundIndex != -1)
                            partDetails.tags.RemoveAt(foundIndex);
                        else
                            partDetails.tags.InsertLast(availableTags[i]);
                    }
                }
                UI::EndCombo();
            }

            if(UI::BeginCombo("Difficulty", tostring(partDetails.difficulty))) {
                if(UI::Selectable("Beginner", partDetails.difficulty == EDifficulty::Beginner)) 
                    partDetails.difficulty = EDifficulty::Beginner;
                if(UI::Selectable("Intermediate", partDetails.difficulty == EDifficulty::Intermediate)) 
                    partDetails.difficulty = EDifficulty::Intermediate;
                if(UI::Selectable("Advanced", partDetails.difficulty == EDifficulty::Advanced)) 
                    partDetails.difficulty = EDifficulty::Advanced;
                if(UI::Selectable("Expert", partDetails.difficulty == EDifficulty::Expert)) 
                    partDetails.difficulty = EDifficulty::Expert;
                UI::EndCombo();
            }

            partDetails.enterSpeed = UI::InputInt("Enter speed", partDetails.enterSpeed, 10);
            partDetails.exitSpeed = UI::InputInt("Exit speed", partDetails.exitSpeed, 10);
            partDetails.duration = UI::InputInt("Duration (seconds)", partDetails.duration);
            UI::TextDisabled("Can you reach the end of this part starting with 0 speed?");
            partDetails.respawnable = UI::Checkbox("Respawnable", partDetails.respawnable);

            if(UI::Button("Save MacroPart")) {
                state = ECreateState::Idle;
            }
        }
    }
    UI::End();
    UI::PopStyleVar(4);
    UI::PopStyleColor(1);
}

void Main2() {
    const string macroblockFolder = "0MacroTrackGenerator"; //zzz_MacroTrackGenerator

    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    auto pluginMapType = editor.PluginMapType;
    auto inventory = pluginMapType.Inventory;
    auto rootNodes = inventory.RootNodes;
    CGameCtnArticleNodeDirectory@ macroblockDir = null;
    for(uint i = 0; i < rootNodes.Length; i++) {
        auto node = cast<CGameCtnArticleNodeDirectory>(rootNodes[i]);
        if(node is null) continue;
        bool foundMacroblocks = false;
        for(uint j = 0; j < node.ChildNodes.Length; j++)
            if(node.ChildNodes[j].Name.EndsWith('.Macroblock.Gbx'))
                foundMacroblocks = true;
        if(!foundMacroblocks) continue;

        print("Found macroblock node" + i);
        for(uint j = 0; j < node.ChildNodes.Length; j++) {
            auto subNode = cast<CGameCtnArticleNodeDirectory>(node.ChildNodes[j]);
            if(subNode is null) continue;
            if(subNode.Name != macroblockFolder) continue;
            @macroblockDir = subNode;
        }
    }

    if(macroblockDir is null) {
        warn("Couldn't find plugin's macroblock dir");
        return;
    }

    print("Found macroblock dir! " + macroblockDir.Name);
    auto mbPath = wstring("Stadium\\macro\\fs-finish2-620-0.Macroblock.Gbx");
    auto mb = pluginMapType.GetMacroblockModelFromFilePath(mbPath);
    print(mb.Name + " " + mb.Description);

    // get map center in free coordinates
    auto mapCenterVec = editor.GetMapCenter();
    // convert to block coordinates
    auto mapCenter = int3(int(mapCenterVec.x / 32), int(mapCenterVec.y / 8) + 20, int(mapCenterVec.z / 32));
    print(mapCenter.x + ", " + mapCenter.y + ", " + mapCenter.z);
    auto direction = CGameEditorPluginMap::ECardinalDirections::West;

    auto canPlace = pluginMapType.CanPlaceMacroblock(mb, mapCenter, direction);
    print("Can place: " + canPlace);

    // mb.Description = "hello world";
    // pluginMapType.SaveMacroblock(mb);

    // auto placed = pluginMapType.PlaceMacroblock_AirMode(mb, mapCenter, direction);
    // print("Placed: " + placed);

    auto coords = pluginMapType.CustomSelectionCoords;
    print("Coord length " + coords.Length);
    for(uint i = 0; i < coords.Length; i++) {
         auto coord = coords[i];
         print(i);
    }

    uint k = pluginMapType.CopyPaste_GetSelectedCoordsCount();
    print(k);
}