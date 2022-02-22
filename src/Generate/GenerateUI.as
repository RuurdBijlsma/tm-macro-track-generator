namespace Generate {
bool windowOpen = IsDevMode();
vec4 baseWindowColor = vec4(6. / 255, 131. / 255, 84. / 255, .97);
vec4 windowColor = baseWindowColor;
int selectedTabIndex = 0;

void RenderInterface() {
    if(!windowOpen) return;

    vec4 color = vec4(0. / 255, 165. / 255, 101. / 255, 1);
    vec4 buttonHover = vec4(0. / 255, 50. / 255, 40. / 255, 1);
    vec4 titleBg = vec4(55. / 255, 198. / 255, 125. / 255, 1);
    vec4 inputBg = vec4(5. / 255, 112. / 255, 69. / 255, 1);
    vec4 textDisabled = vec4(1, 1, 1, .6);
    vec4 textSelect = vec4(51. / 255, 51. / 255, 102. / 255, 1);
    vec4 headerHovered = vec4(16. / 255, 100. / 255, 113. / 255, 1);

    UI::PushStyleColor(UI::Col::ScrollbarGrab, color * vec4(1, 1, 1, 0.3));
    UI::PushStyleColor(UI::Col::ScrollbarGrabHovered, color * vec4(1, 1, 1, 0.6));
    UI::PushStyleColor(UI::Col::ScrollbarGrabActive, color * vec4(1, 1, 1, 0.8));
    UI::PushStyleColor(UI::Col::ResizeGrip, color * vec4(1, 1, 1, 0.3));
    UI::PushStyleColor(UI::Col::ResizeGripHovered, color * vec4(1, 1, 1, 0.6));
    UI::PushStyleColor(UI::Col::ResizeGripActive, color * vec4(1, 1, 1, 0.8));
    UI::PushStyleColor(UI::Col::TextDisabled, textDisabled);
    UI::PushStyleColor(UI::Col::FrameBg , inputBg);
    UI::PushStyleColor(UI::Col::FrameBgHovered, color * vec4(1.7f, 1.7f, 1.7f, 0.2f));
    UI::PushStyleColor(UI::Col::FrameBgActive, color * vec4(1.7f, 1.7f, 1.7f, 0.4f));
    UI::PushStyleColor(UI::Col::Tab, color * vec4(0.5f, 0.5f, 0.5f, 0.75f));
    UI::PushStyleColor(UI::Col::TabHovered, color * vec4(1.2f, 1.2f, 1.2f, 0.85f));
    UI::PushStyleColor(UI::Col::TabActive, color);
    UI::PushStyleColor(UI::Col::Header, color * vec4(0.5f, 0.5f, 0.5f, 0.75f));
    UI::PushStyleColor(UI::Col::HeaderHovered, headerHovered);
    UI::PushStyleColor(UI::Col::HeaderActive, color);
    UI::PushStyleColor(UI::Col::Separator, color * vec4(1.7f, 1.7f, 1.7f, 0.5));
    UI::PushStyleColor(UI::Col::Button, color);
    UI::PushStyleColor(UI::Col::ButtonHovered, buttonHover);
    UI::PushStyleColor(UI::Col::ButtonActive, buttonHover * vec4(1.7f, 1.7f, 1.7f, 0.7f));
    UI::PushStyleColor(UI::Col::TextSelectedBg, textSelect);
    UI::PushStyleColor(UI::Col::CheckMark, color * vec4(1.7f, 1.7f, 1.7f, 0.8f));
    UI::PushStyleColor(UI::Col::SliderGrab, color * vec4(1.7f, 1.7f, 1.7f, 0.7f));
    UI::PushStyleColor(UI::Col::SliderGrabActive, color * vec4(1.7f, 1.7f, 1.7f, 0.9f));

    UI::PushStyleColor(UI::Col::TitleBg, titleBg * vec4(.8, .8, .8, 1));
    UI::PushStyleColor(UI::Col::TitleBgActive, titleBg);
    UI::PushStyleColor(UI::Col::WindowBg, windowColor);

    UI::PushStyleVar(UI::StyleVar::GrabMinSize, 35);
    UI::PushStyleVar(UI::StyleVar::GrabRounding, 20);
    UI::PushStyleVar(UI::StyleVar::CellPadding, vec2(12, 6));
    UI::PushStyleVar(UI::StyleVar::ScrollbarSize, 13.);
    UI::PushStyleVar(UI::StyleVar::ScrollbarRounding, 10.);
    UI::PushStyleVar(UI::StyleVar::FrameRounding, 20);

    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(20, 10));
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(30, 15));
    UI::PushStyleVar(UI::StyleVar::WindowRounding, 20.0);
    UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
    UI::SetNextWindowSize(550, 738);
    UI::PushFont(Fonts::robotoRegular);
    if(UI::Begin("Macro Track Generator", windowOpen)) {
        RenderGenerateTrack();
    }
    UI::End();
    UI::PopFont();
    UI::PopStyleVar(10);
    UI::PopStyleColor(27);
}

