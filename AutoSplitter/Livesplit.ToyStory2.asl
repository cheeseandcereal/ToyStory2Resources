state("Project64", "PJ64")
{
	int level1LoadScreen : "Project64.exe", 0x107AD8, 0x3480;
	byte fBoss1Health : "Project64.exe", 0x107AD8, 0x2120;
	byte fBoss2Health : "Project64.exe", 0x107AD8, 0x2124;
	byte fBoss3Health : "Project64.exe", 0x107AD8, 0x2128;
	short buzzXPos : "Project64.exe", 0x107AD8, 0xBB078;
	byte16 tokenCount : "Project64.exe", 0x107AD8, 0x1E2DD0;
	int inLevel : "Project64.exe", 0x107AD8, 0xB0B58;
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
	int inLevel : "toy2.exe", 0x13EEEC;
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
	int inLevel : "toy2.exe", 0x14006C;
}

startup
{
	settings.Add("final_boss_split", true, "Split when defeating the final boss");
	settings.Add("level_split", true, "Split by levels instead of tokens");
}

init
{
	if (game.ProcessName == "Project64") {
		version = "PJ64";
	} else {
		var baseAddr = modules.First().BaseAddress;
		var isLoadingAddr = IntPtr.Zero;
		// detect version by using the date modified value of the EXE (the US is 0 because the header starts later)
		vars.modifiedDate = memory.ReadValue<int>(baseAddr + 0xF8);
		if (vars.modifiedDate == 0) {
			version = "US";
			isLoadingAddr = baseAddr + 0xA4EFFC;
		}
		else if (vars.modifiedDate == 0x388395FF) {
			version = "UK";
			isLoadingAddr = baseAddr + 0xA51FFC;
		}
		else {
			version = "";
		}

		// Inject load detection code

		var hooks = new dynamic[,] {
			{ 0, "83 EC 0C 8B 44 24 14 53"                  , 7, false }, // 0x414320 Enter PressJump_LevelOrFmv
			{ 0, "8B 44  24 08 83 C4 0C"                    , 7, true  }, // 0x414546 Leave PressJump_LevelOrFmv
			{ 0, "53 55 56 33 DB 57 66"                     , 5, true  }, // 0x414720 Enter LoadLevel
			{ 4, "83 C4 04 5F 8B C5"                        , 5, false }, // 0x414A70 Leave LoadLevel
			{ 0, "A1 ?? ?? ?? ?? 81 EC 10 01 00 00 53 55 56", 5, true  }, // 0x452FC0 Enter InitLevelPlay
			{ 0, "81 C4 10 01 00 00 C3 90 90 C3"            , 6, false }, // 0x453C67 Leave InitLevelPlay
			{ 0, "8B 7C 24 10 85 FF 74 0A"                  , 6, true  }, // 0x49AB99 Enter PlayFmv
			{ 0, "83 C4 04 5F 5D C3"                        , 5, false }, // 0x49AC26 Leave PlayFmv 1
			{ 0, "8B C5 5F 5D"                              , 5, false }, // 0x49AC2C Leave PlayFmv 2
			{ 0, "8B 2D ?? ?? ?? ?? 83 C4 24"               , 6, false }, // 0x4CE634 PlayFmvByFilename: start playback
			{ 0, "83 C4 04 8B C3 5F"                        , 5, true  }  // 0x4CE6A7 PlayFmvByFilename: stop playback
		};

		var scanner = new SignatureScanner(game, new IntPtr(0x401000), 0xDB000);
		for (int i = 0; i < hooks.GetLength(0); ++i) {
			var signatureOffset  = hooks[i, 0];
			var signature        = hooks[i, 1];
			int overwrittenBytes = hooks[i, 2];
			var increment        = hooks[i, 3];

			// Find address
			var hookAddr = scanner.Scan(new SigScanTarget(signatureOffset, signature));
			if (hookAddr == IntPtr.Zero) {
				print("Cannot find address to hook.");
				break;
			}

			/*
			inc/dec <load variable>
			jmp     <livesplit detour gate>
			*/
			var code = new byte[] { 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE9, 0x00, 0x00, 0x00, 0x00 };

			// Allocate memory for code
			var codeAddr = memory.AllocateMemory(code.Length);
			if (codeAddr == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();

			// Adjust code and inject it
			code[1] = (byte)(increment ? 0x05 : 0x0D);
			BitConverter.GetBytes(isLoadingAddr.ToInt32()).CopyTo(code, 2);
			var gateAddr = memory.WriteDetour(hookAddr, overwrittenBytes, codeAddr);
			BitConverter.GetBytes(gateAddr.ToInt32() - codeAddr.ToInt32() - 11).CopyTo(code, 7);
			if (!memory.WriteBytes(codeAddr, code)) throw new System.ComponentModel.Win32Exception();
		}

		vars.isLoading = new MemoryWatcher<int>(isLoadingAddr);
		vars.isLoading.Current = 0;
		vars.isLoading.Enabled = (isLoadingAddr != IntPtr.Zero);
	}

	vars.checkBossHealth = false;
}

update
{
	if (version == "") return false;
	if (version != "PJ64") {
		// Only start checking for final boss health if it is the final level, the first boss is at max health, and buzz is in the starting position
		// This makes it so we will only start checking for final boss health when entering the final level
		if (current.levelID == 15 && current.fBoss1Health == 29 && current.buzzXPos == -5416) vars.checkBossHealth = true;
		if (current.levelID != 15) vars.checkBossHealth = false; // Make sure we aren't checking for final boss health if it isn't the final level

		vars.isLoading.Update(game);
	}
}

start
{
	//31815 is the starting position in level 1. This will make it so that once buzz moves at the start of level 1, timer starts
	return (old.buzzXPos == 31815 && current.buzzXPos != old.buzzXPos);
}

split
{
	if (settings["final_boss_split"]) {
		// If enabled, split when final boss is defeated
		if (version == "PJ64") {
			// With PJ64, levelID is not supported, so it will continually split after boss is defeated
			if (current.fBoss1Health==9 && current.fBoss2Health==9 && current.fBoss3Health<=9) return true;
		} else {
			// With PC version, we will only split once, after the boss is defeated
			if (vars.checkBossHealth && current.fBoss1Health==9 && current.fBoss2Health==9 && current.fBoss3Health<=9) {
				vars.checkBossHealth = false;
				return true;
			}
		}
	}
	if (settings["level_split"]) {
		return (old.inLevel != current.inLevel) && (current.inLevel == 0);
	} else {
		return !(Enumerable.SequenceEqual(old.tokenCount, current.tokenCount));
	}
}

reset
{
	if (version == "PJ64")
		return current.level1LoadScreen == 0;
	else
		return (current.levelID == 1 && current.isLoadScreen == 1);
}

isLoading
{
	if (version == "PJ64")
		return false; // Not supported for N64
	else
		return vars.isLoading.Current != 0;
}
