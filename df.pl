Xchat::PRI_NORM;

Xchat::register("DF","1.0","Shows DF","unload");

$DISC = `df`;

Xchat::command("msg #BT $DISC");

#------------------------------------------------------------------------------
sub unload( $ )
{
	Xchat::unhook($IHOOK);
}