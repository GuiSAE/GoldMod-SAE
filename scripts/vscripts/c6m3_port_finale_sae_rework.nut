
Msg("Initiating c6m3_port_finale_sae_rework script\n")
//---[by:GuiSAE]
//-----------------------------------------------------
PANIC <- 0
TANK <- 1
DELAY <- 2
ONSLAUGHT <- 3
//-----------------------------------------------------

SharedOptions <-
{
 	A_CustomFinale1 = ONSLAUGHT
	A_CustomFinaleValue1 = ""

	A_CustomFinale2 = PANIC
	A_CustomFinaleValue2 = 1

	A_CustomFinale3 = ONSLAUGHT
	A_CustomFinaleValue3 = "c1m4_delay"
        
	A_CustomFinale4 = TANK
	A_CustomFinaleValue4 = 1

	A_CustomFinale5 = ONSLAUGHT
	A_CustomFinaleValue5 = "c1m4_delay"

	A_CustomFinale6 = PANIC
	A_CustomFinaleValue6 = 1

	A_CustomFinale7 = ONSLAUGHT
	A_CustomFinaleValue7 = "c1m4_delay"
 
 	A_CustomFinale8 = PANIC
	A_CustomFinaleValue8 = 1

	A_CustomFinale9 = ONSLAUGHT
	A_CustomFinaleValue9 = "c1m4_delay"
 
 	A_CustomFinale10 = PANIC
	A_CustomFinaleValue10 = 1

	A_CustomFinale11 = ONSLAUGHT
	A_CustomFinaleValue11 = "c1m4_delay"

	A_CustomFinale12 = PANIC
	A_CustomFinaleValue12 = 1
        
 	A_CustomFinale13 = ONSLAUGHT
	A_CustomFinaleValue13 = "c1m4_delay"
        
	A_CustomFinale14 = TANK
	A_CustomFinaleValue14 = 2   
        
 	A_CustomFinale15 = ONSLAUGHT
	A_CustomFinaleValue15 = "c1m4_delay"
        
	A_CustomFinale16 = PANIC
	A_CustomFinaleValue16 = 1  
                  
 	A_CustomFinale17 = ONSLAUGHT
	A_CustomFinaleValue17 = "c1m4_delay"    
                       
 	A_CustomFinale18 = PANIC
	A_CustomFinaleValue18 = 1  
	
 	A_CustomFinale19 = ONSLAUGHT
	A_CustomFinaleValue19 = "c1m4_delay"
        
	A_CustomFinale20 = PANIC
	A_CustomFinaleValue20 = 1   
        
 	A_CustomFinale21 = ONSLAUGHT
	A_CustomFinaleValue21 = "c1m4_delay"
        
	A_CustomFinale22 = TANK
	A_CustomFinaleValue22 = 1  
                  
 	A_CustomFinale23 = ONSLAUGHT
	A_CustomFinaleValue23 = "c1m4_delay"    
                       
 	A_CustomFinale24 = PANIC
	A_CustomFinaleValue24 = 1
															
 	A_CustomFinale25 = ONSLAUGHT
	A_CustomFinaleValue25 = "c1m4_delay"
        
	A_CustomFinale26 = PANIC
	A_CustomFinaleValue26 = 1   
        
 	A_CustomFinale27 = ONSLAUGHT
	A_CustomFinaleValue27 = "c1m4_delay"
        
	A_CustomFinale28 = PANIC
	A_CustomFinaleValue28 = 1  
                  
 	A_CustomFinale29 = ONSLAUGHT
	A_CustomFinaleValue29 = "c1m4_delay"    
                       
 	A_CustomFinale30 = PANIC
	A_CustomFinaleValue30 = 1

 	A_CustomFinale31 = ONSLAUGHT
	A_CustomFinaleValue31 = "c1m4_delay"   

	A_CustomFinale32 = TANK
	A_CustomFinaleValue32 = 2  
                  
 	A_CustomFinale33 = ONSLAUGHT
	A_CustomFinaleValue33 = "c1m4_delay"    
                       
 	A_CustomFinale34 = PANIC
	A_CustomFinaleValue34 = 1
															
 	A_CustomFinale35 = ONSLAUGHT
	A_CustomFinaleValue35 = "c1m4_delay"
        
	A_CustomFinale36 = PANIC
	A_CustomFinaleValue36 = 1   
        
 	A_CustomFinale37 = ONSLAUGHT
	A_CustomFinaleValue37 = "c1m4_delay"
        
	A_CustomFinale38 = PANIC
	A_CustomFinaleValue38 = 1  
                  
 	A_CustomFinale39 = ONSLAUGHT
	A_CustomFinaleValue39 = "c1m4_delay"    
                       
 	A_CustomFinale40 = PANIC
	A_CustomFinaleValue40 = 1

 	A_CustomFinale41 = ONSLAUGHT
	A_CustomFinaleValue41 = "c1m4_delay"   

	A_CustomFinale42 = TANK
	A_CustomFinaleValue42 = 1  
                  
 	A_CustomFinale43 = ONSLAUGHT
	A_CustomFinaleValue43 = "c1m4_delay"    
                       
 	A_CustomFinale44 = PANIC
	A_CustomFinaleValue44 = 1
															
 	A_CustomFinale45 = ONSLAUGHT
	A_CustomFinaleValue45 = "c1m4_delay"
        
	A_CustomFinale46 = PANIC
	A_CustomFinaleValue46 = 1   
        
 	A_CustomFinale47 = ONSLAUGHT
	A_CustomFinaleValue47 = "c1m4_delay"
        
	A_CustomFinale48 = PANIC
	A_CustomFinaleValue48 = 1  
                  
 	A_CustomFinale49 = ONSLAUGHT
	A_CustomFinaleValue49 = "c1m4_delay"    
                       
 	A_CustomFinale50 = PANIC
	A_CustomFinaleValue50 = 1

 	A_CustomFinale51 = ONSLAUGHT
	A_CustomFinaleValue51 = "c1m4_delay"   
                      
	//-----------------------------------------------------

	PreferredMobDirection = SPAWN_LARGE_VOLUME
	PreferredSpecialDirection = SPAWN_LARGE_VOLUME
        
//	BoomerLimit = 0
//	SmokerLimit = 2
//	HunterLimit = 1
//	SpitterLimit = 1
//	JockeyLimit = 0
//	ChargerLimit = 1

	ProhibitBosses = true
	ZombieSpawnRange = 3000
	MobRechargeRate = 0.5
	HordeEscapeCommonLimit = 15
	BileMobSize = 15
	SpecialRespawnInterval = 20
	
	MusicDynamicMobSpawnSize = 8
	MusicDynamicMobStopSize = 2
	MusicDynamicMobScanStopSize = 1
} 

