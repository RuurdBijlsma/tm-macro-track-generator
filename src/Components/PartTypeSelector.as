EPartType PartTypeSelector(EPartType currentType) {
    if(UI::BeginCombo("Type", tostring(currentType))) {
        for(uint i = 0; i < availableTypes.Length; i++) 
            if(UI::Selectable(tostring(availableTypes[i]), currentType == availableTypes[i])) 
                currentType = availableTypes[i];
        UI::EndCombo();
    }
    return currentType;
}