bool CopyFile(const string &in fromFile, const string &in toFile, bool overwrite = true){
    if(!IO::FileExists(fromFile)){
        warn("fromFile does not exist");
        return false;
    }
    if(!overwrite && IO::FileExists(toFile)){
        warn("toFile already exists, and overwrite is set to false!");
        return false;
    }
    IO::File fromItem(fromFile);
    fromItem.Open(IO::FileMode::Read);
    auto buffer = fromItem.Read(fromItem.Size());
    fromItem.Close();

    IO::File toItem(toFile);
    toItem.Open(IO::FileMode::Write);
    toItem.Write(buffer);
    toItem.Close();
    return true;
}

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

const string macroblockFolder = "zzz_MacroTrackGenerator"; //zzz_MacroTrackGenerator

CGameCtnMacroBlockInfo@ SaveMacroPart(CGameCtnMacroBlockInfo@ macroblock, MacroPartDetails@ partDetails) {
    auto saveFolder = "Stadium/" + macroblockFolder + "/";
    string blocksFolder = GetBlocksFolder();
    if(!IO::FolderExists(blocksFolder + saveFolder))
        IO::CreateFolder(blocksFolder + saveFolder);
    string filename = partDetails.author + "_" + partDetails.name + "_" + tostring(partDetails.type);

    string relativeSaveLocation = saveFolder + filename + ".Macroblock.Gbx";
    int i = 0;
    while(IO::FileExists(blocksFolder + relativeSaveLocation)) {
        relativeSaveLocation = saveFolder + filename + '(' + tostring(++i) + ')' + ".Macroblock.Gbx";
    }

    return SaveMacroPartToLocation(macroblock, partDetails, relativeSaveLocation);
}

CGameCtnMacroBlockInfo@ SaveMacroPartToLocation(CGameCtnMacroBlockInfo@ macroblock, MacroPartDetails@ partDetails, const string &in relativeSaveLocation) {
    string oldDescription = macroblock.Description;
    string base64Items = "";
    for(uint i = 0; i < partDetails.embeddedItems.Length; i++) {
        auto relItemPath = partDetails.embeddedItems[i];
        auto itemPath = GetItemsFolder() + relItemPath;
        IO::File file(itemPath);
        file.Open(IO::FileMode::Read);
        auto buffer = file.Read(file.Size());
        file.Close();
        // base64 does not use |, so use it as separator again
        if(i != 0) base64Items += "|";
        base64Items += buffer.ReadToBase64(buffer.GetSize());
    }
    macroblock.Description = partDetails.ToString() + "|||||" + base64Items;
    auto app = GetApp();
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    editor.PluginMapType.SaveMacroblock(macroblock);

    string saveLocation = GetBlocksFolder() + relativeSaveLocation;
    print("Saving new macropart to: " + saveLocation);
    CopyFile(GetBlocksFolder() + macroblock.IdName, saveLocation);
    macroblock.Description = oldDescription;
    editor.PluginMapType.SaveMacroblock(macroblock);
    print("Loading from relative location: " + relativeSaveLocation);
    auto new = editor.PluginMapType.GetMacroblockModelFromFilePath(relativeSaveLocation.Replace('/', '\\'));
    print("New is null? " + (new is null));
    return new;
}