// file from AvondaleZPR
// https://github.com/AvondaleZPR/TMTrackGenerator/blob/main/random.as

namespace Random {


bool seedEnabled = false;
string seedText = "OPENPLANET";
double seedDouble = 0;

void SetSeed(string seed) {
	seedEnabled = true;
	seedText = seed;
	seedDouble = ConvertSeed(seedText);
}

float Float(float min = 0, float max = 1) {
	if (seedEnabled)
	{
		return rnd_Next() * (max-min) + min;
	}
	
	return Math::Rand(min, max);
}

int Int(int a, int b)
{
	if (seedEnabled)
	{
		return RandomFromSeed(a, b);
	}
	
	return Math::Rand(a, b);
}

string RandomSeed(int length)
{
	string result = "";
	string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
	
	for(int i = 0; i < length; i++)
	{
		result = result.opAdd(chars.SubStr(Math::Rand(0, chars.Length), 1));
	}
	
	return result;
}

double ConvertSeed(string seed)
{
	string newSeed = "";
	
	int length = seed.get_Length();
	if (length > 10) {length = 10;}
	for(int i = 0; i < length; i++)
	{
		newSeed = newSeed + tostring(seed[i]);
	}
	
	return Text::ParseDouble(newSeed + ".0000");
}

int RandomFromSeed(int min, int max)
{
	return int(Math::Floor(rnd_Next() * (max-min) + min));
}

float rnd_A = 45.0001;
float rnd_LEET = 1337.0000;
float rnd_M = 69.9999;
float rnd_Next()
{
	seedDouble = (rnd_A * seedDouble + rnd_LEET) % rnd_M; 
	return seedDouble % 1;
}

CGameEditorPluginMap::EMapElemColor RandomColor()
{
	int randomInt = Math::Rand(1,7);
	if(randomInt == 1)
	{
		return CGameEditorPluginMap::EMapElemColor::Default;
	}
	else if(randomInt == 2)
	{
		return CGameEditorPluginMap::EMapElemColor::White;
	}
	else if(randomInt == 3)
	{
		return CGameEditorPluginMap::EMapElemColor::Green;
	}
	else if(randomInt == 4)
	{
		return CGameEditorPluginMap::EMapElemColor::Blue;
	}
	else if(randomInt == 5)
	{
		return CGameEditorPluginMap::EMapElemColor::Red;
	}
	else if(randomInt == 6)
	{
		return CGameEditorPluginMap::EMapElemColor::Black;
	}	
	
	return CGameEditorPluginMap::EMapElemColor::Default;
}

void CheckDistribution() {
    int[] bins = {};
    uint binCount = 10;
    uint iterations = 500000;
    for(uint i = 0; i < binCount; i++) {
        bins.InsertLast(0);
    }
    for(uint i = 0; i < iterations; i++) {
        int value = Random::Int(0, 10);
        bins[value]++;
    }
    for(uint i = 0; i < binCount; i++) {
        string bar = "";
        for(uint j = 0; j < uint(bins[i] * 100 / iterations); j++) {
            bar += "x";
        }
        print(tostring(i) + ": " + bar);
    }
}

}
