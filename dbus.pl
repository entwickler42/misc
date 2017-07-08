#!/usr/bin/perl -w 

use strict;
use Net::DBus;
use Net::DBus::Reactor;

my $bus = Net::DBus->system;
my $hal = $bus->get_service('org.freedesktop.Hal');
my $mgr = $hal->get_object('/org/freedesktop/Hal/Manager','org.freedesktop.Hal.Manager');

$mgr->connect_to_signal('DeviceAdded',\&on_device_added);
$mgr->connect_to_signal('DeviceRemoved',\&on_device_removed);

my $modem = $mgr->FindDeviceByCapability("modem");

foreach (@$modem){
	my $dev = $hal->get_object($_,'org.freedesktop.Hal.Device');
}

$|=1;
my $run=1;

my $rec = Net::DBus::Reactor->main();
$rec->run();

print "waiting for events";
while($run){
	print '.';
	sleep(1);
}

sub on_device_added {
	print("\nDevice added:\n");
	$run = 0;
}

sub on_device_removed {
	print("\nDevice removed:\n");
	$run = 0;
}
