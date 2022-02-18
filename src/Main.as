//todo
// -------------- priority high: ----------------
// * UI for generating tracks
// -------------- priority low: ---------------
// * stop yields in generate track om de timeout te omzeilen
// * random macroblock kleuren
// * Nicer UI for creating macropart (integrated in real editor UI)
// * safety checks for editor is null
// * Give warning when creating that non-block mode placed items can end up intersecting 
//      so dont make large section with just ghost/free blocks or items, 
//      if you do then place some blockmode blocks in the area to stop collisions when generating track
// * say what part is missing when track generation fails (for example: "You need a finish part for 680 speed with platform connector")
// * use dictionary for macroblock count used in map and sort by that when doing EReuse::PreferNoReuse
// --------------- not possible: ------------------
// * find better way of deleting macroblock

CGameCtnEditorCommon@ editor = null;
CGameCtnApp@ app = null;

void Main() {
    @app = GetApp();
    @editor = cast<CGameCtnEditorCommon>(app.Editor);
    Generate::Initialize();
    Generate::GenerateTrack();
}

void Update(float dt) {
    @app = GetApp();
    @editor = cast<CGameCtnEditorCommon>(app.Editor);
}

bool OnKeyPress(bool down, VirtualKey key){ return Create::OnKeyPress(down, key); }
bool OnMouseButton(bool down, int button, int x, int y){ return Create::OnMouseButton(down, button, x, y); }

void RenderInterface() {
    if(editor !is null)
        Create::RenderInterface();
}