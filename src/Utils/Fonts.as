namespace Fonts {
    Resources::Font@ robotoItalic = null;
    Resources::Font@ robotoRegular = null;
    Resources::Font@ robotoLight = null;

    Resources::Font@ montserratLight = null;
    Resources::Font@ montserratRegular = null;

    Resources::Font@ droidSansBold = null;
    Resources::Font@ droidSansRegular = null;
    Resources::Font@ droidSansRegularBigger = null;
    bool loaded = false;

    void Load() {
        int fontSize = 16;

        @droidSansRegular = Resources::GetFont("DroidSans.ttf", fontSize);
        @droidSansBold = Resources::GetFont("DroidSans-Bold.ttf", fontSize);

        @robotoItalic = Resources::GetFont("fonts/Roboto-Italic.ttf", fontSize);
        @robotoRegular = Resources::GetFont("fonts/Roboto-Regular.ttf", fontSize);
        @robotoLight = Resources::GetFont("fonts/Roboto-Light.ttf", fontSize);

        @montserratLight = Resources::GetFont("fonts/Montserrat-Light.ttf", fontSize);
        @montserratRegular = Resources::GetFont("fonts/Montserrat-Regular.ttf", fontSize);

        loaded = true;
    }
}