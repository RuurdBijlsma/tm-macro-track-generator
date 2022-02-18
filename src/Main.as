//todo
// -------------- priority high: ----------------
// * Filters
//      - connector speed
//      - checkbox for whether to check for connector speed
//      - max variation of connector speed
//      - custom items allowed
//      - custom blocks allowed
//      - tag
//      - min-max speed
//      - difficulty range
//      - desired map length
//      - author
//      - respawnable
//      - allow same macropart being used twice checkbox
// -------------- priority low: ---------------
// * stop yields in generate track om de timeout te omzeilen
// * random macroblock kleuren
// * Nicer UI for creating macropart (integrated in real editor UI)
// * UI for creating tracks
// * safety checks for editor is null
// * Give warning when creating that non-block mode placed items can end up intersecting 
//      so dont make large section with just ghost/free blocks or items, 
//      if you do then place some blockmode blocks in the area to stop collisions when generating track
// * rename mb files after filling in details (rename to MTG-RuteNL-{name}.Macroblock.Gbx)
// * When you cancel creating a macropart, delete the macroblock
// * make function to delete macroblock properly (try with SelectArticle(article@ nodearticle)) -> then delete
// * say what part is missing when track generation fails (for example: "You need a finish part for 680 speed with platform connector")

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