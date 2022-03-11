namespace Parts {

MacroPart@ selectedPart = null;

void PickMacroblock(CGameCtnMacroBlockInfo@ macroblock) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Macroblock;
    @editor.PluginMapType.CursorMacroblockModel = macroblock;
}

void RenderInterface() {
    if(selectedPart is null) {
        if(TMUI::Button("Refresh")) {
            Generate::Initialize();
        }
        if(UI::BeginTable("parts", (Generate::usedParts is null) ? 3 : 4)) {
            auto editor = Editor();
            if(editor is null || editor.PluginMapType is null) return;
            if(Generate::usedParts !is null)
                UI::TableSetupColumn("##useCount", UI::TableColumnFlags::WidthFixed, 5);
            UI::TableSetupColumn("##name", UI::TableColumnFlags::WidthStretch, 1);
            UI::TableSetupColumn("##filtered", UI::TableColumnFlags::WidthFixed, 10);
            UI::TableSetupColumn("##actions", UI::TableColumnFlags::WidthFixed, 160);
            // UI::TableHeadersRow();
            for(uint i = 0; i < Generate::allParts.Length; i++) {
                UI::PushID("partRow" + i);
                UI::TableNextRow();
                auto part = Generate::allParts[i];
                auto selected = editor.CurrentMacroBlockInfo !is null && part.ID == editor.CurrentMacroBlockInfo.IdName;
                RenderPartRow(part, selected);
                UI::PopID();
            }
            UI::EndTable();
        }
    } else {
        RenderPart(selectedPart);
    }
}

void EditBlocks(ref@ partRef) {
    auto part = cast<MacroPart@>(partRef);
    PickMacroblock(part.macroblock);
    yield();
    Create::EditExistingMacroPart();
}

void EditEntranceExit(ref@ partRef) {
    auto part = cast<MacroPart@>(partRef);
    PickMacroblock(part.macroblock);
    yield();
    Create::EditEntranceExit();
}

void RenderPart(MacroPart@ part) {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    if(TMUI::Button("Back to list")) {
        @selectedPart = null;
    }
    UI::SameLine();
    if(TMUI::Button(Icons::Eyedropper)) {
        PickMacroblock(part.macroblock);
    }
    TMUI::TextDisabled(part.ID);

    PartEditor(part);

    if(part.embeddedItems.Length > 0){
        UI::Text("Embedded items:");
        TMUI::TextDisabled(string::Join(part.embeddedItems, ", "));
    } else
        UI::Text("No embedded items");
        
    if(TMUI::Button("Edit blocks")) {
        startnew(EditBlocks, part);
        @selectedPart = null;
    }
    UI::SameLine();
    if(TMUI::Button("Edit entrance/exit")) {
        startnew(EditEntranceExit, part);
    }
    UI::SameLine();
    if(TMUI::Button("Save changes")) {
        Create::SaveMacroPart(part, false);
        @selectedPart = null;
    }
    UI::PopTextWrapPos();
}

void RenderPartRow(MacroPart@ part, bool selected) {
    string reason = string(Generate::filterReasons[part.ID]);

    if(Generate::usedParts !is null) { 
        UI::PushStyleVar(UI::StyleVar::ItemInnerSpacing, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(0, 0));
        int useCount = int(Generate::usedParts[part.ID]);
        UI::TableNextColumn();
        TMUI::TextDisabled(tostring(useCount));
        UI::PopStyleVar(3);
        if(UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("Use count in previously generated track");
            UI::EndTooltip();
        }
    }

    UI::TableNextColumn();
    if(selected) {
        UI::Text(Icons::Eyedropper);
        UI::SameLine();
    }
    if(part.type == EPartType::Finish) {
        UI::Text("\\$e22" + Icons::FlagCheckered);
        UI::SameLine();
    }
    if(part.type == EPartType::Start) {
        UI::Text("\\$3f3" + Icons::PlusCircle);
        UI::SameLine();
    }
    UI::Text(part.name);
    TMUI::TextDisabled(part.author);

    UI::TableNextColumn();
    UI::Dummy(vec2(1, 0));
    if(reason == "") {
        UI::Text("\\$3f3" + Icons::Check);
    } else {
        UI::Text("\\$f80" + Icons::Times);
    }
    if(reason != "" && UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(reason);
        UI::EndTooltip();
    }
    
    UI::TableNextColumn();
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(4, 5));
    auto listIndex = GenOptions::disabledParts.Find(part.ID);
    bool isInList = listIndex != -1;
    auto checkValue = UI::Checkbox("##check", !isInList);
    if(checkValue == isInList) {
        print("Toggle");
        if(isInList) {
            GenOptions::disabledParts.RemoveAt(listIndex);
        } else {
            GenOptions::disabledParts.InsertLast(part.ID);
        }
        GenOptions::OnChange();
    }
    if(UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(isInList ? "Enable MacroPart" : "Disable MacroPart");
        UI::EndTooltip();
    }
    UI::SameLine();
    if(UI::Button(Icons::Eyedropper)) {
        PickMacroblock(part.macroblock);
    }
    if(UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text("Select macroblock");
        UI::EndTooltip();
    }
    UI::SameLine();
    if(UI::Button(Icons::Pencil)) {
        @selectedPart = part;
    }
    if(UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text("Edit MacroPart");
        UI::EndTooltip();
    }
    UI::SameLine();
    if(UI::RedButton(Icons::Trash)) {
        Create::DeleteMacroblock(part.ID);
        Generate::Initialize();
    }
    if(UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text("Delete MacroPart");
        UI::EndTooltip();
    }
    UI::PopStyleVar(1);
}

}