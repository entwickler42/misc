#!/bin/perl

#------------------------------------------------------------------------------
# Autor	: Stefan Brück akn <refowe>
# E-Mail	: <refowe@justmail.de>
#------------------------------------------------------------------------------

# TODO
#
# Priority for voiced users
# !list only channels on list
# Load & Save Options
#

#------------------------------------------------------------------------------
$VAR{'enabled'}	   = 1;
$VAR{'trigger'}	   = "list";
$VAR{'message'}	   = "Serving Stargate and Farscape -> join #atlantis-stargate or #farscape to download <-";
$VAR{'maxqueues'}	   = 3;
$VAR{'userqueues'}   = 1;
$VAR{'maxsends'}	   = 1;
$VAR{'timeout'}  	   = 5400000;

@CHANNEL	= ('#atlantis-stargate','#farscape');
@FILE	   	= ();
@QUEUES	 	= ();
@SENDS	 	= ();

$LOGO	    = "\002\00303[\00302XDCC\00303]\002";
$VERSION  = "\002\00302 - by  \00308r \00302e \00308f \00302o \00308w \00302e\002";
$ADPREFIX = "\002\00303[\00302XDCC Active\00303]\002";

#------------------------------------------------------------------------------
Xchat::register("XDCC Plugin","1.0","XDCC Server Plugin","Unload");

$HOOK{'COMMAND'}		= Xchat::hook_command("xdcc","ProcessCommand");
$HOOK{'CHANMSG'}		= Xchat::hook_print("Channel Message","ChannelMessage");
$HOOK{'YOUMSG'}		= Xchat::hook_print("Your Message","YouMessage");
$HOOK{'CTCP'}			= Xchat::hook_print("CTCP Generic","CTCPMessage");

$HOOK{'DCCSEND'}		= Xchat::hook_print("DCC SEND Complete","CompleteDCC");
$HOOK{'DCCABORT'} 	= Xchat::hook_print("DCC SEND Abort","AbortDCC");
$HOOK{'DCCFAILED'} 	= Xchat::hook_print("DCC SEND Failed","FailedDCC");
$HOOK{'DCCSTALL'} 	= Xchat::hook_print("DCC Stall","StallDCC");
$HOOK{'DCCTIMEOUT'} 	= Xchat::hook_print("DCC Timeout","StallDCC");
$HOOK{'timer'} 		= Xchat::hook_timer($VAR{'timeout'},"NotifyChannels");

#------------------------------------------------------------------------------
Xchat::print("$LOGO	Loaded successful ! $VERSION");


#------------------------------------------------------------------------------
sub Print( $ )
{
	Xchat::print("$LOGO	$_[0]");
}

#------------------------------------------------------------------------------
sub Msg
{
	my $DEST = $_[0];
	$DEST =~ y/\[0-9]//d;
	Xchat::command("msg $DEST $_[1]");
}

#------------------------------------------------------------------------------
sub Notice
{
	my $DEST = $_[0];
	$DEST =~ y/\0-9//d;
	Xchat::command("notice $DEST $_[1]");
}

#------------------------------------------------------------------------------
sub GenNotify()
{
	my $nick = Xchat::get_info("nick");
	my $cs   = @SENDS;
	my $cq   = @QUEUES;
	return "$ADPREFIX $VAR{'message'} \00302[\00303Trigger: /ctcp $nick $VAR{trigger}\00302] \00303Sends: \00302[\00303$cs/$VAR{'maxsends'}\00302] \00303Queues: \00302[\00303$cq/$VAR{'maxqueues'}\00302] $VERSION";
}

#------------------------------------------------------------------------------
sub Filename
{
	my $filename;

	if(rindex($file,'\\') ne -1)
	{
		$filename = substr($_[0],rindex($_[0],'\\')+1,length($_[0])-rindex($_[0],'\\')+1);
	}
	elsif(rindex($_[0],'/') ne -1)
	{
		$filename = substr($_[0],rindex($_[0],'/')+1,length($_[0])-rindex($_[0],'/')+1);
	}
	else
	{
		$filename = "";
	}

	return $filename;
}

#------------------------------------------------------------------------------
sub Filesize
{
	my $size = (stat($_[0]))[7];
	return sprintf("%07.2f MB",$size/1024/1024);
}

