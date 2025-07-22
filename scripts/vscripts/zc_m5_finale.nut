Msg("Initiating zc_m5_finale rework script\n");
//---[by:GuiSAE]

PANIC <- 0
TANK <- 1
DELAY <- 2
ONSLAUGHT <- 3

//-----------------------------------------------------------------------------

SharedOptions <-
{
	A_CustomFinale_StageCount = 10
	
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
	
	A_CustomFinale7 = PANIC
	A_CustomFinaleValue7 = 1
	
	A_CustomFinale8 = DELAY
	A_CustomFinaleValue8 = 10

	A_CustomFinale9 = TANK
	A_CustomFinaleValue9 = 1

	A_CustomFinale10 = DELAY
	A_CustomFinaleValue10 = 10
	
	PreferredMobDirection = SPAWN_LARGE_VOLUME
	PreferredSpecialDirection = SPAWN_LARGE_VOLUME

	ZombieSpawnRange = 4000
	
	SpecialRespawnInterval = 20
} 

PanicOptions <-
{
	CommonLimit = 30
}


DirectorOptions <- clone SharedOptions
{
}
