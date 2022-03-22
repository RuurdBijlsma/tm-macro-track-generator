[Setting name="MacroPart folder" category="General"]
string macroPartFolder = "zzz_MacroTrackGenerator"; //zzz_MacroTrackGenerator

[Setting name="Add in-editor buttons" category="General"]
bool nativeButtons = true;

enum PartsListInfo {
    UsedCount,
    Connectivity
};

[Setting name="Info shown in parts list" category="General"]
PartsListInfo partsListInfo = PartsListInfo::Connectivity;

[Setting name="Maximum track length" category="General"]
int maxTrackLength = 1000;