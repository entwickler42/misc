Xchat::PRI_HIGH;

Xchat::register("Autovoice Plugin","1.0","Autovoice to everyone who joins","Unload");

@VCHANELS	= ("#BT");
$VHOOK		= Xchat::hook_print("Join","Voiceuser");

Xchat::print("Autovoice Plugin 1.0 loaded...");

sub Voiceuser( $ )
{
	foreach my $chan (@VCHANELS)
	{
		if($chan eq $_[0][1])
		{
			Xchat::command("msg $chan \00303Welcome to $chan $_[0][0]!");
			Xchat::command("mode +v $_[0][0]");
		}
	}

	return Xchat::EAT_NONE;
}

#------------------------------------------------------------------------------
sub Unload( $ )
{
	Xchat::unhook($VHOOK);
}