#------------------------------------------------------------------------------
sub QueueFile
{
	my $user= $_[0];
	$user =~ y/\[0-9]//d;

	if(@QUEUES < $VAR{'maxqueues'})
	{
		my $c_userq = 0;
		foreach my $i (@QUEUES)
		{
			my @queue = split(/=/,$i);

			if($queue[0] eq $user)
			{
				$c_userq++;
			}
			if($queue[1] eq $_[1] && $queue[0] eq $user)
			{
				Notice($user,"$LOGO You have allready queryed this file !");
				return;
			}
		}
		if($c_userq >= $VAR{'userqueues'})
		{
			Notice($user,"$LOGO All u're personal slots are full !");
		}
		else
		{
			push(@QUEUES,"$user=$_[1]");
			my $file_name = Filename($_[1]);

			Notice($user,"$LOGO Sending file: $file_name");

			CheckSends();
		}
	}
	else
	{
		Notice($_[0],"$LOGO Sorry all slots are full ! Try again later.");
	}
}

#------------------------------------------------------------------------------
sub CheckSends
{
	while(@SENDS < $VAR{'maxsends'} && @QUEUES ne 0)
	{
		$next_send = $QUEUES[0];
		shift(@QUEUES);
		push(@SENDS,$next_send);
		my @queue = split(/=/,$next_send);
		Xchat::command("dcc send $queue[0] \"$queue[1]\"");
	}
}

#------------------------------------------------------------------------------
sub CompleteDCC
{
	RemoveSend($_[0][1],$_[0][0]);
	CheckSends();
}

#------------------------------------------------------------------------------
sub AbortDCC
{
	RemoveSend($_[0][0],$_[0][1]);
	CheckSends();
}

#------------------------------------------------------------------------------
sub FailedDCC
{
	RemoveSend($_[0][1],$_[0][0]);
	CheckSends();
}

#------------------------------------------------------------------------------
sub StallDCC
{
	RemoveSend($_[0][2],$_[0][1]);
	CheckSends();
}

#------------------------------------------------------------------------------
sub RemoveSend
{
	my $pos = 0;

	foreach my $i (@SENDS)
	{
		my @send = split(/=/,$i);
		my $file = Filename($send[1]);

		if($send[0] eq $_[0] && $file eq $_[1])
		{
			splice(@SENDS,$pos,1);
			return;
		}
		$pos++;
	}
}