InitialOnslaughtOptions <-
{
    LockTempo = 0
	IntensityRelaxThreshold = 1.1
	RelaxMinInterval = 2
	RelaxMaxInterval = 4
	SustainPeakMinTime = 25
	SustainPeakMaxTime = 30
	
	MobSpawnMinTime = 4
	MobSpawnMaxTime = 8
	MobMinSize = 2
	MobMaxSize = 6
	CommonLimit = 5
	
	SpecialRespawnInterval = 100
}

PanicOptions <-
{

	MegaMobSize = 0 // randomized in OnBeginCustomFinaleStage
	MegaMobMinSize = 20
	MegaMobMaxSize = 40
	MaxSpecials = 5
	BoomerLimit = 1
	SmokerLimit = 2
	HunterLimit = 2
	SpitterLimit = 1
	JockeyLimit = 1
	ChargerLimit = 1
	CommonLimit = 25
	
	SpecialRespawnInterval = 25
}

TankOptions <-
{
	ShouldAllowMobsWithTank = true
	ShouldAllowSpecialsWithTank = true

	MobSpawnMinTime = 20
	MobSpawnMaxTime = 40
	MobMinSize = 3
	MobMaxSize = 5
	MaxSpecials = 3
	CommonLimit = 5
	
	SpecialRespawnInterval = 50
}


DirectorOptions <- clone SharedOptions
{
}


//-----------------------------------------------------

// number of cans needed to escape.
NumCansNeeded <- 8

// fewer cans in single player since bots don't help much
if ( Director.IsSinglePlayerGame() )
{
	NumCansNeeded <- 8
}

// duration of delay stage.
DelayMin <- 10
DelayMax <- 20

// Number of touches and/or pours allowed before a delay is aborted.
DelayPourThreshold <- 1
DelayTouchedOrPouredThreshold <- 2


// Once the delay is aborted, amount of time before it progresses to next stage.
AbortDelayMin <- 1
AbortDelayMax <- 3

// Number of touches and pours it takes to transition out of c1m4_finale_wave_1
GimmeThreshold <- 4


