void Main() {
    
}

// todo:
// finish create macropart flow:
// 1. Start
// 2. "Save your macroblock to 'zzz_MacroTrackGenerator/decideaname.Macroblock.Gbx' by selecting blocks and clicking the save icon"
// 3. do the thing with currently selected macroblock: editor.CurrentMacroBlockInfo
// 4. Place it in the viewport while hiding all other blocks and do the rest of the user inputs
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

CGameCtnBlock@ entranceBlock = null;
CGameCtnBlock@ exitBlock = null;
EPartType entranceType = EPartType::Part;
EPartType exitType = EPartType::Part;

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
    
    if(state == ECreateState::UserSelectMacro && key == VirtualKey::V && down) {
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorCommon>(app.Editor);
        auto coord = editor.PluginMapType.CursorCoord;
        auto dir = editor.PluginMapType.CursorDir;
        @macroPlace = DirectedPosition(coord.x, coord.y, coord.z, dir);
        // placeusermacroblock changes state, so this doesn't get repeatedly called
        PlaceUserMacroblock(macroPlace, false);
        return true;
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
        print("Entrance relative: " + partDetails.entrance.ToPrintString());
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
        print("Exit relative: " + partDetails.exit.ToPrintString());

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

        // clear any accidentally selected coords
        editor.PluginMapType.CustomSelectionCoords.RemoveRange(0, editor.PluginMapType.CustomSelectionCoords.Length);
        editor.PluginMapType.HideCustomSelection();
        // set type from detected blocks
        partDetails.type = entranceType;
        if(exitType != EPartType::Part)
            partDetails.type = exitType;
        if(partDetails.embeddedItems.Length == 0) {
            state = ECreateState::EnterDetails;
        } else {
            state = ECreateState::ConfirmItems;
        }
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
    auto placePoint = DirectedPosition(
        mapSize.x / 2 - macroblockSize.x / 2,
        mapSize.y / 2 - macroblockSize.y / 2,
        mapSize.z / 2 - macroblockSize.z / 2,
        placeDir
    );
    auto canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, placePoint.position, placePoint.direction);
    if(canPlace) 
        return placePoint;

    mapSize.x -= macroblockSize.x;
    mapSize.y -= macroblockSize.y;
    mapSize.z -= macroblockSize.z;
    // have same amount of loops regardless of map size (step = 2 for normal sized map)
    int step = (mapSize.x * mapSize.y * mapSize.z) / (48 * 40 * 48) + 1;
    for(uint x = 0; x < mapSize.x; x += step) {
        for(uint y = 0; y < mapSize.y; y += step) {
            for(uint z = 0; z < mapSize.z; z += step) {
                @placePoint = DirectedPosition(x, y, z, placeDir);
                canPlace = editor.PluginMapType.CanPlaceMacroblock(macroblock, placePoint.position, placePoint.direction);
                if(canPlace) 
                    return placePoint;
            }
        }
    }
    return null;
}

bool BlockFitsInDirection(CGameCtnBlock@ block,  CGameCtnBlockInfo@ otherBlock, CGameEditorPluginMap::ECardinalDirections direction) {
    if(block is null || otherBlock is null) return false;
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
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
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);

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

void PlaceUserMacroblock(DirectedPosition@ dirPos, bool focusCam = true) {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    editor.PluginMapType.CopyPaste_SelectAll();
    print("Count: " + editor.PluginMapType.CopyPaste_GetSelectedCoordsCount());
    if(editor.PluginMapType.CopyPaste_GetSelectedCoordsCount() != 0) {
        editor.PluginMapType.CopyPaste_Cut();
        copiedMap = true;
    }
    if(dirPos is null) {
        state = ECreateState::Idle;
        warn("Failed to place macro!");
    } else {
        editor.PluginMapType.PlaceMacroblock_AirMode(selectedMacroBlock, dirPos.position, dirPos.direction);
        if(focusCam)
            FocusCam(dirPos.x, dirPos.y, dirPos.z);
        state = ECreateState::SelectEntrance;
        windowColor = vec4(1./255, 30./255, 1./255, 1);
    }
}