#------------------------------------------------------------------------------
sub ProcessCommand( $ )
{
	if($_[0][1] eq 'help')
	{
		Print('Usage: ');
		Print("-");
		Print('     /xdcc on');
		Print('     /xdcc off');
		Print('     /xdcc notify');
		Print('     /xdcc timeout <MINUTES>');
		Print('     /xdcc message <MESSAGE>');
		Print('     /xdcc channels');
		Print('     /xdcc addchannel <CHANNEL>');
		Print('     /xdcc delchannel <INDEX>');
		Print('     /xdcc files');
		Print('     /xdcc addfile <PATH>');
		Print('     /xdcc adddir <PATH>');
		Print('     /xdcc delfile <INDEX>');
		Print('     /xdcc maxqueues <NUMBER>');
		Print('     /xdcc userqeues <NUMBER>');
		Print('     /xdcc maxsents <NUMBER>');
		Print('     /xdcc options');
		Print('     /xdcc queues');
		Print('     /xdcc mvqueue <SLOT> <SLOT>');
		Print('     /xdcc delqueue <NUMBER>');
		Print('     /xdcc delsend <NUMBER>');
		Print('     /xdcc sends');
		Print('     /xdcc save');
		Print('     /xdcc load');
		Print("-");
	}
	elsif($_[0][1] eq 'on')
	{
		$VAR{'enabled'} = 1;
		Print('Server is enabled now !');
	}
	elsif($_[0][1] eq 'off')
	{
		$VAR{'enabled'} = 0;
		Print('Server is disabled now !');
	}
	elsif($_[0][1] eq 'notify')
	{
		NotifyChannels();
	}
	elsif($_[0][1] eq 'timeout')
	{
		SetTimeout($_[0][2]);
	}
	elsif($_[0][1] eq 'message')
	{
		SetMessage($_[0][2]);
	}
	elsif($_[0][1] eq 'addchannel')
	{
		AddChannel($_[0][2]);
	}
	elsif($_[0][1] eq 'delchannel')
	{
		DelChannel($_[0][2]);
	}
	elsif($_[0][1] eq 'channels')
	{
		ShowChannels();
	}
	elsif($_[0][1] eq 'addfile')
	{
		AddFile($_[0][2]);
	}
	elsif($_[0][1] eq 'adddir')
	{
		Adddir($_[0][2]);
	}
	elsif($_[0][1] eq 'mvqueue')
	{
		MvQueue($_[0][2],$_[0][2]);
	}
	elsif($_[0][1] eq 'delfile')
	{
		DelFile($_[0][2]);
	}
	elsif($_[0][1] eq 'files')
	{
		ShowFiles();
	}
	elsif($_[0][1] eq 'maxqueues')
	{
		if($_[0][2] && $_[0][2] > 0)
		{
			$VAR{'maxqueues'} = $_[0][2];
			Print("Setting maxqueues to: $_[0][2]");
		}
		else
		{
			Print("Invaild Value !");
		}
	}
	elsif($_[0][1] eq 'userqueues')
	{
		if($_[0][2] && $_[0][2] > 0)
		{
			$VAR{'userqueues'} = $_[0][2];
			Print("Setting userqueues to: $_[0][2]");
		}
		else
		{
			Print("Invaild Value !");
		}
	}
	elsif($_[0][1] eq 'maxsends')
	{
		if($_[0][2] && $_[0][2] > 0)
		{
			$VAR{'maxsends'} = $_[0][2];
			Print("Setting maxsends to: $_[0][2]");
		}
		else
		{
			Print("Invaild Value !");
		}
	}
	elsif($_[0][1] eq 'options')
	{
		Print("Current settings :");
		Print("-");
		Print("message: $VAR{'message'}");
		Print("userqueues: $VAR{'userqueues'}");
		Print("maxqueues: $VAR{'maxqueues'}");
		Print("maxsends: $VAR{'maxsends'}");
		Print("timeout: $VAR{'timeout'}");
		Print("-");
	}
	elsif($_[0][1] eq 'queues')
	{
		ShowQueues();
	}
	elsif($_[0][1] eq 'delqueue')
	{
		DelQueue($_[0][2]);
	}
	elsif($_[0][1] eq 'delsend')
	{
		DelSend($_[0][2]);
	}
	elsif($_[0][1] eq 'sends')
	{
		ShowSends();
	}
	elsif($_[0][1] eq 'save')
	{
		SaveConfig();
	}
	elsif($_[0][1] eq 'load')
	{
		LoadConfig();
	}
	else
	{
		Print('Unknown Command !');
	}

	return Xchat::EAT_ALL;
}

#------------------------------------------------------------------------------
sub YouMessage( $ )
{

	return Xchat::EAT_NONE;
}

#------------------------------------------------------------------------------
sub ChannelMessage( $ )
{
	if($VAR{'enabled'} eq 1)
	{
		if($_[0][1] eq '!list' || $_[0][1] eq 'xdcc list')
		{
			Notice($_[0][0],GenNotify());
			return Xchat::EAT_NONE;
		}
	}
	return Xchat::EAT_NONE;
}

#------------------------------------------------------------------------------
sub CTCPMessage( $ )
{
	if($VAR{'enabled'} eq 1)
	{
		my $mynick  = Xchat::get_info("nick");
		my @request = split(/ /,$_[0][0]);
		my $reason 	= $request[0];
		my $number 	= $request[1];

		if($reason eq uc($VAR{'trigger'}))
		{
			Notice($_[0][1],GenNotify());
			Notice($_[0][1],"$LOGO");
			Notice($_[0][1],"$LOGO Usage:");
			Notice($_[0][1],"$LOGO          /ctcp $mynick send [PACK]");
			Notice($_[0][1],"$LOGO          /ctcp $mynick remove [SLOT]");
			Notice($_[0][1],"$LOGO          /ctcp $mynick queues");
			Notice($_[0][1],"$LOGO");
			Notice($_[0][1],"$LOGO The folowing packs are available:");
			Notice($_[0][1],"$LOGO -");

			my $pos  = 1;

			foreach my $file (@FILE)
			{
				my $filename = Filename($file);
				my $size = Filesize($file);
				my $pos_str = sprintf("%03i",$pos);

				Notice($_[0][1],"$LOGO     \00303[\00302$pos_str\00303] \00303[\00302$size\00303] - $filename");
				$pos++;
			}

			Notice($_[0][1],"$LOGO -");
		}
		elsif($reason eq 'SEND')
		{
			if($number <= @FILE)
			{
				QueueFile($_[0][1],$FILE[$number-1]);
			}
			else
			{
				Notice($_[0][1],"$LOGO No such file !");
			}
		}
		elsif($reason eq 'REMOVE')
		{
			my @queue 		= split(/=/,$QUEUES[$number-1]);

			Print("$number");

			if(@QUEUES < $number || $number eq 0 || $number eq "")
			{
				Notice($_[0][1],"$LOGO No such slot !");
			}
			elsif($queue[0] eq $_[0][1])
			{
				Notice($_[0][1],"$LOGO slot removed !");
				splice(@QUEUES,$number-1,1);
			}
			else
			{
				Notice($_[0][1],"You do not own that slot!");
			}
		}
		elsif($reason eq 'QUEUES')
		{
			my $pos = 1;

			Notice($_[0][1],"$LOGO Queues :");
			Notice($_[0][1],"$LOGO -");
			foreach my $i (@QUEUES)
			{
				my @queue 		= split(/=/,$i);
				my $file_show	= Filename($queue[1]);
				my $pos_str 	= sprintf("%03i",$pos);

				Notice($_[0][1],"$LOGO     \00303[\00302$pos_str\00303] $queue[0] - $file_show");
				$pos++;
			}
			Notice($_[0][1],"$LOGO -");
		}
	}

	return xChat::EAT_ALL;
}

