enum EReuse {
    Reuse,
    PreferNoReuse,
    NoReuse
};
EReuse[] availableReuses = {EReuse::Reuse, EReuse::PreferNoReuse, EReuse::NoReuse};

namespace GenOptions {

[setting category="Filter"]
bool useSeed = false;
[setting category="Filter"]
string seed = "Hello World";
[setting category="Filter"]
bool animate = false;
[setting category="Filter"]
bool airMode = true;

// - custom items allowed
bool allowCustomItems = true;
// - custom blocks allowed
bool allowCustomBlocks = true;
// - tag
string[]@ includeTags = {};
string[]@ excludeTags = {};
// - checkbox for whether to check for connector speed
bool considerSpeed = true;
// - max variation of connector speed
int maxSpeedVariation = 100;
// - min-max speed
int minSpeed = 0;
int maxSpeed = 999;
// - difficulty range
EDifficulty[]@ difficulties = {EDifficulty::Beginner, EDifficulty::Intermediate, EDifficulty::Advanced, EDifficulty::Expert};
// - desired map length (seconds)
int desiredMapLength = 60;
// - author (empty for all authors)
string author = "";
// - respawnable
bool respawnable = false;
// - allow same macropart being used twice checkbox
EReuse reuse = EReuse::PreferNoReuse;

void Initialize() {
    ResetIncludeTags();
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

};