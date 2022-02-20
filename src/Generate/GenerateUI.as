namespace Generate {
bool windowOpen = true;
vec4 baseWindowColor = vec4(19. / 255, 18. / 255, 22. / 255, 1);
vec4 windowColor = baseWindowColor;
int selectedTabIndex = 0;

void RenderInterface() {
    vec4 color = vec4(.8, 0.3, 0, 1);

    UI::PushStyleColor(UI::Col::FrameBg , vec4(1, 1, 1, 0.03));
    UI::PushStyleColor(UI::Col::FrameBgHovered, color * vec4(1.7f, 1.7f, 1.7f, 0.2f));
    UI::PushStyleColor(UI::Col::FrameBgActive, color * vec4(1.7f, 1.7f, 1.7f, 0.4f));
    UI::PushStyleColor(UI::Col::ChildBg, vec4(1, 1, 1, .007));
    UI::PushStyleColor(UI::Col::Tab, color * vec4(0.5f, 0.5f, 0.5f, 0.75f));
    UI::PushStyleColor(UI::Col::TabHovered, color * vec4(1.2f, 1.2f, 1.2f, 0.85f));
    UI::PushStyleColor(UI::Col::TabActive, color);
    UI::PushStyleColor(UI::Col::Header, color * vec4(0.5f, 0.5f, 0.5f, 0.75f));
    UI::PushStyleColor(UI::Col::HeaderHovered, color * vec4(1.2f, 1.2f, 1.2f, 0.85f));
    UI::PushStyleColor(UI::Col::HeaderActive, color);
    UI::PushStyleColor(UI::Col::Separator, color * vec4(1.7f, 1.7f, 1.7f, 0.5));
    UI::PushStyleColor(UI::Col::Button, color * vec4(1.7f, 1.7f, 1.7f, 0.5f));
    UI::PushStyleColor(UI::Col::ButtonHovered, color * vec4(1.7f, 1.7f, 1.7f, 0.5f));
    UI::PushStyleColor(UI::Col::ButtonActive, color * vec4(1.7f, 1.7f, 1.7f, 0.7f));
    UI::PushStyleColor(UI::Col::TextSelectedBg, color * vec4(1.7f, 1.7f, 1.7f, 0.3f));
    UI::PushStyleColor(UI::Col::CheckMark, color * vec4(1.7f, 1.7f, 1.7f, 0.8f));

    UI::PushStyleColor(UI::Col::TitleBg, windowColor * vec4(1.1, 1.1, 1.1, 1));
    UI::PushStyleColor(UI::Col::TitleBgActive, windowColor * vec4(1.5, 1.5, 1.5, 1));
    UI::PushStyleColor(UI::Col::WindowBg, windowColor);

    UI::PushStyleVar(UI::StyleVar::ChildRounding, 5.0);
    UI::PushStyleVar(UI::StyleVar::CellPadding, vec2(12, 6));

    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(500, 738);
    if(UI::Begin("Macro Track Generator", windowOpen)) {
        RenderGenerateTrack();
    }

    UI::End();
    UI::PopStyleVar(6);
    UI::PopStyleColor(19);
}

void RenderGenerateTrack() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());
    UI::BeginTabBar("gentabs");
    bool showGenerateButtons = true;
    int flags = 0;
    if(selectedTabIndex == 0) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Generation", flags)) {
        RenderGenerationOptions();
        UI::EndTabItem();
    }
    flags = 0;
    if(selectedTabIndex == 1) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Filter", flags)) {
        RenderFilterOptions();
        UI::EndTabItem();
    }
    flags = 0;
    if(selectedTabIndex == 2) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Create parts", flags)) {
        showGenerateButtons = false;
        Create::RenderInterface();
        UI::EndTabItem();
    }
    UI::EndTabBar();

    if(showGenerateButtons){ 
        UI::Text("With this configuration, there are:");
        UI::TextDisabled(Generate::startCount + " start parts");
        UI::TextDisabled(Generate::partCount + " parts");
        UI::TextDisabled(Generate::finishCount + " finish parts");

        if(Generate::lastGenerateFailed) {
            UI::Text(Icons::ExclamationTriangle + " Track failed to generate!");
        } else {
            UI::Text("");
        }

        bool canGenerate = Generate::startCount > 0 && Generate::finishCount > 0;
        if(!canGenerate)
            UI::BeginDisabled();
        if(Generate::isGenerating) {
            if(UI::IsKeyPressed(UI::Key::V)) {
                Generate::canceled = true;
            }
            if(UI::RedButton(GetHourGlass() + ' "V" to cancel')) {
                Generate::canceled = true;
            }
        } else {
            if(UI::GreenButton(Icons::Random + " Generate"))
                startnew(Generate::GenerateTrack);
        }
        if(!canGenerate)
            UI::EndDisabled();
        UI::SameLine();
        if(UI::Button("Reset to default")) {
            GenOptions::ResetToDefault();
        }
    }

    UI::PopTextWrapPos();
}

