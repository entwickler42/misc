Xchat::PRI_NORM;

Xchat::register("Ding","1.0","Dictionary","unload");

$PATH_DIC 				= "/store/Appz/ding-1.2/ger-eng.txt";

$HOOK{'UCOMMAND'}		= Xchat::hook_command("ding","translate");
$HOOK{'CHANMSG'}		= Xchat::hook_print("Channel Message","translateChan");
$HOOK{'YOUMSG'}		= Xchat::hook_print("Your Message","translateChan");

#------------------------------------------------------------------------------
sub translate( $ )
{
	my $TERM = "$_[1][1]";
	my $RET  = `egrep -h -w -i -e "$TERM" $PATH_DIC`;

	Xchat::print("\002\00303----------------------------------------------------------------------------------------------------");
	Xchat::print("\002\00303Translation for: \00308$TERM");
	Xchat::print("\002\00303----------------------------------------------------------------------------------------------------");

	Xchat::print("$RET");

	Xchat::print("\002\00303----------------------------------------------------------------------------------------------------");
}

#------------------------------------------------------------------------------
sub translateChan( $ )
{
	my $POS = index($_[0][1]," ");

	if($POS == -1)
	{
		return Xchat::EAT_NONE;
	}

	my $TERM    = substr($_[0][1],$POS,length($_[0][1]));
	my $CMD     = substr($_[0][1],0,$POS);

	if($CMD eq '!ding')
	{
		my $NICK = "$_[0][0]";
		$NICK =~ s/\cC\d{1,2}//g;
		my $RET  = `egrep -h -w -i -e "$TERM" $PATH_DIC`;

		Xchat::print("called by: $NICK");

		Xchat::command("notice $NICK \002\00303----------------------------------------------------------------------------------------------------");
		Xchat::command("notice $NICK \002\00303Translation for: \00308$TERM");
		Xchat::command("notice $NICK \002\00303----------------------------------------------------------------------------------------------------");


		my @TRANS = split(/\n/,$RET);

		foreach my $LINE (@TRANS)
		{
			Xchat::command("notice $NICK - $LINE");
		}

		Xchat::command("notice $NICK \002\00303----------------------------------------------------------------------------------------------------");
	}

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