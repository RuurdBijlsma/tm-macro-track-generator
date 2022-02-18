class PartFilter {
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
    bool allowPartReuse = true;

    PartFilter() {
        ResetIncludeTags();
    }

    void ClearIncludeTags() {
        this.includeTags.RemoveRange(0, this.includeTags.Length);
    }

    void ClearExcludeTags() {
        this.excludeTags.RemoveRange(0, this.excludeTags.Length);
    }

    void ResetIncludeTags() {
        for(uint i = 0; i < availableTags.Length; i++) {
            this.includeTags.InsertLast(availableTags[i]);
        }
    }
};