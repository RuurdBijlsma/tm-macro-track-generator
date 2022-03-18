namespace TMUI {

vec4 baseWindowColor = vec4(6. / 255, 131. / 255, 84. / 255, .97);
vec4 windowColor = baseWindowColor;

void PushWindowStyle() {
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
    UI::PushFont(Fonts::robotoRegular);
}

void PopWindowStyle() {
    UI::PopFont();
    UI::PopStyleVar(10);
    UI::PopStyleColor(27);
}

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
    UI::PushFont(Fonts::robotoLightItalic);
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