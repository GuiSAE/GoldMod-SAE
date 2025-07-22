Msg("Initiating dc3m6_station finale rework script\n");
//---[by:GuiSAE]

PANIC <- 0
TANK <- 1
DELAY <- 2

//-----------------------------------------------------------------------------

DirectorOptions <-
{
	A_CustomFinale_StageCount = 5
	
 	A_CustomFinale1 = PANIC
	A_CustomFinaleValue1 = 1
	
 	A_CustomFinale2 = PANIC
	A_CustomFinaleValue2 = 1

	A_CustomFinale3 = DELAY
	A_CustomFinaleValue3 = 10
	
	A_CustomFinale4 = PANIC
	A_CustomFinaleValue4 = 1
	
	A_CustomFinale5 = DELAY
	A_CustomFinaleValue5 = 10
	
	A_CustomFinale6 = PANIC
	A_CustomFinaleValue6 = 1
	
	A_CustomFinale7 = DELAY
	A_CustomFinaleValue7 = 5

	
	PreferredMobDirection = SPAWN_LARGE_VOLUME

	ZombieSpawnRange = 3000
	CommonLimit = 30
	SpecialRespawnInterval = 20
} 


