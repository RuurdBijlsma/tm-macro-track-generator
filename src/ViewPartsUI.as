namespace Parts {

MacroPart@ selectedPart = null;

void RenderInterface() {
    if(selectedPart is null) {
        if(UI::BeginTable("parts", 3)) {
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch, 1);
            UI::TableSetupColumn("Matches filter", UI::TableColumnFlags::WidthFixed, 90);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 130);
            // UI::TableHeadersRow();
            for(uint i = 0; i < Generate::allParts.Length; i++) {
                UI::PushID("partRow" + i);
                UI::TableNextRow();
                auto part = Generate::allParts[i];
                RenderPartRow(part);
                UI::PopID();
            }
            UI::EndTable();
        }
    } else {
        RenderPart(selectedPart);
    }
}

void RenderPart(MacroPart@ part) {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    if(UI::Button("Back to list")) {
        @selectedPart = null;
    }
    TMUI::TextDisabled(part.macroblock.IdName);

    PartEditor(part);

    if(part.embeddedItems.Length > 0){
        UI::Text("Embedded items:");
        TMUI::TextDisabled(string::Join(part.embeddedItems, ", "));
    } else
        UI::Text("No embedded items");
        
    if(TMUI::Button("Save changes")) {
        Create::SaveMacroPart(part);
    }
    UI::SameLine();
    if(TMUI::Button("Edit entrance / exit block")) {
        print("edit");
    }
    UI::PopTextWrapPos();
}

void RenderPartRow(MacroPart@ part) {
    int useCount = 0;
    if(Generate::usedParts !is null)
        useCount = int(Generate::usedParts[part.ID]);
    string reason = string(Generate::filterReasons[part.ID]);

    UI::TableNextColumn();
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
    if(TMUI::Button(Icons::Info)) {
        @selectedPart = part;
    }
    UI::SameLine();
    if(TMUI::RedButton(Icons::Trash)) {
        print("trash");
    }
}

}