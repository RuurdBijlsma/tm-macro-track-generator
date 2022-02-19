namespace Sort {

MacroPart@[]@ SortParts(MacroPart@[]@ arr, dictionary@ usedParts) {
    MacroPart@[]@ result = {};
    uint arrLength = arr.Length;
    for(uint i = 0; i < arrLength; i++) {
        int lowestIndex = -1;
        int lowestUsed = 2000000000;
        for(uint j = 0; j < arr.Length; j++) {
            int usedCount = int(usedParts[arr[j].ID]);
            if(usedCount < lowestUsed) {
                lowestIndex = j;
                lowestUsed = usedCount;
            }
        }
        result.InsertLast(arr[lowestIndex]);
        arr.RemoveAt(lowestIndex);
    }
    return result;
}

}