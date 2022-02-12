namespace Generate {

// Get MacroParts from macro folder
MacroPart@[] GetMacroParts() {
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    auto pluginMapType = editor.PluginMapType;
    auto inventory = pluginMapType.Inventory;
    auto rootNodes = inventory.RootNodes;
    MacroPart@[] macroParts = {};
    for(uint i = 0; i < rootNodes.Length; i++) {
        auto node = cast<CGameCtnArticleNodeDirectory>(rootNodes[i]);
        if(node is null) continue;
        for(uint j = 0; j < node.ChildNodes.Length; j++) {
            if(node.ChildNodes[j].Name == macroblockFolder){
                auto mbFolder = cast<CGameCtnArticleNodeDirectory@>(node.ChildNodes[j]);
                for(uint k = 0; k < mbFolder.ChildNodes.Length; k++) {
                    auto articleNode = cast<CGameCtnArticleNodeArticle@>(mbFolder.ChildNodes[k]);
                    if(articleNode is null) continue;
                    auto macroblock = cast<CGameCtnMacroBlockInfo@>(articleNode.Article.LoadedNod);
                    if(macroblock is null) continue;
                    auto macroPart = MacroPart::FromMacroblock(macroblock)
                    if(macroPart is null) continue;
                    macroParts.InsertLast(macroPart);
                }
            }
        }
    }

    return macroParts;
}

void GenerateTrack() {
    auto macroParts = GetMacroParts();
    if(macroParts.Length == 0) {
        warn("No MacroParts found to generate a track with!");
        return;
    }
    
    for(uint i = 0; i < macroParts.Length; i++) {
        print(macroParts[i].ToString());
    }
}

void RenderInterface() {
    
}

}