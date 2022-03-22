namespace Parts {

class PartFolderTuple {
    MacroPart@ part = null;
    string folder = "";
};

MacroPart@ selectedPart = null;

void PickMacroblock(CGameCtnMacroBlockInfo@ macroblock) {
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    editor.PluginMapType.PlaceMode = CGameEditorPluginMap::EPlaceMode::Macroblock;
    @editor.PluginMapType.CursorMacroblockModel = macroblock;
}

void DisableFolder(const string &in folder, int startIndex = 0) {
    bool foundFolder = false;
    for(uint i = startIndex; i < Generate::allParts.Length; i++) {
        auto part = Generate::allParts[i];
        if(part.folder.StartsWith(folder)) {
            foundFolder = true;
            GenOptions::disabledParts.InsertLast(part.ID);
        } else if(foundFolder) {
            break;
        }
    }
    if(folder != "" && GenOptions::disabledFolders.Find(folder) == -1)
        GenOptions::disabledFolders.InsertLast(folder);
}

void EnableFolder(const string &in folder) {
    bool foundFolder = false;
    for(int i = int(GenOptions::disabledParts.Length) - 1; i >= 0; i--) {
        auto part = MTG::PartFromID(GenOptions::disabledParts[i]);
        if(part.folder.StartsWith(folder)) {
            foundFolder = true;
            GenOptions::disabledParts.RemoveAt(i);
        }
    }
    auto index = GenOptions::disabledFolders.Find(folder);
    if(index != -1)
        GenOptions::disabledFolders.RemoveAt(index);
}

void RenderInterface() {
    if(selectedPart is null) {
        if(TMUI::Button("Refresh")) {
            Generate::Initialize();
        }
        UI::SameLine();
        if(TMUI::Button("Disable all")) {
            auto folders = Generate::folders.GetKeys();
            for(uint i = 0; i < folders.Length; i++) {
                auto folder = folders[i];
                DisableFolder(folder, i);
            }
            GenOptions::OnChange();
        }
        UI::SameLine();
        if(TMUI::Button("Enable all")) {
            GenOptions::disabledParts = {};
            GenOptions::disabledFolders = {};
            GenOptions::OnChange();
        }
        UI::SameLine();
        if(TMUI::Button(Icons::Random)) {
            GenOptions::disabledParts = {};
            GenOptions::disabledFolders = {};
            for(uint i = 0; i < Generate::allParts.Length; i++) {
                auto part = Generate::allParts[i];
                if(Random::Float() > 0.6) {
                    GenOptions::disabledParts.InsertLast(part.ID);
                }
            }
            GenOptions::OnChange();
        }
        if(UI::BeginTable("parts", 4)) {
            auto editor = Editor();
            if(editor is null || editor.PluginMapType is null) return;
            UI::TableSetupColumn("##useCount", UI::TableColumnFlags::WidthFixed, partsListInfo == PartsListInfo::Connectivity ? 45 : 5);
            UI::TableSetupColumn("##name", UI::TableColumnFlags::WidthStretch, 1);
            UI::TableSetupColumn("##filtered", UI::TableColumnFlags::WidthFixed, 10);
            UI::TableSetupColumn("##actions", UI::TableColumnFlags::WidthFixed, 160);
            // UI::TableHeadersRow();

            UI::ListClipper clipper(Generate::rows.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::PushID("partRow" + i);
                    auto tup = Generate::rows[i];
                    if(tup.part is null) {
                        UI::TableNextRow();
                        RenderSeperatorRow(tup.folder);
                    } else {
                        auto selected = editor.CurrentMacroBlockInfo !is null && tup.part.ID == editor.CurrentMacroBlockInfo.IdName;
                        UI::TableNextRow();
                        RenderPartRow(tup.part, selected);
                    }
                    UI::PopID();
                }
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

void RenderConnectivity(MacroPart@ part, bool short = false) {
    string prefix = short ? "" : "Connectivity: ";
    if(part.type == EPartType::Finish) 
        UI::Text(prefix + int(Generate::partsEntranceConnections[part.ID]) + " "+Icons::Forward);
    else if(part.type == EPartType::Start) 
        UI::Text(prefix + Icons::Forward+" " + int(Generate::partsExitConnections[part.ID]));
    else
        UI::Text(prefix + int(Generate::partsEntranceConnections[part.ID]) + " "+Icons::Forward+" " + int(Generate::partsExitConnections[part.ID]));
    if(UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text("The amount of parts that can connect before and after this part.");
        UI::EndTooltip();
    }
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

    if(Generate::partsEntranceConnections.Exists(part.ID) && Generate::partsExitConnections.Exists(part.ID)) {
        RenderConnectivity(part);
    }

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

void RenderSeperatorRow(const string &in folder) {
    UI::TableNextColumn();

    UI::TableNextColumn();
    UI::Separator();
    UI::Text(folder);
    UI::Separator();
    
    UI::TableNextColumn();
    UI::TableNextColumn();
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(4, 5));

    auto listIndex = GenOptions::disabledFolders.Find(folder);
    bool isInList = listIndex != -1;
    auto checkValue = UI::Checkbox("##separatorCheck", !isInList);
    if(checkValue == isInList) {
        print("Toggle");
        if(isInList) {
            EnableFolder(folder);
        } else {
            DisableFolder(folder);
        }
        GenOptions::OnChange();
    }
    if(UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(isInList ? "Enable Set" : "Disable Set");
        UI::EndTooltip();
    }

    UI::PopStyleVar(1);
}

void RenderPartRow(MacroPart@ part, bool selected) {
    string reason = "";
    if(Generate::filterReasons !is null) {
        reason = string(Generate::filterReasons[part.ID]);
    }

    UI::TableNextColumn();
    if(partsListInfo == PartsListInfo::UsedCount && Generate::usedParts !is null) { 
        UI::PushStyleVar(UI::StyleVar::ItemInnerSpacing, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(0, 0));
        int useCount = int(Generate::usedParts[part.ID]);
        TMUI::TextDisabled(tostring(useCount));
        UI::PopStyleVar(3);
        if(UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("Use count in previously generated track");
            UI::EndTooltip();
        }
    } else if(partsListInfo == PartsListInfo::Connectivity && Generate::partsEntranceConnections !is null && Generate::partsExitConnections !is null) {
        UI::PushStyleVar(UI::StyleVar::ItemInnerSpacing, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(0, 0));
        RenderConnectivity(part, true);
        UI::PopStyleVar(3);
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