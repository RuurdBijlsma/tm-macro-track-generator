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

bool isEditing = false;
bool windowOpen = true;
CGameCtnMacroBlockInfo@ selectedMacroBlock = null;
EState state = EState::Idle;
bool copiedMap = false;
bool altIsDown = false;

string failureReason = "";
DirectedPosition@ macroPlace = null;
vec4 baseWindowColor = vec4(.1, .1, .1, 1);
vec4 windowColor = baseWindowColor;
MacroPart@ partDetails = null;
bool changedSaveAsFilename = false;
string mbPath = "";

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
    editor.PluginMapType.Camera.ReleaseLock();
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
    return DirectedPosition::Subtract(cursor, northArrow, northArrow.direction);
}

bool OnKeyPress(bool down, VirtualKey key) {
    if(key == VirtualKey::Menu) {
        altIsDown = down;
    }

    if(state == EState::SelectPlacement && key == VirtualKey::V && down) {
        return UserPlaceMacroblockAtCursor();
    }

    return false;
}

bool UserPlaceMacroblockAtCursor() {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    if(isEditing) {
        if(editor.CurrentMacroBlockInfo is null) 
            return false;
        @selectedMacroBlock = editor.CurrentMacroBlockInfo;
        @partDetails = MacroPart::FromMacroblock(selectedMacroBlock);
        if(partDetails is null) {
            warn("MacroPart selected for editing is invalid.");
            @partDetails = MacroPart();
        }
    }
    print("Click place!");
    auto coord = editor.PluginMapType.CursorCoord;
    auto dir = editor.PluginMapType.CursorDir;
    @macroPlace = DirectedPosition(coord.x, coord.y, coord.z, dir);
    // placeusermacroblock changes state, so this doesn't get repeatedly called
    PlaceUserMacroblock(macroPlace, false);
    return true;
}

