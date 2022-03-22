void EntranceSelector(MacroPart@ part) {
    UI::SetNextItemWidth(120);
    if(UI::BeginCombo("Connector", tostring(part.entranceConnector))) {
        for(uint i = 0; i < availableConnectors.Length; i++) 
            if(UI::Selectable(tostring(availableConnectors[i]), part.entranceConnector == availableConnectors[i])) 
                part.entranceConnector = availableConnectors[i];
        UI::EndCombo();
    }
    UI::SameLine();
    UI::SetNextItemWidth(149);
    part.enterSpeed = Math::Clamp(UI::InputInt("Speed", part.enterSpeed, 10), 0, 1000);
}

void ExitSelector(MacroPart@ part) {
    UI::SetNextItemWidth(120);
    if(UI::BeginCombo("Connector", tostring(part.exitConnector))) {
        for(uint i = 0; i < availableConnectors.Length; i++) 
            if(UI::Selectable(tostring(availableConnectors[i]), part.exitConnector == availableConnectors[i])) 
                part.exitConnector = availableConnectors[i];
        UI::EndCombo();
    }
    UI::SameLine();
    UI::SetNextItemWidth(149);
    part.exitSpeed = Math::Clamp(UI::InputInt("Speed", part.exitSpeed, 10), 0, 1000);
}