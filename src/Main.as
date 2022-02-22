//todo
// -------------- priority high: ----------------
// * When deleting a part either through rename or through delete button, mark it deleted for GetAllParts()
// * Finish up parts list and part edit thing

// -------------- priority low: ---------------

// * say what part is missing when track generation fails (for example: "You need a finish part for 680 speed with platform connector")
// * replace warns with warning notification
// * show user list of all macroparts -> let user disable individual parts

// * Give warning when creating that non-block mode placed items can end up intersecting 
//      so dont make large section with just ghost/free blocks or items, 
//      if you do then place some blockmode blocks in the area to stop collisions when generating track


// --------------- not possible: ------------------
// * find better way of deleting macroblock

CGameCtnEditorCommon@ editor = null;
CGameCtnApp@ app = null;

void Main() {
    Fonts::Load();
    GenOptions::Initialize();
}

void Render() {
    if(editor is null) return;
    if(!Fonts::loaded) return;
    auto driving = editor.PluginMapType.IsTesting || editor.PluginMapType.IsValidating;
    if(!driving){
        Create::RenderNativeUI();
        Generate::RenderInterface();
    }
}

void Update(float dt) {
    @app = GetApp();
    auto newEditor = cast<CGameCtnEditorCommon>(app.Editor);
    bool enteredEditor = false;
    if(editor is null && newEditor !is null) 
        enteredEditor = true;
    @editor = newEditor;
    if(enteredEditor)
        Generate::Initialize();
    if(editor is null) return;
    Create::Update();
}

bool OnKeyPress(bool down, VirtualKey key){ return Create::OnKeyPress(down, key); }
bool OnMouseButton(bool down, int button, int x, int y){ return Create::OnMouseButton(down, button, x, y); }

void RenderMenu() {
	if (UI::MenuItem("\\$0A5" + Icons::Random + "\\$z Macro Track Generator", "", Generate::windowOpen)) {
		Generate::windowOpen = !Generate::windowOpen;
	}
}