bool OnMouseButton(bool down, int button, int x, int y) {
    if(!isEditing && state == EState::SelectPlacement && button == 0 && down && !altIsDown) {
        return UserPlaceMacroblockAtCursor();
    }

    if(state == EState::SelectEntrance && button == 0 && down && !altIsDown) {
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorCommon>(app.Editor);
        auto coord = editor.PluginMapType.CursorCoord;
        auto absEntrance = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.entrance = ToRelativePosition(selectedMacroBlock, macroPlace, absEntrance);
        print("Entrance relative: " + partDetails.entrance.ToPrintString());
        state = EState::SelectExit;
        windowColor = vec4(35./255, 1./255, 1./255, 1);
        return true;
    }
    if(state == EState::SelectExit && button == 0 && down && !altIsDown) {
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorCommon>(app.Editor);
        auto coord = editor.PluginMapType.CursorCoord;
        auto absExit = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
        @partDetails.exit = ToRelativePosition(selectedMacroBlock, macroPlace, absExit);
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

bool CutMap() {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    editor.PluginMapType.CopyPaste_SelectAll();
    if(editor.PluginMapType.CopyPaste_GetSelectedCoordsCount() != 0) {
        editor.PluginMapType.CopyPaste_Cut();
        return true;
    }
    return false;
}

void PlaceUserMacroblock(DirectedPosition@ dirPos, bool focusCam = true) {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    copiedMap = CutMap();
    if(dirPos is null) {
        state = EState::Failed;
        failureReason = "Failed to find placement position for macro.";
        warn("Failed to place macro!");
    } else {
        editor.PluginMapType.PlaceMacroblock_AirMode(selectedMacroBlock, dirPos.position, dirPos.direction);
        if(focusCam)
            FocusCam(dirPos.x, dirPos.y, dirPos.z);
        state = EState::SelectEntrance;
        windowColor = vec4(1./255, 30./255, 1./255, 1);
    }
}

void SelectNewMacroblock() {
    auto maxWait = 1000;
    while(true) {
        auto app = GetApp();
        auto editor = cast<CGameCtnEditorCommon>(app.Editor);
        auto mbPathW = wstring("Stadium\\" + mbPath.Replace('/', '\\')) + ".Macroblock.Gbx";
        print(mbPathW);
        auto mb = editor.PluginMapType.GetMacroblockModelFromFilePath(mbPathW);
        print("Mb isnull? " + (mb is null));
        yield();
        if(maxWait-- < 0) {
            failureReason = "Failed to get newly saved macroblock";
            state = EState::Failed;
            break;
        }
        if(mb !is null) {
            state = EState::SelectPlacement;
            @selectedMacroBlock = mb;
            break;
        };
    }
}

void RenderInterface() {
    auto app = GetApp();

    UI::PushStyleColor(UI::Col::WindowBg, windowColor);
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(500, 364);
    if(UI::Begin("Create MacroPart", windowOpen)) {
        if(state == EState::Failed) {
            UI::Text("Something went wrong!");
            UI::Text(failureReason);
            if(UI::Button("Go back")) {
                state = EState::Idle;
            }
        }

        if(state == EState::Idle) {
            UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
            UI::Text("Randomly generated tracks consist of 'MacroParts'. These are macroblocks with some extra information embedded in them to help the generator connect parts together.");
            UI::TextDisabled("Your available MacroParts can be found in the macroblocks tab below (F4), in the folder '" + macroPartFolder + "'.");
            UI::PopTextWrapPos();            
            if(UI::Button("Create new MacroPart")) {
                auto editor = cast<CGameCtnEditorCommon>(app.Editor);
                // Reset variables
                @partDetails = MacroPart();
                if(editor.Challenge !is null && editor.Challenge.AuthorNickName != "") {
                    partDetails.author = editor.Challenge.AuthorNickName;
                    print("author name: " + partDetails.author);
                }
                copiedMap = false;
                @selectedMacroBlock = null;
                @macroPlace = null;
                changedSaveAsFilename = false;

                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CopyPaste;
                isEditing = false;
                state = EState::SelectBlocks;
            }
            if(UI::Button("Edit existing MacroPart")) {
                auto editor = cast<CGameCtnEditorCommon>(app.Editor);
                // Reset variables
                @partDetails = null;
                copiedMap = false;
                @selectedMacroBlock = null;
                @macroPlace = null;
                changedSaveAsFilename = false;

                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Macroblock;
                isEditing = true;
                state = EState::SelectPlacement;
            }
        }

        if(state == EState::SelectBlocks) {
            
            auto currentFrame = app.BasicDialogs.Dialogs.CurrentFrame;
            if(currentFrame !is null && currentFrame.IdName == 'FrameDialogSaveAs') {
                if(!changedSaveAsFilename) {
                    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
                    auto timeString = Time::FormatString("%Y%m%d-%H%M%S", Time::get_Stamp());
                    auto filename = "MTG-" + partDetails.author + "-" + timeString;
                    mbPath = macroPartFolder + "/" + filename;
                    app.BasicDialogs.String = mbPath;
                    app.BasicDialogs.DialogSaveAs_OnValidate();
                    app.BasicDialogs.DialogSaveAs_OnValidate();
                    changedSaveAsFilename = true;
                    startnew(SelectNewMacroblock);
                }
            } else {
                UI::Text("Select the blocks for this part, click the " + Icons::Kenney::Save + " icon when done.");
                UI::TextDisabled("Only use floating blocks or items.");
                UI::TextDisabled("Don't select ground blocks.");
                auto editor = cast<CGameCtnEditorCommon>(app.Editor);
                auto selectCount = editor.PluginMapType.CopyPaste_GetSelectedCoordsCount();
                UI::Text("Selection size: " + selectCount);
            }
        }

        if(state == EState::SelectPlacement) {
            UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
            if(isEditing) {
                state = EState::SelectPlacement;
                UI::Text("Select the MacroPart to edit.");
                UI::Text("Press 'V' to place the macroblock in the map. It will not destroy any existing blocks.");
            } else {
                UI::Text("Click to place the macroblock in the map. It will not destroy any existing blocks.");
            }
            UI::TextDisabled("Take care not to place it too close to the map border, or custom items may not get placed.");
            UI::PopTextWrapPos();
        }

        if(state == EState::SelectEntrance) {
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
            if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection)
                editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
            
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

        if(state == EState::SelectExit) {
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

        if(state == EState::ConfirmItems) {
            auto editor = cast<CGameCtnEditorCommon>(app.Editor);
            UI::Text("Embedding the following items in the macroblock");
            UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
            UI::TextDisabled('It is recommended to only embed items and blocks from the preset location: "zzz_ImportedItems/SetName/ItemName.Item.Gbx" when sharing parts.');
            UI::TextDisabled("When sharing a MacroPart the custom items and blocks need to be in the exact same folder for everyone using it.");
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
                state = EState::EnterDetails;
            }
        }

        if(state == EState::EnterDetails) {
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
                state = EState::SavedConfirmation;
            }
        }
        
        if(state == EState::SavedConfirmation) {
            UI::Text(Icons::Check + " Created MacroPart!");
            if(UI::GreenButton("Ok")) {
                state = EState::Idle;
            }
        }
    }

    if(state != EState::Idle && state != EState::SavedConfirmation && UI::OrangeButton("Cancel creating MacroPart")) {
        windowColor = baseWindowColor;
        state = EState::Idle;
    }

    UI::End();
    UI::PopStyleVar(4);
    UI::PopStyleColor(1);
}

}