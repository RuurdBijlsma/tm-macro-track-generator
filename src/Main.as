void Main() {
    auto gen = Generate();
    gen.GenerateTrack();
}

bool OnKeyPress(bool down, VirtualKey key){return Create::OnKeyPress(down, key);}
bool OnMouseButton(bool down, int button, int x, int y){return Create::OnMouseButton(down, button, x, y);}

void RenderInterface() {
    Create::RenderInterface();
}