// console overrides
if ( Director.IsPlayingOnConsole() )
{
	DelayMin <- 20
	DelayMax <- 30
	
	// Number of touches and/or pours allowed before a delay is aborted.
	DelayPourThreshold <- 2
	DelayTouchedOrPouredThreshold <- 4
	
	TankOptions.ShouldAllowSpecialsWithTank = false
	
}
//-----------------------------------------------------
//      INIT
//-----------------------------------------------------

GasCansTouched          <- 0
GasCansPoured           <- 0
DelayTouchedOrPoured    <- 0
DelayPoured             <- 0

EntFire( "timer_delay_end", "LowerRandomBound", DelayMin )
EntFire( "timer_delay_end", "UpperRandomBound", DelayMax )
EntFire( "timer_delay_abort", "LowerRandomBound", AbortDelayMin )
EntFire( "timer_delay_abort", "UpperRandomBound", AbortDelayMax )

// this is too late. Moved to c1m4_atrium.nut
//EntFire( "progress_display", "SetTotalItems", NumCansNeeded )

function AbortDelay(){}  	// only defined during a delay, in c1m4_delay.nut
function EndDelay(){}		// only defined during a delay, in c1m4_delay.nut

NavMesh.UnblockRescueVehicleNav()

//-----------------------------------------------------

function GasCanTouched()
{
    GasCansTouched++
    Msg(" Touched: " + GasCansTouched + "\n")   
     
    EvalGasCansPouredOrTouched()    
}
    
function GasCanPoured()
{
    GasCansPoured++
    DelayPoured++
    Msg(" Poured: " + GasCansPoured + "\n")   

    if ( GasCansPoured == NumCansNeeded )
    {
        Msg(" needed: " + NumCansNeeded + "\n") 
        EntFire( "relay_car_ready", "trigger" )
    }

    EvalGasCansPouredOrTouched()
}

function EvalGasCansPouredOrTouched()
{
    TouchedOrPoured <- GasCansPoured + GasCansTouched
    Msg(" Poured or touched: " + TouchedOrPoured + "\n")

    DelayTouchedOrPoured++
    Msg(" DelayTouchedOrPoured: " + DelayTouchedOrPoured + "\n")
    Msg(" DelayPoured: " + DelayPoured + "\n")
    
    if (( DelayTouchedOrPoured >= DelayTouchedOrPouredThreshold ) || ( DelayPoured >= DelayPourThreshold ))
    {
        AbortDelay()
    }
    
    switch( TouchedOrPoured )
    {
        case GimmeThreshold:
            EntFire( "@director", "EndCustomScriptedStage" )
            break
    }
}
//-----------------------------------------------------

function AddTableToTable( dest, src )
{
	foreach( key, val in src )
	{
		dest[key] <- val
	}
}

function OnBeginCustomFinaleStage( num, type )
{
	printl( "Beginning custom finale stage " + num + " of type " + type );
	
	local waveOptions = null
	if ( num == 1 )
	{
		waveOptions = InitialOnslaughtOptions
	}
	else if ( type == PANIC )
	{
		waveOptions = PanicOptions
		waveOptions.MegaMobSize = PanicOptions.MegaMobMinSize + rand()%( PanicOptions.MegaMobMaxSize - PanicOptions.MegaMobMinSize )
		
		Msg("*************************" + waveOptions.MegaMobSize + "\n")
		
	}
	else if ( type == TANK )
	{
		waveOptions = TankOptions
		EntFire( "bonus_relay", "Trigger", 0 )
	}
	
	// give out items at certain stages
	if ( num == 3 || num == 7 || num == 15 || num == 23 )
	{
		Director.L4D1SurvivorGiveItem()
	}
	
	//---------------------------------


	MapScript.DirectorOptions.clear()
	

	AddTableToTable( MapScript.DirectorOptions, SharedOptions );

	if ( waveOptions != null )
	{
		AddTableToTable( MapScript.DirectorOptions, waveOptions );
	}
	
	
	Director.ResetMobTimer()
	
	if ( developer() > 0 )
	{
		Msg( "\n*****\nMapScript.DirectorOptions:\n" );
		foreach( key, value in MapScript.DirectorOptions )
		{
			Msg( "    " + key + " = " + value + "\n" );
		}

		if ( LocalScript.rawin( "DirectorOptions" ) )
		{
			Msg( "\n*****\nLocalScript.DirectorOptions:\n" );
			foreach( key, value in LocalScript.DirectorOptions )
			{
				Msg( "    " + key + " = " + value + "\n" );
			}
		}
	}
}

//-----------------------------------------------------


if ( Director.GetGameMode() == "coop" )
{
}
else if ( Director.GetGameMode() == "versus" )
{
	SharedOptions.ProhibitBosses = false
}

