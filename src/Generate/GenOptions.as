enum EReuse {
    Reuse,
    PreferNoReuse,
    NoReuse
};
EReuse[] availableReuses = {EReuse::Reuse, EReuse::PreferNoReuse, EReuse::NoReuse};
CGameEditorPluginMap::EMapElemColor[] availableColors = {
    CGameEditorPluginMap::EMapElemColor::Default, 
    CGameEditorPluginMap::EMapElemColor::White,
    CGameEditorPluginMap::EMapElemColor::Green,
    CGameEditorPluginMap::EMapElemColor::Blue,
    CGameEditorPluginMap::EMapElemColor::Red,
    CGameEditorPluginMap::EMapElemColor::Black
};
vec4[]@ colorVecs = {
    vec4(.5, .5, .5, 1),
    vec4(1, 1, 1, 1),
    vec4(0, 1, 0, 1),
    vec4(0, 0, 1, 1),
    vec4(1, 0, 0, 1),
    vec4(0, 0, 0, 1)
};


namespace GenOptions {

// - tag
string[]@ includeTags = {};
string[]@ excludeTags = {};
// - difficulty range
EDifficulty[]@ difficulties = {EDifficulty::Beginner, EDifficulty::Intermediate, EDifficulty::Advanced, EDifficulty::Expert};

float _startHeight = 0.5;
float get_startHeight(){return _startHeight;}
void set_startHeight(float v) {
    if(_startHeight != v) {
        OnChange();
        _startHeight = v;
    }
}
bool _autoColoring = false;
bool get_autoColoring(){return _autoColoring;}
void set_autoColoring(bool v) {
    if(_autoColoring != v) {
        OnChange();
        _autoColoring = v;
    }
}
bool _forceColor = false;
bool get_forceColor(){return _forceColor;}
void set_forceColor(bool v) {
    if(_forceColor != v) {
        OnChange();
        _forceColor = v;
    }
}
CGameEditorPluginMap::EMapElemColor _color = CGameEditorPluginMap::EMapElemColor::Black;
CGameEditorPluginMap::EMapElemColor get_color(){return _color;}
void set_color(CGameEditorPluginMap::EMapElemColor v) {
    if(_color != v) {
        OnChange();
        _color = v;
    }
}
bool _useSeed = false;
bool get_useSeed(){return _useSeed;}
void set_useSeed(bool v) {
    if(_useSeed != v) {
        OnChange();
        _useSeed = v;
    }
}
string _seed = "Hello World";
string get_seed(){return _seed;}
void set_seed(string v) {
    if(_seed != v) {
        OnChange();
        _seed = v;
    }
}
bool _animate = false;
bool get_animate(){return _animate;}
void set_animate(bool v) {
    if(_animate != v) {
        OnChange();
        _animate = v;
    }
}
bool _airMode = true;
bool get_airMode(){return _airMode;}
void set_airMode(bool v) {
    if(_airMode != v) {
        OnChange();
        _airMode = v;
    }
}
bool _allowCustomItems = true;
bool get_allowCustomItems(){return _allowCustomItems;}
void set_allowCustomItems(bool v) {
    if(_allowCustomItems != v) {
        OnChange();
        _allowCustomItems = v;
    }
}
bool _allowCustomBlocks = true;
bool get_allowCustomBlocks(){return _allowCustomBlocks;}
void set_allowCustomBlocks(bool v) {
    if(_allowCustomBlocks != v) {
        OnChange();
        _allowCustomBlocks = v;
    }
}
bool _considerSpeed = true;
bool get_considerSpeed(){return _considerSpeed;}
void set_considerSpeed(bool v) {
    if(_considerSpeed != v) {
        OnChange();
        _considerSpeed = v;
    }
}
int _maxSpeedVariation = 100;
int get_maxSpeedVariation(){return _maxSpeedVariation;}
void set_maxSpeedVariation(int v) {
    if(_maxSpeedVariation != v) {
        OnChange();
        _maxSpeedVariation = v;
    }
}
int _minSpeed = 0;
int get_minSpeed(){return _minSpeed;}
void set_minSpeed(int v) {
    if(_minSpeed != v) {
        OnChange();
        _minSpeed = v;
    }
}
int _maxSpeed = 1000;
int get_maxSpeed(){return _maxSpeed;}
void set_maxSpeed(int v) {
    if(_maxSpeed != v) {
        OnChange();
        _maxSpeed = v;
    }
}
int _desiredMapLength = 60;
int get_desiredMapLength(){return _desiredMapLength;}
void set_desiredMapLength(int v) {
    if(_desiredMapLength != v) {
        OnChange();
        _desiredMapLength = v;
    }
}
string _author = "";
string get_author(){return _author;}
void set_author(string v) {
    if(_author != v) {
        OnChange();
        _author = v;
    }
}
bool _respawnable = false;
bool get_respawnable(){return _respawnable;}
void set_respawnable(bool v) {
    if(_respawnable != v) {
        OnChange();
        _respawnable = v;
    }
}
EReuse _reuse = EReuse::PreferNoReuse;
EReuse get_reuse(){return _reuse;}
void set_reuse(EReuse v) {
    if(_reuse != v) {
        OnChange();
        _reuse = v;
    }
}

string optionsFile = IO::FromDataFolder("mtg-options.json");

void Initialize() {
    if(IO::FileExists(optionsFile)) {
        FromFile();
    } else {
        ResetToDefault();
    }
    startnew(Update);
}

void ClearIncludeTags() {
    includeTags.RemoveRange(0, includeTags.Length);
}

void ClearExcludeTags() {
    excludeTags.RemoveRange(0, excludeTags.Length);
}

void ResetIncludeTags() {
    for(uint i = 0; i < availableTags.Length; i++) {
        includeTags.InsertLast(availableTags[i]);
    }
}

Json::Value ToJson() {
    auto obj = Json::Object();

    obj["includeTags"] = Json::Array();
    for(uint i = 0; i < includeTags.Length; i++)
        obj["includeTags"].Add(includeTags[i]);
    obj["excludeTags"] = Json::Array();
    for(uint i = 0; i < excludeTags.Length; i++)
        obj["excludeTags"].Add(excludeTags[i]);
    obj["difficulties"] = Json::Array();
    for(uint i = 0; i < difficulties.Length; i++)
        obj["difficulties"].Add(difficulties[i]);
    obj["startHeight"] = startHeight;
    obj["forceColor"] = forceColor;
    obj["autoColoring"] = autoColoring;
    obj["color"] = color;
    obj["useSeed"] = useSeed;
    obj["seed"] = seed;
    obj["animate"] = animate;
    obj["airMode"] = airMode;
    obj["allowCustomItems"] = allowCustomItems;
    obj["allowCustomBlocks"] = allowCustomBlocks;
    obj["considerSpeed"] = considerSpeed;
    obj["maxSpeedVariation"] = maxSpeedVariation;
    obj["minSpeed"] = minSpeed;
    obj["maxSpeed"] = maxSpeed;
    obj["desiredMapLength"] = desiredMapLength;
    obj["author"] = author;
    obj["reuse"] = reuse;

    return obj;
}

void FromJson(Json::Value obj) {
    if(obj.GetType() != Json::Type::Object) {
        warn("Can't parse gen options from json");
        return;
    }
    includeTags = {};
    for(uint i = 0; i < obj["includeTags"].Length; i++) 
        includeTags.InsertLast(obj["includeTags"][i]);
    excludeTags = {};
    for(uint i = 0; i < obj["excludeTags"].Length; i++) 
        excludeTags.InsertLast(obj["excludeTags"][i]);
    difficulties = {};
    for(uint i = 0; i < obj["difficulties"].Length; i++) {
        int intDiff = obj["difficulties"][i];
        difficulties.InsertLast(EDifficulty(intDiff));
    }

    startHeight = obj["startHeight"];
    autoColoring = obj["autoColoring"];
    forceColor = obj["forceColor"];
    int intColor = obj["color"];
    color = CGameEditorPluginMap::EMapElemColor(intColor);
    useSeed = obj["useSeed"];
    seed = obj["seed"];
    animate = obj["animate"];
    airMode = obj["airMode"];
    allowCustomItems = obj["allowCustomItems"];
    allowCustomBlocks = obj["allowCustomBlocks"];
    considerSpeed = obj["considerSpeed"];
    maxSpeedVariation = obj["maxSpeedVariation"];
    minSpeed = obj["minSpeed"];
    maxSpeed = obj["maxSpeed"];
    desiredMapLength = obj["desiredMapLength"];
    author = obj["author"];
    int intReuse = obj["reuse"];
    reuse = EReuse(intReuse);
}

void ResetToDefault() {
    auto json = Json::FromFile("default-generation-options.json");
    FromJson(json);
}

void FromFile() {
    print("Importing gen options from file");
    auto json = Json::FromFile(optionsFile);
    FromJson(json);
}

void ToFile() {
    print("Exporting gen options to file");
    Json::ToFile(optionsFile, ToJson());
}

void OnChange() {
    onChangeTimeout = 30;
}

int onChangeTimeout = -1;
void Update() {
    while(true) {
        yield();
        if(onChangeTimeout == 0) {
            ToFile();
            Generate::UpdateFilteredParts();
        }
        if(onChangeTimeout >= 0)
            onChangeTimeout--;
    }
}

};