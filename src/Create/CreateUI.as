namespace Create {
string failureReason = "";
float mouseX = 0;
float mouseY = 0;
vec4 lightTextColor = vec4(1, 1, 1, .8);
vec4 textColor = vec4(1, 1, 1, 1);
vec4 shadowColor = vec4(0, 0, 0, 1);
vec4 buttonBackdropColor = vec4(61. / 255, 61. / 255, 61. / 255, 237. / 255);
string hintText = "";

void RenderNativeUI() {
    if(state == EState::SelectBlocks)
        hintText = "Select the blocks for this part, press " + Icons::Kenney::Save + " button when done.";
    if(state == EState::SelectPlacement)
        hintText = "Click to place the macroblock in the map. It will not destroy any existing blocks.";
    if(state == EState::EditBlocks)
        hintText = "Edit blocks in the macroblock, select all and click " + Icons::Kenney::Save + " to continue.";
    if(state == EState::SelectEntrance) 
        hintText = "Select the position the car enters this part";
    if(state == EState::SelectExit)
        hintText = "Select the position the car exits this part";
    if(state == EState::AirMode) 
        hintText += "Click to place a macroblock in the map using air block mode.";
    
    
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    float scaleX = float(Draw::GetWidth()) / 2560;
    float scaleY = float(Draw::GetHeight()) / 1440;
    auto mousePos = UI::GetMousePos();
    mouseX = mousePos.x / float(Draw::GetWidth());
    mouseY = mousePos.y / float(Draw::GetHeight());
    nvg::Save();
    nvg::Scale(scaleX, scaleY);
    RenderHintText();
    hintText = "";

    if(nativeButtons) {
        for(uint i = 0; i < Button::list.Length; i++){
            Button::list[i].visible = false;
            Button::list[i].isHovered = false;
        }
        auto placeMode = editor.PluginMapType.PlaceMode;

        if(!editor.PluginMapType.HideInventory) {
            if(placeMode == CGameEditorPluginMap::EPlaceMode::CopyPaste) {
                if(state == EState::Idle || state == EState::Failed) {
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
                if(editor.CurrentMacroBlockInfo !is null) {
                    Button::mtgAirmode.visible = true;
                }
                Button::mtgClear.visible = true;
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
    for(uint i = 0; i < Button::list.Length; i++) {
        nvg::FontFace(Fonts::droidSansBold);
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
            nvg::FontFace(Fonts::montserratRegular);
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

    if(state != EState::Idle && state != EState::Failed && TMUI::Button("Cancel creating MacroPart")) {
        CleanUp();
        state = EState::Idle;
    }
}

void RenderFailedState() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    UI::Text("Something went wrong!");
    string[] reasons = failureReason.Split('\n');
    for(uint i = 0; i < reasons.Length; i++) {
        UI::Text(reasons[i]);
    }
    if(TMUI::Button("Go back")) {
        state = EState::Idle;
    }
    UI::PopTextWrapPos();
}

void RenderIdleState() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    UI::Text("Randomly generated tracks consist of 'MacroParts'. These are macroblocks with extra embedded information to help the generator connect parts together.");
    TMUI::TextDisabled("Your available MacroParts can be found in the macroblocks tab below (F4), in the folder '" + macroPartFolder + "'.");
    UI::NewLine();
    if(nativeButtons) {
        UI::Text("Click the " + Icons::FilePowerpointO + " button in the copy paste menu (C) to create a MacroPart.");
    } else {
        if(TMUI::Button("Create part")) {
            CreateNewMacroPart();
        }
        UI::SameLine();
        if(TMUI::Button("Edit part")) {
            EditExistingMacroPart();
        }
    }

    // Explainer
    if(UI::CollapsingHeader("Tips for creating parts")) {
        UI::Text("MacroParts need to be built in a certain way, look at the existing parts to get an idea of what they should look like. Parts are generally about 5 second parts of a track with a set entrance and exit speed.");
        UI::Separator();
        if(UI::CollapsingHeader("General tips")) {
            TMUI::TextDisabled("Important tips");
            UI::Text("● Blocks may not connect to the ground, so when placing blocks always use air mode.");
            UI::Text("● Free placed blocks don't work when generating tracks, so don't use them. Free placed items and ghost blocks work fine.");
            UI::Text("● All connector roads (end / start) must be flat, because checking for connectivity between parts doesn't work when banked roads/platforms are involved.");
            UI::Text("● Bobsleigh entrance/exit connector must be placed at the height of the road borders.");
            UI::Text("● Give some space (2-3 blocks) at the start of your part to let the driver adjust their line.");
            UI::Separator();
            TMUI::TextDisabled("Less important tips");
            UI::Text("● When placing platforms, try to place 1 layer of wood supports under them (folder 13), otherwise platforms generated directly below your platform part might automatically connect and make the track undrivable.");
            UI::Text("● Mediatracker works, try to put cam3 in loopings and such. Always reset any mediatracker effects at the end of your part.");
            UI::Text("● When using effects on the car (reactor, engine off, cruise, water wheels, etc.) remember to reset them at the end of your part.");
            UI::Text("● Uphill/downhill road turns destroy the block below them in some situations even though the placement is green, you can prevent this by placing any block below uphill/downhill road turns. The generator does a check after generating to see if this bug happened and informs the user.");
            UI::Text("● Short parts are more likely to be used by the track generator, because they are more likely to physically fit in the map.");
            UI::Text("● Keep in mind there is quite a bit of speed variation (+/- 60) with which drivers enter your part, don't make extremely precise transitions or speedchecks based on the speed you enter the part with.");
            UI::Text("● If you notice your part is almost never used by the generator, check the connectivity of the part in the parts list. If very few other parts can connect to your part it's not likely to be used. You can fix this by creating parts which can connect to your part.");
            UI::Text("● The optimized magnet blocks by BE_Doomsday need to receive a block update after generating, or they will not be magnetic. Other magnet items might be better for use in MacroParts.");
            UI::Text("● If you only create parts that go uphill, the track generator will get stuck at the top of the map when generating long maps.");
        }
        UI::Separator();
        if(UI::CollapsingHeader("Prevent part from intersecting other parts.")) {
            UI::Text("The plugin checks if it can place a MacroPart by checking if the placement in that position is 'green', the same as you can see in game when trying to place a macroblock somewhere. Because of this you need to be careful when using items or ghost blocks, because they can be green while intersecting with other parts, making them undrivable. You always need to keep this in mind when creating new parts, because if a road can cross somewhere it shouldn't, then it will eventually do that, and make the track undrivable.");
            UI::Separator();
            UI::Text("● When using items or ghost blocks for driving surface, place 12-5-4-1 or any other block (hidden) inside those items to prevent other blocks from intersecting with your item / ghost block.");
            UI::Text("● When using track walls as roads (folder 13), keep in mind roads can be placed in the driving route, meaning you need to place 12-5-4-1 or any other block to prevent other blocks from intersecting the driving line.");
            UI::Text("● Jumps also need to be covered by blocks, signs, 12-5-4-1, 12-6-1, and blocks from 12-5-1 can help prevent other parts from routing through the jumping line.");
            UI::Text("● Technics (folder 12) always generate as they look on the thumbnail icon, however placing them in air mode they might look different. For example, 12-5-1-5 placed in air mode has no X in the middle, the generated version of the part will have it.");
        }
    }

    UI::PopTextWrapPos();
}

void RenderSelectBlockState() {  
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
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

    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    auto coord = editor.PluginMapType.CursorCoord;
    auto absEntrance = DirectedPosition(coord.x, coord.y, coord.z, editor.PluginMapType.CursorDir);
    auto relCoord = MTG::ToRelativePosition(partDetails.macroblock, macroPlace, absEntrance);
    UI::Text(relCoord.ToPrintString());

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
    UI::Text("Embedding the following items and blocks in the macroblock");
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    UI::TextDisabled('It is recommended to only embed items and blocks from the preset location: "zzz_ImportedItems/SetName/ItemName.Item.Gbx" when sharing parts.');
    UI::TextDisabled("When sharing a MacroPart the custom items and blocks need to be in the exact same folder for everyone using it.");
    UI::BeginChild("CustomItemsList", vec2(UI::GetWindowContentRegionWidth(), 300));
    for(int i = int(partDetails.embeddedItems.Length) - 1; i >= 0; i--) {
        if(UI::RedButton(Icons::Trash)) {
            partDetails.embeddedItems.RemoveAt(i);
        }
        UI::SameLine();
        UI::Text(partDetails.embeddedItems[i]);
    }
    UI::EndChild();
    UI::PopTextWrapPos();

    if(TMUI::Button("Confirm items")) {
        state = EState::EnterDetails;
    }
}

void RenderEnterDetailsState() {
    UI::Text("Enter MacroPart information");
    PartEditor(partDetails);

    if(TMUI::Button("Save MacroPart")) {
        auto id = SaveMacroPart(partDetails);
        if(id == "") return;
        state = EState::Idle;
        print("ID of new macropart: " + id);
        auto part = MTG::PartFromID(id);
        if(part !is null)
            Parts::PickMacroblock(part.macroblock);
        Generate::selectedTabIndex = 2;
    }
}

}