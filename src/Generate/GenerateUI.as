namespace Generate {
// bool windowOpen = IsDevMode();
bool windowOpen = false;
int selectedTabIndex = 0;

void RenderInterface() {
    if(!windowOpen) return;
    TMUI::PushWindowStyle();
    UI::SetNextWindowSize(480, 738);
    if(UI::Begin("Macro Track Generator", windowOpen)) {
        RenderGenerateTrack();
    }
    UI::End();
    TMUI::PopWindowStyle();
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
    if(UI::BeginTabItem("Parts", flags)) {
        tabIndex = 2;
        showGenerateButtons = false;
        UI::EndTabItem();
    }
    flags = 0;
    if(selectedTabIndex == 3) {
        flags |= UI::TabItemFlags::SetSelected;
        selectedTabIndex = -1;
    }
    if(UI::BeginTabItem("Create parts", flags)) {
        tabIndex = 3;
        showGenerateButtons = false;
        UI::EndTabItem();
    }
    UI::EndTabBar();
    
    UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(5, 5));
    UI::BeginChild("tabcontent", vec2(UI::GetWindowContentRegionWidth(), UI::GetWindowSize().y - (showGenerateButtons ? 320 : 110)), true);
    if(tabIndex == 0) RenderGenerationOptions();
    if(tabIndex == 1) RenderFilterOptions();
    if(tabIndex == 2) Parts::RenderInterface();
    if(tabIndex == 3) Create::RenderInterface();
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

        // if(Generate::isGenerating) {
            UI::Text("Tried " + Generate::triedParts + " parts, generated map duration: " + Generate::generatedMapDuration + " s");
        // }

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
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    UI::PushTextWrapPos(UI::GetWindowContentRegionWidth() + 20);

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
    GenOptions::desiredMapLength = UI::SliderInt("Map length (seconds)", GenOptions::desiredMapLength, 10, 3000);
    // GenOptions::desiredMapLength = Math::Clamp(UI::InputInt("Map length (seconds)", GenOptions::desiredMapLength, 10), 0, 3000);

    GenOptions::clearMap = TMUI::Checkbox("Clear map before generating", GenOptions::clearMap);
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
    UI::PopTextWrapPos();
}

void RenderFilterOptions() {
    // -------- Include tags ------------
    TMUI::TextDisabled("Parts must include one of the following tags (empty for all tags):");
    string iTagsString = "";
    UI::PushID("includeTags");
    if(TagSelector(GenOptions::includeTags)) {
        GenOptions::OnChange();
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
    UI::PushID("excludeTags");
    if(TagSelector(GenOptions::excludeTags)) {
        GenOptions::OnChange();
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
    GenOptions::noRepeats = TMUI::Checkbox("Prevent parts being connecting to themselves", GenOptions::noRepeats);
    GenOptions::considerSpeed = TMUI::Checkbox("Consider speed when connecting parts", GenOptions::considerSpeed);
    if(GenOptions::considerSpeed) {
        TMUI::TextDisabled("Maximum difference in speed between parts:");
        GenOptions::maxSpeedVariation = Math::Clamp(UI::InputInt("Max speed diff", GenOptions::maxSpeedVariation, 10), 0, 990);
    }
    GenOptions::maxSpeed = Math::Clamp(UI::InputInt("Maximum speed", GenOptions::maxSpeed, 10), GenOptions::minSpeed + 10, 1000);
    GenOptions::minSpeed = Math::Clamp(UI::InputInt("Minimum speed", GenOptions::minSpeed, 10), 0, GenOptions::maxSpeed - 10);

    GenOptions::author = UI::InputText("Author", GenOptions::author);
    TMUI::TextDisabled("Leave author empty to allow any author.");

    if(UI::BeginCombo("Allow part reuse?", tostring(GenOptions::reuse))) {
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