#------------------------------------------------------------------------------
sub NotifyChannels()
{
	if($VAR{'enabled'} eq 1)
	{
		foreach my $chan (@CHANNEL)
		{
			Msg($chan,GenNotify());
		}
	}
	return 1;
}

#------------------------------------------------------------------------------
sub SetTimeout
{
	Xchat::unhook($HOOK{'timer'});

	if( $_[0] > 0 )
	{
		$VAR{'timeout'} = $_[0]*60000;
		$HOOK{'timer'}  = Xchat::hook_timer($VAR{'timeout'},"NotifyChannels");

		Print("Notify timer set to $_[0] Minutes!");
	}
	else
	{
		Print("Notify timer disabled !");
	}
}

#------------------------------------------------------------------------------
sub SetTrigger( $ )
{
	$VAR{'trigger'} = $_[0];
	Print("Trigger is now : $VAR{'trigger'}");
}

#------------------------------------------------------------------------------
sub SetMessage( $ )
{
	$VAR{'message'} = $_[0];
	Print("Message is now : $VAR{'message'}");
}

#------------------------------------------------------------------------------
sub AddChannel( $ )
{
	foreach my $chan (@CHANNEL)
	{
		if($chan eq $_[0])
		{
			Print("Channel allready added !");
			return;
		}
	}

	Print("Adding channel: $_[0]");
	push(@CHANNEL,$_[0]);
}

#------------------------------------------------------------------------------
sub DelChannel( $ )
{
	if($_[0] <= @CHANNEL )
	{
		Print("Removing Channel: $CHANNEL[$_[0]-1]");
		splice(@CHANNEL, $_[0]-1, 1);
	}
	else
	{
		Print("There is no channel number: $_[0]");
	}
}

#------------------------------------------------------------------------------
sub ShowChannels()
{
	if(@CHANNEL ne 0)
	{
		Print('Channels to Notify :');

		my $POS=1;
		foreach my $chan (@CHANNEL)
		{
			Print("     $POS. $chan");Print("$entry");
			$POS++;
		}
	}
	else
	{
		Print('No channels to notify yet !');
	}
}

#------------------------------------------------------------------------------
sub AddFile( $ )
{
	open(HANDLE,$_[0]) || return Print("No access to that file ! Check the Path plz.");
	close(HANDLE);

	foreach my $f (@FILE)
	{
		if($f eq $_[0])
		{
			Print("File allready added !");
			return;
		}
	}

	Print("Adding file: $_[0]");
	push(@FILE,$_[0]);
}

#------------------------------------------------------------------------------
sub Adddir( $ )
{
	opendir(DIR,$_[0]) || return Print("No access to that directory ! Check the Path pzl.");

	while($entry = readdir(DIR))
	{
		if(!-d $entry)
		{
			AddFile("$_[0]$entry");
		}
	}

	closedir(DIR);
}

#------------------------------------------------------------------------------
sub DelFile( $ )
{
	if($_[0] <= @FILE )
	{
		Print("Removing file: $FILE[$_[0]-1]");
		splice(@FILE, $_[0]-1, 1);
	}
	else
	{
		Print("There is no file number: $_[0]");
	}
}

