namespace Fonts {
    Resources::Font@ robotoRegular = null;
    Resources::Font@ robotoBig = null;
    Resources::Font@ robotoLightItalic = null;

    Resources::Font@ montserratRegular = null;

    Resources::Font@ droidSansBold = null;
    Resources::Font@ droidSansRegular = null;
    bool loaded = false;

    void Load() {
        int fontSize = 16;

        @droidSansRegular = Resources::GetFont("DroidSans.ttf", fontSize);
        yield();
        @droidSansBold = Resources::GetFont("DroidSans-Bold.ttf", fontSize);
        yield();
        
        @robotoLightItalic = Resources::GetFont("fonts/Roboto-LightItalic.ttf", fontSize);
        yield();
        @robotoRegular = Resources::GetFont("fonts/Roboto-Regular.ttf", fontSize);
        yield();
        @robotoBig = Resources::GetFont("fonts/Roboto-Regular.ttf", 48);
        yield();
        @montserratRegular = Resources::GetFont("fonts/Montserrat-Regular.ttf", fontSize);

        loaded = true;
    }
}