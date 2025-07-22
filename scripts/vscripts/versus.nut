Msg("Activating Versus Weapon\n");


DirectorOptions <- 
{
	botAvoidItems = 
	{
		weapon_hunting_rifle = true
		weapon_sniper_military = true
		weapon_sniper_awp = true
		weapon_sniper_scout = true
	}
	function ShouldAvoidItem( classname )
	{
		if ( classname in botAvoidItems )
		{
			return true;
		}
		return false;
	}
}

