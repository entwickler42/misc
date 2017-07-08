Xchat::PRI_NORM;

Xchat::register("Auto THX","1.0","Auto Thanks on MODE","unload");

$HOOK{'VOICE'}		= Xchat::hook_print("Channel Operator","message");
$HOOK{'OP'}			= Xchat::hook_print("Channel Voice","message");

#------------------------------------------------------------------------------
sub message( $ )
{
	Xchat::command("say \00303thank ya, thank ya - far to kind !");
	return Xchat::EAT_NONE;
}


#------------------------------------------------------------------------------
sub unload( $ )
{
	while(@h = each(%HOOK))
	{
		Xchat::unhook($h[1]);
	}
}