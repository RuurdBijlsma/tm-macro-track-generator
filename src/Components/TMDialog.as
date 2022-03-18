namespace TMDialog {
    bool promptOpen = false;
    bool promptResult = false;

    string promptLabel = "";
    string promptSubLabel = "";
    string promptOkText = "";
    string promptCancelText = "";

    void Confirm(const string &in label, const string &in subLabel = "", const string &in okText = "Ok", const string &in cancelText = "Cancel") {
        promptLabel = label;
        promptSubLabel = subLabel;
        promptOkText = okText;
        promptCancelText = cancelText;
        promptOpen = true;
    }

    void Alert(const string &in label, const string &in subLabel = "", const string &in okText = "Ok") {
        promptLabel = label;
        promptSubLabel = subLabel;
        promptOkText = okText;
        promptCancelText = "";
        promptOpen = true;
    }

    void RenderPrompt() {
        if(!promptOpen) return;
        TMUI::PushWindowStyle();
        int flags = UI::WindowFlags::NoResize 
            | UI::WindowFlags::NoScrollbar 
            | UI::WindowFlags::NoCollapse 
            | UI::WindowFlags::AlwaysAutoResize;
        if(UI::Begin("MTG - Prompt", flags)) {
            UI::Text(promptLabel);
            if(promptSubLabel != "") {
                TMUI::TextDisabled(promptSubLabel);
            }
            if(TMUI::Button(promptOkText)) {
                promptResult = true;
                promptOpen = false;
            }
            if(promptCancelText != "") {
                UI::SameLine();
                if(TMUI::Button(promptCancelText)) {
                    promptResult = false;
                    promptOpen = false;
                }
            }
        }
        UI::End();
        TMUI::PopWindowStyle();
    }

    void Render() {
        RenderPrompt();
    }
}