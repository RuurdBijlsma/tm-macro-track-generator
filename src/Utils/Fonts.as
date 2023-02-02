namespace Fonts {
    UI::Font@ robotoRegular;
    UI::Font@ robotoBig;
    UI::Font@ robotoLightItalic;

    nvg::Font montserratRegular;
    nvg::Font droidSansBold;
    nvg::Font droidSansRegular;
    bool loaded = false;

    void Load() {
        int fontSize = 16;

        @robotoLightItalic = UI::LoadFont("fonts/Roboto-LightItalic.ttf", fontSize);
        yield();
        @robotoRegular = UI::LoadFont("fonts/Roboto-Regular.ttf", fontSize);
        yield();
        @robotoBig = UI::LoadFont("fonts/Roboto-Regular.ttf", 48);


        // nvg fonts
        yield();
        montserratRegular = nvg::LoadFont("fonts/Montserrat-Regular.ttf", true, true);
        yield();
        droidSansBold = nvg::LoadFont("DroidSans-Bold.ttf", true, true);
        yield();
        droidSansRegular = nvg::LoadFont("DroidSans.ttf", true, true);

        loaded = true;
    }
}