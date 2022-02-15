namespace Create{

string GetTrackmaniaFolder() {
    auto documents = IO::FromDataFolder("").Split('/Openplanet')[0] + "\\Documents";
    string itemsFolder;
    if(IO::FolderExists(documents + "\\Trackmania2020")) {
        itemsFolder = documents + "\\Trackmania2020\\";
    } else {
        itemsFolder = documents + "\\Trackmania\\";
    }
    return itemsFolder.Replace("\\", "/");
}

string GetItemsFolder() {return GetTrackmaniaFolder() + "Items/";}

string GetBlocksFolder() {return GetTrackmaniaFolder() + "Blocks/";}

void SaveMacroPart(CGameCtnMacroBlockInfo@ macroblock, MacroPart@ partDetails) {
    string base64Items = "";
    for(uint i = 0; i < partDetails.embeddedItems.Length; i++) {
        auto relItemPath = partDetails.embeddedItems[i];
        auto itemPath = GetItemsFolder() + relItemPath;
        print("itemPath: " + itemPath);
        IO::File file(itemPath);
        file.Open(IO::FileMode::Read);
        auto buffer = file.Read(file.Size());
        file.Close();
        // base64 does not use |, so use it as separator again
        if(i != 0) base64Items += MacroPart::DetailSeparator;
        base64Items += buffer.ReadToBase64(buffer.GetSize());
    }
    macroblock.Description = partDetails.ToString() + MacroPart::BaseSeparator + base64Items;
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    editor.PluginMapType.SaveMacroblock(macroblock);
}

}
