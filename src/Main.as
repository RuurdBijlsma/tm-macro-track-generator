//todo
// -------------- priority high: ----------------
// * plugin sometimes crashes game when leaving editor without any error or logs
// * Finish up parts list and part edit thing
// * in part details page -> 2 buttons -> save changes & edit blocks which puts the macroblock on the cursor to be placed in airmode so the user can:
//      place it -> change it -> user select it -> choose entrance / exit -> save changes to file and go back to part details page
// clicking air macroblock button places macroblock

// -------------- priority low: ---------------

// * have sets/folders for parts for categorising
// * say what part is missing when track generation fails (for example: "You need a finish part for 680 speed with platform connector")

// * Give warning when creating that non-block mode placed items can end up intersecting 
//      so dont make large section with just ghost/free blocks or items, 
//      if you do then place some blockmode blocks in the area to stop collisions when generating track

// * auto check if macroblock is connected to ground after selecting
// * Scenery generator? 

// --------------- not possible: ------------------
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
    if(!isInEditor && editor !is null) 
        Generate::Initialize();
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