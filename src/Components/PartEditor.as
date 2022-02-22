void PartEditor(MacroPart@ part) {
    part.name = UI::InputText("Name", part.name);
    UI::Text("Author:");
    UI::SameLine();
    TMUI::TextDisabled(part.author);

    TagSelector(part.tags);

    part.duration = UI::InputInt("Duration (s)", part.duration);

    if(part.type != EPartType::Start) {
        UI::TextDisabled("Can you reach the end of this part starting with 0 speed?");
        part.respawnable = TMUI::Checkbox("Respawnable", part.respawnable);
    }

    part.type = PartTypeSelector(part.type);

    part.difficulty = DifficultySelector(part.difficulty);

    UI::Text("Entrance:");
    TMUI::TextDisabled("Block: " + part.entrance.ToPrintString());
    UI::PushID('entrance');
    EntranceSelector(part);
    UI::PopID();

    UI::Text("Exit:");
    TMUI::TextDisabled("Block: " + part.exit.ToPrintString());
    UI::PushID('exit');
    ExitSelector(part);
    UI::PopID();
}