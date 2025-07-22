//-----------------------------------------------------
Msg("Initiating c4m5_milltown_escape_finale_sae_rework script\n");
//---[by:GuiSAE]
//-----------------------------------------------------

//-----------------------------------------------------

local PANIC = 0
local TANK = 1
local DELAY = 2

//-----------------------------------------------------

DirectorOptions <-
{
	//-----------------------------------------------------

	 A_CustomFinale_StageCount = 8
	 
	 A_CustomFinale1 = PANIC
	 A_CustomFinaleValue1 = 1
	 
	 A_CustomFinale2 = PANIC
	 A_CustomFinaleValue2 = 1
	 
	 A_CustomFinale3 = DELAY
	 A_CustomFinaleValue3 = 10
	 
	 A_CustomFinale4 = TANK
	 A_CustomFinaleValue4 = 1
	 
	 A_CustomFinale5 = DELAY
	 A_CustomFinaleValue5 = 10
	 
	 A_CustomFinale6 = PANIC
	 A_CustomFinaleValue6 = 1
	 
	 A_CustomFinale7 = DELAY
	 A_CustomFinaleValue7 = 10
	 
	 A_CustomFinale8 = TANK
	 A_CustomFinaleValue8 = 1
	 
	 A_CustomFinale9 = DELAY
	 A_CustomFinaleValue9 = 15
	 
	 
	HordeEscapeCommonLimit = 15
	CommonLimit = 20
	SpecialRespawnInterval = 80


}
