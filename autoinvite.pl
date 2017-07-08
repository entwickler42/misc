Xchat::PRI_NORM;

Xchat::register("Autoinvite Plugin","1.0","Autoinvites everyone who joins to an other channel","UnloadInvite");

@ICHANELS	= ("#atlantis-stargate","#FARSCAPE","#SciFiCore");
$TOCHAN		= "#BT";
$IHOOK		= Xchat::hook_print("Join","Inviteuser");

sub Inviteuser( $ )
{

	foreach my $chan (@ICHANELS)
	{

		if($chan eq $_[0][1])
		{
			Xchat::command("invite $_[0][0] $TOCHAN");
		}
	}
	return Xchat::EAT_NONE;
}

#------------------------------------------------------------------------------
sub UnloadInvite( $ )
{
	Xchat::unhook($IHOOK);
}