void RenderGenerateTrack() {
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth() + 20);
    UI::BeginTabBar("gentabs");
    bool showGenerateButtons = true;
    int tabIndex = 0;
    int flags = 0;
    if(selectedTabIndex == 0) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Generation", flags)) {
        tabIndex = 0;
        UI::EndTabItem();
    }
    flags = 0;
    if(selectedTabIndex == 1) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Filter", flags)) {
        tabIndex = 1;
        UI::EndTabItem();
    }
    flags = 0;
    if(selectedTabIndex == 2) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Create parts", flags)) {
        tabIndex = 2;
        showGenerateButtons = false;
        UI::EndTabItem();
    }
    UI::EndTabBar();
    
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(5, 5));
    UI::BeginChild("tabcontent", vec2(UI::GetWindowContentRegionWidth(), UI::GetWindowSize().y - 320), true);
    if(tabIndex == 0) RenderGenerationOptions();
    if(tabIndex == 1)
        RenderFilterOptions();
    if(tabIndex == 2)
        Create::RenderInterface();
    UI::EndChild();
    UI::PopStyleVar(1);

    if(showGenerateButtons){
        UI::Separator();
        UI::NewLine();
        UI::Text("With this configuration, there are:");
        TMUI::TextDisabled(Generate::startCount + " start parts");
        TMUI::TextDisabled(Generate::partCount + " parts");
        TMUI::TextDisabled(Generate::finishCount + " finish parts");

        if(Generate::lastGenerateFailed) {
            UI::Text(Icons::ExclamationTriangle + " Track failed to generate!");
        } else {
            UI::Text("");
        }

        if(Generate::isGenerating) {
            UI::Text("Generated map duration: " + Generate::generatedMapDuration + " s");
        }

        bool canGenerate = Generate::startCount > 0 && Generate::finishCount > 0;
        if(!canGenerate)
            UI::BeginDisabled();
        if(Generate::isGenerating) {
            if(UI::IsKeyPressed(UI::Key::V)) {
                Generate::canceled = true;
            }
            if(TMUI::RedButton(GetHourGlass() + ' "V" to cancel')) {
                Generate::canceled = true;
            }
        } else {
            if(TMUI::Button(Icons::Random + " Generate"))
                startnew(Generate::GenerateTrack);
        }
        if(!canGenerate)
            UI::EndDisabled();
        UI::SameLine();
        if(TMUI::Button("Reset to default")) {
            GenOptions::ResetToDefault();
        }
    }

    UI::PopTextWrapPos();
}

