bool TagSelector(string[]@ selectedTags) {
    bool changed = false;
    string tagsString = "";
    if(selectedTags.Length == 0) {
        tagsString = "No tags selected";
    }
    for(uint i = 0; i < selectedTags.Length; i++) {
        if(i != 0) tagsString += ", ";
        tagsString += selectedTags[i];
    }
    if(UI::BeginCombo("Tags", tagsString)) {
        for(uint i = 0; i < availableTags.Length; i++) {
            int foundIndex = selectedTags.Find(availableTags[i]);
            if(UI::Selectable(availableTags[i], foundIndex != -1)) {
                if(foundIndex != -1)
                    selectedTags.RemoveAt(foundIndex);
                else
                    selectedTags.InsertLast(availableTags[i]);
                changed = true;
            }
        }
        UI::EndCombo();
    }
    return changed;
}