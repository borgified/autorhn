#!/usr/bin/env perl

use warnings;
use strict;
use CGI qw/:standard/;
use Net::OpenSSH;


my $hostname=param('hostname');
my $password=param('password');
my $add=param('add');
my $remove=param('remove');

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

print header;

my %config = do "/secret/rhn.config";

if($add=~/\w+/){
	$ssh->system("rhn-channel -a --user=$config{'rhn_user'} --password=$config{'rhn_pass'} --channel=$add") or die "problem: ".$ssh->error;
	print "adding $add<br>";

}elsif($remove=~/\w+/){
	$ssh->system("rhn-channel -r --user=$config{'rhn_user'} --password=$config{'rhn_pass'} --channel=$remove") or die "problem: ".$ssh->error;
	print "removing $remove<br>";

}else{
	print "nothing to do!<br>";
}
print "<a href='/cgi-bin/autorhn/modify_subscription/list.pl?&hostname=$hostname&password=$password'>View Channels</a>";
