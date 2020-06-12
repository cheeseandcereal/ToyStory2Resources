state("Project64", "PJ64")
{
	int level1LoadScreen : "Project64.exe", 0x107AD8, 0x3480;
	byte fBoss1Health : "Project64.exe", 0x107AD8, 0x2120;
	byte fBoss2Health : "Project64.exe", 0x107AD8, 0x2124;
	byte fBoss3Health : "Project64.exe", 0x107AD8, 0x2128;
	short buzzXPos : "Project64.exe", 0x107AD8, 0xbb078;
	byte16 tokenCount : "Project64.exe", 0x107AD8, 0x1e2dd0;
}

state("toy2", "US")
{
	int isLoadScreen : "toy2.exe", 0x15A0E0;
	int levelID : "toy2.exe", 0x15A0E4;
	byte fBoss1Health : "toy2.exe", 0x130028;
	byte fBoss2Health : "toy2.exe", 0x13002C;
	byte fBoss3Health : "toy2.exe", 0x130030;
	short buzzXPos : "toy2.exe", 0x12F308;
	byte16 tokenCount : "toy2.exe", 0x12F0D8;
}

state("toy2", "UK")
{
	int isLoadScreen : "toy2.exe", 0x15B2E0;
	int levelID : "toy2.exe", 0x15B2E4;
	byte fBoss1Health : "toy2.exe", 0x1311A8;
	byte fBoss2Health : "toy2.exe", 0x1311AC;
	byte fBoss3Health : "toy2.exe", 0x1311B0;
	short buzzXPos : "toy2.exe", 0x130488;
	byte16 tokenCount : "toy2.exe", 0x130258;
}

init
{
	if (game.ProcessName == "Project64") {
		version = "PJ64";
	} else {
		// detect version by using the date modified value of the EXE (the US is 0 because the header starts later)
		vars.modifiedDate = memory.ReadValue<int>(modules.First().BaseAddress + 0xF8);
		if (vars.modifiedDate == 0)
			version = "US";
		else if (vars.modifiedDate == 0x388395FF)
			version = "UK";
	}
}

update
{
	if (version == "") return false;
}

start
{
	//31815 is the starting position in level 1. This will make it so that once buzz moves at the start of level 1, timer starts
	return (old.buzzXPos == 31815 && current.buzzXPos != old.buzzXPos);
}

split
{
	if(current.fBoss1Health==9 && current.fBoss2Health==9 && current.fBoss3Health<=9) //if final boss is defeated
		return true;
	return !(Enumerable.SequenceEqual(old.tokenCount, current.tokenCount));
}

reset
{
	if (version == "PJ64")
		return current.level1LoadScreen == 0;
	else
		return (current.levelID == 1 && current.isLoadScreen == 1);
}