void RenderGenerationOptions() {
    GenOptions::useSeed = UI::Checkbox("Use seed", GenOptions::useSeed);
    if(GenOptions::useSeed) {
        GenOptions::seed = UI::InputText("Seed", GenOptions::seed);
    }
    GenOptions::animate = UI::Checkbox("Animate generation process", GenOptions::animate);
    UI::TextDisabled("The generation process is much slower when animating.");
    GenOptions::airMode = UI::Checkbox("Use airmode to place blocks", GenOptions::airMode);
    UI::TextDisabled("Track generation is more restricted with airmode turned off, because the wood supports can get in the way.");
}

void RenderFilterOptions() {
    // -------- Include tags ------------
    UI::TextDisabled("Parts must include one of the following tags (empty for all tags):");
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
                GenOptions::OnChange();
            }
        }
        UI::EndCombo();
    }
    if(GenOptions::includeTags.Length > 0) {
        UI::SameLine();
        if(UI::Button(Icons::Times)) {
            GenOptions::ClearIncludeTags();
            GenOptions::OnChange();
        }
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("Clear tags");
            UI::EndTooltip();
        }
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
                GenOptions::OnChange();
            }
        }
        UI::EndCombo();
    }
    if(GenOptions::excludeTags.Length > 0) {
        UI::SameLine();
        if(UI::Button(Icons::Times)) {
            GenOptions::ClearExcludeTags();
            GenOptions::OnChange();
        }
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("Clear tags");
            UI::EndTooltip();
        }
    }
    UI::PopID();

    // -------- Difficulties ------------
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
                GenOptions::OnChange();
            }
        }
        UI::EndCombo();
    }

    GenOptions::allowCustomItems = UI::Checkbox("Custom items", GenOptions::allowCustomItems);
    UI::SameLine();
    GenOptions::allowCustomBlocks = UI::Checkbox("Custom blocks", GenOptions::allowCustomBlocks);
    GenOptions::respawnable = UI::Checkbox("Parts must be respawnable", GenOptions::respawnable);
    GenOptions::considerSpeed = UI::Checkbox("Consider speed when connecting parts", GenOptions::considerSpeed);
    if(GenOptions::considerSpeed) {
        UI::TextDisabled("Maximum difference in speed between parts:");
        GenOptions::maxSpeedVariation = Math::Clamp(UI::InputInt("Max speed difference", GenOptions::maxSpeedVariation, 10), 0, 990);
    }
    GenOptions::maxSpeed = Math::Clamp(UI::InputInt("Maximum speed", GenOptions::maxSpeed, 10), GenOptions::minSpeed + 10, 1000);
    GenOptions::minSpeed = Math::Clamp(UI::InputInt("Minimum speed", GenOptions::minSpeed, 10), 0, GenOptions::maxSpeed - 10);
    GenOptions::desiredMapLength = Math::Clamp(UI::InputInt("Map length (seconds)", GenOptions::desiredMapLength, 10), 0, 3000);

    GenOptions::author = UI::InputText("Author", GenOptions::author);
    UI::TextDisabled("Leave author empty to allow any author.");

    if(UI::BeginCombo("Allow reuse of parts?", tostring(GenOptions::reuse))) {
        for(uint i = 0; i < availableReuses.Length; i++) 
            if(UI::Selectable(tostring(availableReuses[i]), GenOptions::reuse == availableReuses[i])) 
                GenOptions::reuse = availableReuses[i];
        UI::EndCombo();
    }
    if(GenOptions::reuse == EReuse::PreferNoReuse) {
        UI::TextDisabled('"Prefer no reuse" reduces randomness of tracks.');
    } else { 
        UI::Text("");
    }
}

}