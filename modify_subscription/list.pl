#!/usr/bin/env perl

use warnings;
use strict;
use CGI qw/:standard/;
use Net::OpenSSH;


my $hostname=param('hostname');
my $password=param('password');

#check if host is pingable before proceeding
my $pingable=0;
my $ping_error;
my $ping = `ping -c1 -W2 $hostname 2>/dev/null`;
$ping =~ s/\n//;
if($ping =~ /100% packet loss/){
	$ping_error="$hostname is unpingable, skipping...\n";
	$pingable=0;
}elsif($ping =~ / 0% packet loss/){
	$ping_error="$hostname is alive, continuing... ";
	$pingable=1;
}elsif($? == 512){
  $ping_error="$hostname doesn't resolve, aborting...\n";
	$pingable=0;
}else{
	$ping_error="$hostname responded unexpectedly to our ping test ($?), aborting...\n";
	$pingable=0;
}

if(!$pingable){
	print header,$ping_error;
	exit;
}

#register to RHN

my $login_error;
my($stdout,$stderr,$exit);
my $ssh=Net::OpenSSH->new($hostname,
	user => 'root',
	passwd => $password,
	ctl_dir => '/home/apache',
	master_opts => [-o => "StrictHostKeyChecking=no",
	-o => "UserKnownHostsFile=/home/apache/.ssh/known_hosts2",
	],
);

if($ssh->error){
	print header;
	print "Can't ssh to $hostname: " . $ssh->error;
	exit;
}

my %config = do "/secret/rhn.config";

print header;
print "<h3>Current channels</h3><p>";
my $current=$ssh->capture("rhn-channel -l");
$ssh->error and die $ssh->error;
$current=~s/\s/<br>/g;
print $current;
print "<hr>";
print "<h3>Available channels</h3>";
my $available=$ssh->capture("rhn-channel -L --user=$config{'rhn_user'} --password=$config{'rhn_pass'} ");
$ssh->error and die $ssh->error;
$available=~s/\s/<br>/g;
print $available;
print "<hr>";
print "You may ADD from the list of Available channels or REMOVE from the list of Current channels (just copy/paste from above)<br>";
print <<FORM;
<form action="/cgi-bin/autorhn/modify_subscription/change.pl" method="POST">
<table>
<input type="hidden" name="hostname" value="$hostname">
<input type="hidden" name="password" value="$password">
<tr><td>Add channel</td><td><input type="text" name="add"></td></tr>
<tr><td>Remove channel</td><td><input type="text" name="remove"></td></tr>
</table>
<input type="submit">
</form>
</body>
FORM

