//todo
// -------------- priority high: ----------------
// * auto import items/download blocks from macroparts
// * On startup:
//      - Check if detault macroparts are there, if not put macroparts into blocks folder, and put embedded items in items folder
//      - Check for every macropart in blocks folder if the embedded items exist in the items folder

// -------------- priority low: ---------------
// * Give warning when creating that non-block mode placed items can end up intersecting 
//      so dont make large section with just ghost blocks or items, 
//      if you do then place some blockmode blocks in the area to stop collisions when generating track

// * when generation is done, save all parts + directed positions used in map, remove every placed part, then replace every part to fix the removed blocks bug

// * Scenery generator? 

// * option to optimize backtracking
//      - remove randomness but use fancy algorithms

// * in create process, button to go back to select entrance?

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
        Generate::Initialize();
    }
    if(isInEditor && editor is null) {
        @Parts::selectedPart = null;
        Generate::ResetState();
        Create::ResetState();
    }
    isInEditor = editor !is null;
    if(editor !is null) {
        Create::Update();
    }
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