//todo
// -------------- first: ----------------
// * big ol refactor with safety checks and dont load editor everywhere
// -------------- after: ---------------
// * track generation
// * Nicer UI for creating macropart (integrated in real editor UI)
// * UI for creating tracks

void Main() {
    auto gen = Generate();
    gen.GenerateTrack();
}

bool OnKeyPress(bool down, VirtualKey key){return Create::OnKeyPress(down, key);}
bool OnMouseButton(bool down, int button, int x, int y){return Create::OnMouseButton(down, button, x, y);}

void RenderInterface() {
    Create::RenderInterface();
}