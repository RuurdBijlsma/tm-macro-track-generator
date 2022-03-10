//todo
// -------------- priority high: ----------------
// * filter out parts that wont be able to connect to any other part (ex. filter: must include dirt, start is pick that has dirt and connects to IceRoad, but there are not parts with iceroad entrance connector. It then takes a very long time to figure out)
//      - can be done in global filter?
//      - but def also in local filter
// * rotate through start blocks before trying other positions for start block
// * add option, dont allow part to connect to itsself


// -------------- priority low: ---------------
// * browse/download part sets from IX
// * have sets/folders for parts for categorising
// * auto import items/download blocks from macroparts

// * Give warning when creating that non-block mode placed items can end up intersecting 
//      so dont make large section with just ghost blocks or items, 
//      if you do then place some blockmode blocks in the area to stop collisions when generating track

// * disallow bobsleigh -> other types connections
// * cancelling generate pukes out bunch of start parts
// * in part view ui add button to change entrance/exit only
// * Scenery generator? 
// * improve performance
//      - Use connection type for connection check instead of can place
//      - profile whats taking longest
//      - dont shuffle every backtrack

// --------------- not possible?: ------------------
// * say what part is missing when track generation fails (for example: "You need a finish part for 680 speed with platform connector")
// * get icon of macroblock
// * find better way of deleting macroblock
bool isInEditor = false;

void Main() {
    Fonts::Load();
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    GenOptions::Initialize();
}

void Render() {
    if(!Fonts::loaded) return;
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    auto driving = editor.PluginMapType.IsTesting || editor.PluginMapType.IsValidating;
    if(!driving){
        Create::RenderNativeUI();
        Generate::RenderInterface();
    }
}

void Update(float dt) {
    auto editor = Editor();
    if(!isInEditor && editor !is null) {
        print("Entered editor, initializing generate");
        Generate::Initialize();
        print("Entered editor, initialized generate");
    }
    if(isInEditor && editor is null) {
        print("Left editor, resetting states");
        Create::ResetState();
    }
    isInEditor = editor !is null;
    if(editor !is null)
        Create::Update();
}

bool OnKeyPress(bool down, VirtualKey key){ return Create::OnKeyPress(down, key); }
bool OnMouseButton(bool down, int button, int x, int y){ return Create::OnMouseButton(down, button, x, y); }

void RenderMenu() {
	if (UI::MenuItem("\\$0A5" + Icons::Random + "\\$z Macro Track Generator", "", Generate::windowOpen)) {
		Generate::windowOpen = !Generate::windowOpen;
	}
}

CGameCtnEditorCommon@ Editor() {
    auto app = GetApp();
    return cast<CGameCtnEditorCommon@>(app.Editor);
}