void RenderInterface() {
    auto app = GetApp();

    UI::PushStyleColor(UI::Col::WindowBg, windowColor);
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(500, 330);
    if(UI::Begin("Create MacroPart", windowOpen)) {

        if(state == ECreateState::Idle) {
            if(UI::Button("Start")) {
                auto editor = cast<CGameCtnEditorCommon>(app.Editor);
                // Reset variables
                @partDetails = MacroPartDetails();
                if(editor.Challenge !is null && editor.Challenge.AuthorNickName != "") {
                    partDetails.author = editor.Challenge.AuthorNickName;
                    print("author name: " + partDetails.author);
                }
                copiedMap = false;
                @selectedMacroBlock = null;
                @macroPlace = null;

                state = ECreateState::UserSelectMacro;
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
                UI::Text('Press "V" to use the curretly selected macroblock.');
                UI::PopTextWrapPos();
                if(UI::Button("Use selected macroblock")) {
                    @macroPlace = FindMacroblockPlacement(selectedMacroBlock);
                    PlaceUserMacroblock(macroPlace);
                }
            }
        }

        if(state == ECreateState::SelectEntrance) {
            UI::TextDisabled("Hiding the map to make selection easier, it will come back!");
            UI::Text("Select position the car enters this part");
            UI::NewLine();
            if(entranceBlock is null) {
                UI::Text("Connector type can automatically be determined if an official block is selected.");
                UI::TextDisabled("Otherwise you will have to specify it later");
            } else {
                UI::Text("Auto detected values:");
                UI::TextDisabled("You can manually change these later");
            }
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            auto c = editor.PluginMapType.CursorCoord;
            @entranceBlock = editor.PluginMapType.GetBlock(int3(c.x, c.y, c.z));
            if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection) {
                print("Setting placemode");
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
            }
            
            if(entranceBlock !is null) {
                partDetails.entranceConnector = GetConnector(entranceBlock, editor.PluginMapType.CursorDir);
                auto tags = GetTags(entranceBlock.BlockInfo);
                partDetails.AddTags(tags);
                UI::TextDisabled("Connector: " + tostring(partDetails.entranceConnector));
                if(entranceBlock.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::Start) {
                    entranceType = EPartType::Start;
                } else if(entranceBlock.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::StartFinish) {
                    entranceType = EPartType::Multilap;
                } else {
                    entranceType = EPartType::Part;
                }
                UI::TextDisabled("Type: " + tostring(entranceType));
                UI::TextDisabled("Tags: " + string::Join(tags, ", "));
            } else{
                partDetails.entranceConnector = EConnector::Platform;
            } 
        }

        if(state == ECreateState::SelectExit) {
            UI::TextDisabled("Hiding the map to make selection easier, it will come back!");
            UI::Text("Select position the car exits this part");
            UI::NewLine();
            if(exitBlock is null) {
                UI::Text("Can't automatically determine current exit block");
                UI::TextDisabled("You will have to specify it later");
            } else {
                UI::Text("Auto detected values:");
                UI::TextDisabled("You can manually change these later");
            }
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            auto c = editor.PluginMapType.CursorCoord;
            @exitBlock = editor.PluginMapType.GetBlock(int3(c.x, c.y, c.z));
            if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection)
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
            
            if(exitBlock !is null) {
                partDetails.exitConnector = GetConnector(exitBlock, editor.PluginMapType.CursorDir);
                auto tags = GetTags(exitBlock.BlockInfo);
                partDetails.AddTags(tags);
                UI::TextDisabled("Connector: " + tostring(partDetails.exitConnector));
                if(exitBlock.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::Finish) {
                    exitType = EPartType::Finish;
                } else if(exitBlock.BlockInfo.EdWaypointType == CGameCtnBlockInfo::EWayPointType::StartFinish) {
                    exitType = EPartType::Multilap;
                } else {
                    exitType = EPartType::Part;
                }
                UI::TextDisabled("Type: " + tostring(exitType));
                UI::TextDisabled("Tags: " + string::Join(tags, ", "));

            } else {
                partDetails.exitConnector = EConnector::Platform;
            }
        }

        if(state == ECreateState::ConfirmItems) {
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            UI::Text("Embedding the following items in the macroblock");
            UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
            UI::TextDisabled('It is recommended to only embed items from preset location: "zzz_ImportedItems/SetName/ItemName.Item.Gbx" when sharing parts.');
            UI::TextDisabled("When sharing a MacroPart the custom items need to be in the exact same folder for everyone using it.");
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
                for(uint i = 0; i < availableTypes.Length; i++) 
                    if(UI::Selectable(tostring(availableTypes[i]), partDetails.type == availableTypes[i])) 
                        partDetails.type = availableTypes[i];
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
                for(uint i = 0; i < availableDifficulties.Length; i++) 
                    if(UI::Selectable(tostring(availableDifficulties[i]), partDetails.difficulty == availableDifficulties[i])) 
                        partDetails.difficulty = availableDifficulties[i];
                UI::EndCombo();
            }

            if(partDetails.type != EPartType::Start) {
                UI::PushID('entrance');
                UI::TextDisabled("Entrance");
                UI::SetNextItemWidth(122);
                if(UI::BeginCombo("Connector", tostring(partDetails.entranceConnector))) {
                    for(uint i = 0; i < availableConnectors.Length; i++) 
                        if(UI::Selectable(tostring(availableConnectors[i]), partDetails.entranceConnector == availableConnectors[i])) 
                            partDetails.entranceConnector = availableConnectors[i];
                    UI::EndCombo();
                }
                UI::SameLine();
                UI::SetNextItemWidth(125);
                partDetails.enterSpeed = Math::Clamp(UI::InputInt("Speed", partDetails.enterSpeed, 10), 0, 999);
                UI::PopID();
            }
            if(partDetails.type != EPartType::Finish) {
                UI::PushID('exit');
                UI::TextDisabled("Exit");
                UI::SetNextItemWidth(122);
                if(UI::BeginCombo("Connector", tostring(partDetails.exitConnector))) {
                    for(uint i = 0; i < availableConnectors.Length; i++) 
                        if(UI::Selectable(tostring(availableConnectors[i]), partDetails.exitConnector == availableConnectors[i])) 
                            partDetails.exitConnector = availableConnectors[i];
                    UI::EndCombo();
                }
                UI::SameLine();
                UI::SetNextItemWidth(125);
                partDetails.exitSpeed = Math::Clamp(UI::InputInt("Speed", partDetails.exitSpeed, 10), 0, 999);
                UI::PopID();
            }
            partDetails.duration = UI::InputInt("Duration (seconds)", partDetails.duration);
            if(partDetails.type != EPartType::Start) {
                UI::TextDisabled("Can you reach the end of this part starting with 0 speed?");
                partDetails.respawnable = UI::Checkbox("Respawnable", partDetails.respawnable);
            }

            if(UI::Button("Save MacroPart")) {
                SaveMacroPart(selectedMacroBlock, partDetails);
                state = ECreateState::Idle;
            }
        }
    }
    UI::End();
    UI::PopStyleVar(4);
    UI::PopStyleColor(1);
}

void Main2() {

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