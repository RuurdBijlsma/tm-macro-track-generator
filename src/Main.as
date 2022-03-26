//todo
// -------------- priority high: ----------------
// * crash when leaving editor?
// * crash after generating (and fixing magnet maybe? maybe only on void map?)?
// * media tracker resets state
// * explain how to make parts

// -------------- priority low: ---------------

// * refresh not called after reset to default filters?
// * in create process, button to go back to select entrance?

// * Scenery generator? 

// * soms gaat ie stuk op saving macroblock, dan moet je temp_mtg verwijderen

// * improve performance
//      - profile whats taking longest
//      - improve shuffle algorithm?
//      - optmize backtracking with heuristis?
// * option to optimize backtracking
//      - remove randomness but use fancy algorithms

// --------------- not possible?: ------------------
// * say what part is missing when track generation fails (for example: "You need a finish part for 680 speed with platform connector")
// * get icon of macroblock
// * find better way of deleting macroblock
bool isInEditor = false;

void Main() {
    Fonts::Load();
    MTG::CheckMacroParts();
    auto editor = Editor();
    if(editor is null || editor.PluginMapType is null) return;
    GenOptions::Initialize();
}

void Render() {
    if(!Fonts::loaded) return;
    TMDialog::Render();
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