#------------------------------------------------------------------------------
sub ShowFiles()
{
	if(@FILE ne 0)
	{
		Print("Shared files :");
		Print("-");

		my $pos=1;
		foreach my $f (@FILE)
		{
			my $size    = Filesize($f);
			my $pos_str = sprintf("%03i",$pos);
			Print("     \00303[\00302$pos_str\00303] \00303[\00302$size\00303] $f");
			$pos++;
		}
		Print("-");
	}
	else
	{
		Print("No files available yet !");
	}
}

#------------------------------------------------------------------------------
sub ShowQueues()
{
	my $pos = 1;
	Print("Queues :");
	Print("-");
	foreach my $i (@QUEUES)
	{
		my @queue 	= split(/=/,$i);
		my $size 	= Filesize($queue[1]);
		my $pos_str = sprintf("%03i",$pos);

		Print("     \00303[\00302$pos_str\00303] \00303[\00302$size\00303] $queue[0] - $queue[1]");
		$pos++;
	}
	Print("-");
}

#------------------------------------------------------------------------------
sub MvQueue
{
	$q = $QUEUES[$_[0]-1];
	$QUEUES[$_[0]-1] = $QUEUES[$_[1]-1];
	$QUEUES[$_[1]-1] = $q;
}

#------------------------------------------------------------------------------
sub DelQueue
{
	if($_[0] <= @QUEUES)
	{
		Print("Queue number $_[0] removed !");
		splice(@QUEUES, $_[0]-1, 1);
	}
	else
	{
		Print("No such queue !");
	}
}

#------------------------------------------------------------------------------
sub DelSend
{
	if($_[0] <= @SENDS)
	{
		Print("Send number $_[0] removed !");
		splice(@SENDS, $_[0]-1, 1);
	}
	else
	{
		Print("No such send !");
	}
}

#------------------------------------------------------------------------------
sub ShowSends()
{
	my $pos = 1;
	Print("Sends :");
	Print("-");
	foreach my $i (@SENDS)
	{
		my @send 	= split(/=/,$i);
		my $size 	= Filesize($send[1]);
		my $pos_str = sprintf("%03i",$pos);

		Print("     \00303[\00302$pos_str\00303] \00303[\00302$size\00303] $send[0] - $send[1]");
		$pos++;
	}
	Print("-");
}

#------------------------------------------------------------------------------
sub SaveConfig()
{
	$home = Xchat::get_info("xchatdir");
	$home = "$home/xdcc.conf";

	open(F,">$home") || return Print("Can't save config !");

	print F "enabled=$VAR{'enabled'}\n";
	print F "trigger=$VAR{'trigger'}\n";
	print F "message=$VAR{'message'}\n";
	print F "maxqueues=$VAR{'maxqueues'}\n";
	print F "userqueues=$VAR{'userqueues'}\n";
	print F "maxsends=$VAR{'maxsends'}\n";

	foreach my $chan (@CHANNEL)
	{
		print F "channel=$chan\n";
	}
	foreach my $file (@FILE)
	{
		print F "file=$file\n";
	}

	close(F);
}

#------------------------------------------------------------------------------
sub LoadConfig()
{
	$home = Xchat::get_info("xchatdir");
	$home = "$home/xdcc.conf";

	open(F,"<$home") || return Print("Can't load config !");
	@conf = <F>;

	splice(@FILE,0,@FILE);
	splice(@CHANNEL,0,@CHANNEL);

	foreach my $i (@conf)
	{
		my @value = split(/=/,$i);

		if($value[0] eq 'enabled')
		{
			$VAR{'enabled'} = $value[1];
		}
		if($value[0] eq 'trigger')
		{
			$VAR{'trigger'} = $value[1];
		}
		if($value[0] eq 'message')
		{
			$VAR{'message'} = $value[1];
		}
		if($value[0] eq 'maxqueues')
		{
			$VAR{'maxqueues'} = $value[1];
		}
		if($value[0] eq 'userqueues')
		{
			$VAR{'userqueues'} = $value[1];
		}
		if($value[0] eq 'maxsends')
		{
			$VAR{'maxsends'} = $value[1];
		}
		if($value[0] eq 'file')
		{
			AddFile($value[1]);
		}
		if($value[0] eq 'channel')
		{
			AddChannel($value[1]);
		}
	}

	close(F);
}

#------------------------------------------------------------------------------
sub Unload( $ )
{
	while(@h = each(%HOOK))
	{
		Xchat::unhook($h[1]);
	}
}
