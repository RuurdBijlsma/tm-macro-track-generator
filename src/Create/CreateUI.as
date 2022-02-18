namespace Create {
bool windowOpen = true;
string failureReason = "";
vec4 baseWindowColor = vec4(.1, .1, .1, 1);
vec4 windowColor = baseWindowColor;

void RenderInterface() {
    UI::PushStyleColor(UI::Col::WindowBg, windowColor);
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(500, 364);
    if(UI::Begin("Create MacroPart", windowOpen)) {
        if(state == EState::Failed) 
            RenderFailedState();

        if(state == EState::Idle) 
            RenderIdleState();

        if(state == EState::SelectBlocks)
            RenderSelectBlockState();

        if(state == EState::SelectPlacement)
            RenderSelectPlacementState();

        if(state == EState::SelectEntrance)
            RenderSelectConnectorState(true);

        if(state == EState::SelectExit)
            RenderSelectConnectorState(false);

        if(state == EState::ConfirmItems)
            RenderConfirmItemsState();

        if(state == EState::EnterDetails)
            RenderEnterDetailsState();
        
        if(state == EState::SavedConfirmation)
            RenderSavedConfirmationState();
    }

    if(state != EState::Idle && state != EState::SavedConfirmation && UI::OrangeButton("Cancel creating MacroPart")) {
        PlaceBackMap();
        windowColor = baseWindowColor;
        state = EState::Idle;
    }

    UI::End();
    UI::PopStyleVar(4);
    UI::PopStyleColor(1);
}

void RenderFailedState() {
    UI::Text("Something went wrong!");
    UI::Text(failureReason);
    if(UI::Button("Go back")) {
        state = EState::Idle;
    }
}

void RenderIdleState() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    UI::Text("Randomly generated tracks consist of 'MacroParts'. These are macroblocks with extra embedded information to help the generator connect parts together.");
    UI::TextDisabled("Your available MacroParts can be found in the macroblocks tab below (F4), in the folder '" + macroPartFolder + "'.");
    UI::PopTextWrapPos();            
    if(UI::Button("Create new MacroPart")) {
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
    if(UI::Button("Edit existing MacroPart")) {
        // Reset variables
        @partDetails = null;
        copiedMap = false;
        @macroPlace = null;
        changedSaveAsFilename = false;

        editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Macroblock;
        isEditing = true;
        state = EState::SelectPlacement;
    }
}

void RenderSelectBlockState() {  
    auto currentFrame = app.BasicDialogs.Dialogs.CurrentFrame;
    if(currentFrame !is null && currentFrame.IdName == 'FrameDialogSaveAs') {
        if(!changedSaveAsFilename) {
            changedSaveAsFilename = true;
            startnew(SelectNewMacroblock);
        }
    } else {
        UI::Text("Select the blocks for this part, click the " + Icons::Kenney::Save + " icon when done.");
        UI::TextDisabled("Only use floating blocks or items.");
        UI::TextDisabled("Don't select ground blocks.");
        auto selectCount = editor.PluginMapType.CopyPaste_GetSelectedCoordsCount();
        UI::Text("Selection size: " + selectCount);
    }
}

void RenderSelectPlacementState() {
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

void RenderSelectConnectorState(bool entrance = true) {
    auto c = editor.PluginMapType.CursorCoord;
    CGameCtnBlock@ blockInfo = editor.PluginMapType.GetBlock(int3(c.x, c.y, c.z));

    if(editor.PluginMapType.PlaceMode != CGameEditorPluginMap::EPlaceMode::CustomSelection)
        editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::CustomSelection;
    
    EConnector connector = EConnector::Platform;
    EPartType type = EPartType::Part;
    string[]@ tags = null;
    if(blockInfo !is null) {
        connector = GetConnector(blockInfo, editor.PluginMapType.CursorDir);
        @tags = GetTags(blockInfo.BlockInfo);
        partDetails.AddTags(tags);
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

    UI::TextDisabled("Hiding the map to make selection easier, it will come back!");
    UI::Text("Select position the car " + (entrance ? "enters" : "exits") + " this part");
    UI::NewLine();
    if(blockInfo is null) {
        UI::Text("Connector type can automatically be determined if an official block is selected.");
        UI::TextDisabled("Otherwise you will have to specify it later");
    } else {
        UI::Text("Auto detected values:");
        UI::TextDisabled("You can manually change these later");
        UI::TextDisabled("Connector: " + tostring(connector));
        UI::TextDisabled("Type: " + tostring(type));
        UI::TextDisabled("Tags: " + string::Join(tags, ", "));
    }
}

void RenderConfirmItemsState() {
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

void RenderEnterDetailsState() {
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
        SaveMacroPart(partDetails);
        state = EState::SavedConfirmation;
    }
}

void RenderSavedConfirmationState() {
    UI::Text(Icons::Check + " Created MacroPart!");
    if(UI::GreenButton("Ok")) {
        state = EState::Idle;
    }
}

}