void RenderGenerationOptions() {
    GenOptions::useSeed = TMUI::Checkbox("Use seed", GenOptions::useSeed);
    if(GenOptions::useSeed) {
        GenOptions::seed = UI::InputText("Seed", GenOptions::seed);
    }
    GenOptions::startHeight = UI::SliderFloat("Start height", GenOptions::startHeight, 0, 1);
    int blocksHeight = int(Math::Round(float(editor.Challenge.Size.y) * GenOptions::startHeight));
    TMUI::TextDisabled(tostring(blocksHeight) + " blocks high");
    
    GenOptions::animate = TMUI::Checkbox("Animate generation process", GenOptions::animate);
    TMUI::TextDisabled("The generation process is much slower when animating.");
    GenOptions::airMode = !TMUI::Checkbox("Add wood supports", !GenOptions::airMode);
    TMUI::TextDisabled("Track generation is more restricted with wood supports, because they can get in the way.");
    GenOptions::desiredMapLength = Math::Clamp(UI::InputInt("Map length (seconds)", GenOptions::desiredMapLength, 10), 0, 3000);

    GenOptions::forceColor = TMUI::Checkbox("Force color", GenOptions::forceColor);
    if(GenOptions::forceColor) {
        UI::SameLine();
        GenOptions::autoColoring = TMUI::Checkbox("Spread colors over length of track", GenOptions::autoColoring);
        if(!GenOptions::autoColoring) {
            UI::NewLine();
            for(uint i = 0; i < availableColors.Length; i++) {
                auto color = availableColors[i];
                if(i != 0) UI::SameLine();
                UI::PushStyleColor(UI::Col::CheckMark, vec4(1, 1, 1, 1));
                UI::PushStyleColor(UI::Col::FrameBg, colorVecs[i] * vec4(.8, .8, .8, .8));
                UI::PushStyleColor(UI::Col::FrameBgHovered, colorVecs[i] * vec4(.8, .8, .8, .8));
                UI::PushStyleColor(UI::Col::FrameBgActive, colorVecs[i] * vec4(1, 1, 1, .8));

                UI::PushStyleColor(UI::Col::Border, GenOptions::color == color ? vec4(1, 1, 1, 1) : vec4(1, 1, 1, 0.2));
                UI::PushStyleVar(UI::StyleVar::FrameBorderSize, 3);
                UI::PushStyleVar(UI::StyleVar::FrameRounding, 20);
                if(UI::Checkbox("##color" + i, GenOptions::color == color)) {
                    GenOptions::color = color;
                }
                UI::PopStyleVar(2);
                UI::PopStyleColor(5);
            }
        }
    }
}

void RenderFilterOptions() {
    // -------- Include tags ------------
    TMUI::TextDisabled("Parts must include one of the following tags (empty for all tags):");
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
        if(TMUI::Button(Icons::Times)) {
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
    TMUI::TextDisabled("Parts may not include any of the following tags:");
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
        if(TMUI::Button(Icons::Times)) {
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

    GenOptions::allowCustomItems = TMUI::Checkbox("Custom items", GenOptions::allowCustomItems);
    UI::SameLine();
    GenOptions::allowCustomBlocks = TMUI::Checkbox("Custom blocks", GenOptions::allowCustomBlocks);
    GenOptions::respawnable = TMUI::Checkbox("Parts must be respawnable", GenOptions::respawnable);
    GenOptions::considerSpeed = TMUI::Checkbox("Consider speed when connecting parts", GenOptions::considerSpeed);
    if(GenOptions::considerSpeed) {
        TMUI::TextDisabled("Maximum difference in speed between parts:");
        GenOptions::maxSpeedVariation = Math::Clamp(UI::InputInt("Max speed difference", GenOptions::maxSpeedVariation, 10), 0, 990);
    }
    GenOptions::maxSpeed = Math::Clamp(UI::InputInt("Maximum speed", GenOptions::maxSpeed, 10), GenOptions::minSpeed + 10, 1000);
    GenOptions::minSpeed = Math::Clamp(UI::InputInt("Minimum speed", GenOptions::minSpeed, 10), 0, GenOptions::maxSpeed - 10);

    GenOptions::author = UI::InputText("Author", GenOptions::author);
    TMUI::TextDisabled("Leave author empty to allow any author.");

    if(UI::BeginCombo("Allow reuse of parts?", tostring(GenOptions::reuse))) {
        for(uint i = 0; i < availableReuses.Length; i++) 
            if(UI::Selectable(tostring(availableReuses[i]), GenOptions::reuse == availableReuses[i])) 
                GenOptions::reuse = availableReuses[i];
        UI::EndCombo();
    }
    if(GenOptions::reuse == EReuse::PreferNoReuse) {
        TMUI::TextDisabled('"Prefer no reuse" reduces randomness of tracks.');
    } else { 
        UI::Text("");
    }
}

}