namespace Generate {
bool windowOpen = true;
vec4 baseWindowColor = vec4(.1, .1, .1, 1);
vec4 windowColor = baseWindowColor;

void RenderInterface() {
    UI::PushStyleColor(UI::Col::WindowBg, windowColor);
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(470, 880);
    if(UI::Begin("Generate track", windowOpen)) {
        RenderGenerateTrack();
    }

    UI::End();
    UI::PopStyleVar(4);
    UI::PopStyleColor(1);
}

void RenderGenerateTrack() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    GenOptions::useSeed = UI::Checkbox("Use seed", GenOptions::useSeed);
    if(GenOptions::useSeed) {
        GenOptions::seed = UI::InputText("Seed", GenOptions::seed);
    }
    GenOptions::animate = UI::Checkbox("Animate generation process", GenOptions::allowCustomItems);
    UI::TextDisabled("Track generation is more restricted with airmode turned off, because the wood supports can get in the way.");
    GenOptions::airMode = UI::Checkbox("Use airmode to place blocks", GenOptions::allowCustomItems);
    // -------- Include tags ------------
    UI::TextDisabled("Parts must include one of the following tags:");
    string iTagsString = "";
    if(GenOptions::includeTags.Length == 0) 
        iTagsString = "No tags selected";
    for(uint i = 0; i < GenOptions::includeTags.Length; i++) {
        if(i != 0) iTagsString += ", ";
        iTagsString += GenOptions::includeTags[i];
    }
    UI::PushID("includeTags");
    if(UI::BeginCombo("Tags", iTagsString)) {
        for(uint i = 0; i < availableTags.Length; i++) {
            int foundIndex = GenOptions::includeTags.Find(availableTags[i]);
            if(UI::Selectable(availableTags[i], foundIndex != -1)) {
                if(foundIndex != -1)
                    GenOptions::includeTags.RemoveAt(foundIndex);
                else
                    GenOptions::includeTags.InsertLast(availableTags[i]);
            }
        }
        UI::EndCombo();
    }
    if(UI::Button("Clear")) {
        GenOptions::ClearIncludeTags();
    }
    UI::SameLine();
    if(UI::Button("Reset")) {
        GenOptions::ResetIncludeTags();
    }
    UI::PopID();

    // -------- Exclude tags ------------
    UI::TextDisabled("Parts may not include any of the following tags:");
    string eTagsString = "";
    if(GenOptions::excludeTags.Length == 0) 
        eTagsString = "No tags selected";
    for(uint i = 0; i < GenOptions::excludeTags.Length; i++) {
        if(i != 0) eTagsString += ", ";
        eTagsString += GenOptions::excludeTags[i];
    }
    UI::PushID("excludeTags");
    if(UI::BeginCombo("Tags", eTagsString)) {
        for(uint i = 0; i < availableTags.Length; i++) {
            int foundIndex = GenOptions::excludeTags.Find(availableTags[i]);
            if(UI::Selectable(availableTags[i], foundIndex != -1)) {
                if(foundIndex != -1)
                    GenOptions::excludeTags.RemoveAt(foundIndex);
                else
                    GenOptions::excludeTags.InsertLast(availableTags[i]);
            }
        }
        UI::EndCombo();
    }
    if(UI::Button("Clear")) {
        GenOptions::ClearExcludeTags();
    }
    UI::PopID();

    // -------- Difficulties ------------
    UI::TextDisabled("Allowed difficulties:");
    string difficultiesString = "";
    for(uint i = 0; i < GenOptions::difficulties.Length; i++) {
        if(i != 0) difficultiesString += ", ";
        difficultiesString += tostring(GenOptions::difficulties[i]);
    }
    if(UI::BeginCombo("Difficulty", difficultiesString)) {
        for(uint i = 0; i < availableDifficulties.Length; i++) {
            int foundIndex = GenOptions::difficulties.Find(availableDifficulties[i]);
            if(UI::Selectable(tostring(availableDifficulties[i]), foundIndex != -1)) {
                if(foundIndex != -1)
                    GenOptions::difficulties.RemoveAt(foundIndex);
                else
                    GenOptions::difficulties.InsertLast(availableDifficulties[i]);
            }
        }
        UI::EndCombo();
    }

    GenOptions::allowCustomItems = UI::Checkbox("Allow custom items", GenOptions::allowCustomItems);
    GenOptions::allowCustomBlocks = UI::Checkbox("Allow custom blocks", GenOptions::allowCustomBlocks);
    GenOptions::respawnable = UI::Checkbox("Parts must be respawnable", GenOptions::respawnable);
    GenOptions::considerSpeed = UI::Checkbox("Consider speed when connecting parts", GenOptions::considerSpeed);
    if(GenOptions::considerSpeed) {
        UI::TextDisabled("Maximum difference in speed between parts.");
        GenOptions::maxSpeedVariation = Math::Clamp(UI::InputInt("Max speed difference", GenOptions::maxSpeedVariation, 10), 0, 990);
    }
    GenOptions::maxSpeed = Math::Clamp(UI::InputInt("Maximum speed", GenOptions::maxSpeed, 10), 0, 999);
    GenOptions::minSpeed = Math::Clamp(UI::InputInt("Minimum speed", GenOptions::minSpeed, 10), 0, 999);
    GenOptions::desiredMapLength = Math::Clamp(UI::InputInt("Map length (seconds)", GenOptions::desiredMapLength, 10), 0, 3000);

    UI::TextDisabled("Leave author empty to allow any author.");
    GenOptions::author = UI::InputText("Author", GenOptions::author);

    if(UI::BeginCombo("Allow reuse of parts?", tostring(GenOptions::reuse))) {
        for(uint i = 0; i < availableReuses.Length; i++) 
            if(UI::Selectable(tostring(availableReuses[i]), GenOptions::reuse == availableReuses[i])) 
                GenOptions::reuse = availableReuses[i];
        UI::EndCombo();
    }

    if(UI::Button("Generate")) {
        Generate::GenerateTrack();
    }
    UI::PopTextWrapPos();
}

}