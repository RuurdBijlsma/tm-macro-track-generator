namespace Fonts {
    Resources::Font@ oswaldRegular = null;
    Resources::Font@ droidSansBold = null;
    Resources::Font@ droidSansRegular = null;
    bool loaded = false;

    void Load() {
        @droidSansRegular = Resources::GetFont("DroidSans.ttf");
        @droidSansBold = Resources::GetFont("DroidSans-Bold.ttf");
        @oswaldRegular = Resources::GetFont("Oswald-Regular.ttf");
        loaded = true;
    }
}