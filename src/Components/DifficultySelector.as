EDifficulty DifficultySelector(EDifficulty currentType) {
    if(UI::BeginCombo("Difficulty", tostring(currentType))) {
        for(uint i = 0; i < availableDifficulties.Length; i++) 
            if(UI::Selectable(tostring(availableDifficulties[i]), currentType == availableDifficulties[i])) 
                currentType = availableDifficulties[i];
        UI::EndCombo();
    }
    return currentType;
}