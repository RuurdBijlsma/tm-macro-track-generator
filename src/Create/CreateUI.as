namespace Create {
bool windowOpen = true;
string failureReason = "";
vec4 baseWindowColor = vec4(19. / 255, 18. / 255, 22. / 255, 1);
vec4 windowColor = baseWindowColor;
float mouseX = 0;
float mouseY = 0;
vec4 lightTextColor = vec4(1, 1, 1, .8);
vec4 textColor = vec4(1, 1, 1, 1);
vec4 shadowColor = vec4(0, 0, 0, 1);
vec4 buttonBackdropColor = vec4(61. / 255, 61. / 255, 61. / 255, 237. / 255);
string hintText = "";

void RenderExtraUI() {
    if(state == EState::SelectBlocks){
        hintText = "Select the blocks for this part, click the " + Icons::Kenney::Save + " button when done.";
    }
    if(state == EState::SelectPlacement) {
        if(isEditing) {
            hintText = "Select the MacroPart to edit.\n";
            hintText += "Press 'V' to place the macroblock in the map. It will not destroy any existing blocks.";
        } else {
            hintText = "Click to place the macroblock in the map. It will not destroy any existing blocks.";
        }
    }
    if(state == EState::SelectEntrance) 
        hintText = "Select the position the car enters this part";
    if(state == EState::SelectExit)
        hintText = "Select the position the car exits this part";
    if(state == EState::AirMode) 
        hintText += "Press 'V' to place a macroblock in the map using air block mode.";
    
    
    if(editor is null) return;
    float scaleX = float(Draw::GetWidth()) / 2560;
    float scaleY = float(Draw::GetHeight()) / 1440;
    auto mousePos = UI::GetMousePos();
    mouseX = mousePos.x / float(Draw::GetWidth());
    mouseY = mousePos.y / float(Draw::GetHeight());
    nvg::Save();
    nvg::Scale(scaleX, scaleY);
    RenderHintText();
    hintText = "";

    for(uint i = 0; i < Button::list.Length; i++){
        Button::list[i].visible = false;
        Button::list[i].isHovered = false;
    }
    auto placeMode = editor.PluginMapType.PlaceMode;

    if(!editor.PluginMapType.HideInventory) {
        if(placeMode == CGameEditorPluginMap::EPlaceMode::CopyPaste) {
            if(state == EState::Idle) {
                Button::create.visible = true;
            } else {
                Button::cancel.visible = true;
            }
        }
        if(placeMode == CGameEditorPluginMap::EPlaceMode::Block 
        || placeMode == CGameEditorPluginMap::EPlaceMode::Macroblock 
        || placeMode == CGameEditorPluginMap::EPlaceMode::FreeBlock 
        || placeMode == CGameEditorPluginMap::EPlaceMode::GhostBlock 
        || placeMode == CGameEditorPluginMap::EPlaceMode::FreeMacroblock 
        || placeMode == CGameEditorPluginMap::EPlaceMode::Item) {
            RenderMTGBackdrop();
            if(editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::Macroblock || editor.PluginMapType.PlaceMode == CGameEditorPluginMap::EPlaceMode::FreeMacroblock) {
                Button::mtgAirmode.visible = true;
            }
            Button::mtgGenerate.visible = true;
            if(state == EState::Idle) {
                Button::mtgCreate.visible = true;
                Button::mtgEdit.visible = true;
            } else {
                Button::mtgCancel.visible = true;
            }
        }
        RenderButtons();
    }
    nvg::Restore();
}

void RenderHintText() {
    if(hintText == "") return;
    nvg::FontFace(Fonts::droidSansBold);
    nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
    nvg::FontSize(40);
    nvg::FillColor(shadowColor);
    nvg::Text(1280 - 2, 200 + 2, hintText);
    nvg::FillColor(textColor);
    nvg::Text(1280, 200, hintText);
}

void RenderButtons() {
    nvg::FontFace(Fonts::droidSansBold);
    for(uint i = 0; i < Button::list.Length; i++) {
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        auto button = Button::list[i];
        if(!button.visible) continue;
        nvg::FontSize(button.fontSize);
        float x = float(button.x) / 2560;
        float y = float(button.y) / 1440;
        float left = x - float(button.width) / 2560 / 2;
        float top = y - float(button.height) / 1440 / 2;
        float right = x + float(button.width) / 2560 / 2;
        float bottom = y + float(button.height) / 1440 / 2;
        button.isHovered = mouseX > left && mouseX < right && mouseY > top && mouseY < bottom;
        nvg::FillColor(button.isHovered ? button.hoverColor : button.color);
        nvg::Text(button.x, button.y, button.label);
        if(button.isHovered && button.hintText != "") {
            nvg::FontSize(25);
            nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
            nvg::FontFace(Fonts::droidSansRegular);
            nvg::FillColor(lightTextColor);
            nvg::Text(1661, 1403, button.hintText);
        }
    }
}

void RenderMTGBackdrop() {
    nvg::BeginPath();
    nvg::RoundedRectVarying(57, 937, 335, 84, 20, 0, 20, 0);
    nvg::FillColor(buttonBackdropColor);
    nvg::Fill();
    nvg::ClosePath();
    nvg::FontSize(21);
    nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
    nvg::FontFace(Fonts::droidSansRegular);
    nvg::FillColor(shadowColor);
    nvg::Text(385 + 1, 956 + 1, "Macro Track Generator");
    nvg::FillColor(lightTextColor);
    nvg::Text(385, 956, "Macro Track Generator");
}

void RenderAirBlockButton() {

}

void RenderInterface() {
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

    if(state != EState::Idle && state != EState::SavedConfirmation && UI::OrangeButton("Cancel creating MacroPart")) {
        CleanUp();
        state = EState::Idle;
    }
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
    UI::NewLine();
    UI::Text("Click the " + Icons::FilePowerpointO + " button in the copy paste menu (C) to create a MacroPart.");
    UI::PopTextWrapPos();
}

void RenderSelectBlockState() {  
    UI::Text(hintText);
    UI::TextDisabled("Only use floating blocks or items.");
    UI::TextDisabled("Don't select ground blocks.");
    auto selectCount = editor.PluginMapType.CopyPaste_GetSelectedCoordsCount();
    UI::Text("Selection size: " + selectCount);
}

void RenderSelectPlacementState() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    UI::Text(hintText);
    UI::TextDisabled("Take care not to place it too close to the map border, or custom items may not get placed.");
    UI::PopTextWrapPos();
}

void RenderSelectConnectorState(bool entrance = true) {
    UI::TextDisabled("Hiding the map to make selection easier, it will come back!");
    UI::Text(hintText);
    UI::NewLine();
    if(blockInfo is null) {
        UI::Text("Connector type can automatically be determined if an official block is selected.");
        UI::TextDisabled("Otherwise you will have to specify it later");
    } else {
        UI::Text("Auto detected values:");
        UI::TextDisabled("You can manually change these later");
        UI::TextDisabled("Connector: " + tostring(entrance ? partDetails.entranceConnector : partDetails.exitConnector));
        UI::TextDisabled("Type: " + tostring(entrance ? entranceType : exitType));
        if(detectedTags !is null)
            UI::TextDisabled("Tags: " + string::Join(detectedTags, ", "));
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
        partDetails.enterSpeed = Math::Clamp(UI::InputInt("Speed", partDetails.enterSpeed, 10), 0, 1000);
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
        partDetails.exitSpeed = Math::Clamp(UI::InputInt("Speed", partDetails.exitSpeed, 10), 0, 1000);
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