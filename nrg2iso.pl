#!/usr/bin/perl

sub convert (@)
{
	my $nrg = $_[0];
	my $iso = $_[1];

	printf("Converting Image : %s to %s\n",$nrg,$iso);

	my $BUF = "";
	my $OFFSET = 307200;

	open(IFILE, "<$nrg") || die "Can't open Input File !";
	open(OFILE, ">$iso") || die "Can't open Ouput File !";

	binmode(IFILE);
	binmode(OFILE);

	seek(IFILE,$OFFSET,SEEK_CUR);

	while(read(IFILE,$BUF,1048576)>0)
	{
		print OFILE $BUF;
	}

	close(IFILE);
	close(OFILE);

	print("Done\n");

	return 0;
}

print("nrg2iso 1.0 by stefan@it-brueck.de\n\n");

if( ($#ARGV+1) != 2 )
{
	print("USAGE: nrg2iso image.nrg image.iso\n");
}
else
{
	convert($ARGV[0],$ARGV[1]);
}