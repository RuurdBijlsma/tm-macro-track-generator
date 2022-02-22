namespace TMUI {

bool Button(const string &in label) {
    UI::PushStyleVar(UI::StyleVar::FrameRounding, 8);
    bool v = UI::Button(label);
    UI::PopStyleVar(1);
    return v;
}

bool Checkbox(const string &in label, bool value) {
    UI::PushStyleVar(UI::StyleVar::FrameRounding, 6);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(6, 6));
    bool v = UI::Checkbox(label, value);
    UI::PopStyleVar(2);
    return v;
}

void TextDisabled(const string &in text) {
    UI::PushFont(Fonts::robotoLight);
    UI::TextDisabled(text);
    UI::PopFont();
}

bool ColoredButton(const string &in text, float h, float s = 0.6f, float v = 0.6f) {
    UI::PushStyleColor(UI::Col::Button, UI::HSV(h, s, v));
    UI::PushStyleColor(UI::Col::ButtonHovered, UI::HSV(h, s + 0.1f, v + 0.1f));
    UI::PushStyleColor(UI::Col::ButtonActive, UI::HSV(h, s + 0.2f, v + 0.2f));
    bool button = TMUI::Button(text);
    UI::PopStyleColor(3);
    return button;
}

bool TransparentButton(const string &in text) {
    UI::PushStyleColor(UI::Col::Button, vec4(1, 1, 1, 0));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(1, 1, 1, 0.05));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(1, 1, 1, 0.2));
    bool button = UI::Button(text);
    UI::PopStyleColor(3);
    return button;
}

bool RedButton(const string &in text) { return ColoredButton(text, 0.0f); }
bool GreenButton(const string &in text) { return ColoredButton(text, 0.33f); }
bool OrangeButton(const string &in text) { return ColoredButton(text, 0.1f); }
bool CyanButton(const string &in text) { return ColoredButton(text, 0.5f); }
bool PurpleButton(const string &in text) { return ColoredButton(text, 0.8f); }
bool RoseButton(const string &in text) { return ColoredButton(text, 0.9f); }

}