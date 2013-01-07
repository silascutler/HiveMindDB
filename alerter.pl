#!/usr/bin/perl
##########################################################################################
#	hivemind -resolver
#		- Tool to resolving domains in the database
#		- Version 1.0 Beta
##########################################################################################
#     __  ___            __  ____           __
#    / / / (_)   _____  /  |/  (_)___  ____/ /
#   / /_/ / / | / / _ \/ /|_/ / / __ \/ __  / 
#  / __  / /| |/ /  __/ /  / / / / / / /_/ /  
# /_/ /_/_/ |___/\___/_/  /_/_/_/ /_/\__,_/   
#                                            
##########################################################################################
# Copyright (C) 2012, Silas Cutler
#      <Silas.Cutler@BlackListThisDomain.com / scutler@SecureWorks.com>
#
# This program is free software; you can redistribute it and/or modify it under the
#      terms of the GNU General Public License as published by the Free Software
#      Foundation; either version 2 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
#      WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#      PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
#############################################################################################

### REMOVE THIS AFTER EDITS
print "Don't forget to set MAIL SERVER details\n";
exit;


use strict;
use warnings;
use DBI;
use Getopt::Long;
use Authen::SASL;
use MIME::Lite;
use Net::DNS;


my $core_time = time;
my $res = Net::DNS::Resolver->new;


# ----- ARGUMENTS ----- #
my $database_name = "HiveMindDB";
my $database_user = "root";
my $database_password = "";


my $dbh = DBI->connect('dbi:mysql:'. $database_name,$database_user,$database_password) or die "Connection Error: $DBI::errstr\n";

print "[*] Pulling Domains for Emailing ...\n";
##### //main
my $report = "";

#######


my ($dns_id);
my $request_handle = $dbh->prepare(' SELECT 
										dns_address_id  
										FROM dns_address_resolved 
										WHERE ( ( dns_first_seen > unix_timestamp(now()) - 86400 ) && ( dns_resolved = "NULL" ) );
									');
$request_handle->execute();
$request_handle->bind_columns(undef, \$dns_id);
while($request_handle->fetch()){
	$report .= pull_dns_name($dns_id)
}
email_report($report);
sub pull_dns_name{
	my $dns_id = shift;
    my ($dns_address, $output );
    my $request_handle = $dbh->prepare('select dns_address from dns_addresses where dns_address_id = ?');
    $request_handle->execute( $dns_id );
    $request_handle->bind_columns(undef, \$dns_address);
    $request_handle->fetch();
    
    my $a_query = $res->search($dns_address);

	if ($a_query) { }
	else{
   
		$output = "\n [ Domain ] $dns_address\n";
		$output .= pull_dns_note($dns_id);
		return $output;
    }
    return "";
    
    
}
sub pull_dns_note{
	my $dns_id = shift;
    my ( $dns_note, $output ) = "";
    my $request_handle = $dbh->prepare('select dns_address_notes from dns_addresses_notes where dns_address_id = ?');
    $request_handle->execute($dns_id);
    $request_handle->bind_columns(undef,  \$dns_note);
    while($request_handle->fetch()){
    	$output .= " [ Domain ] [ Note ] $dns_note \n"
    }
    return $output;
}


## Email Alering
sub email_report{
	my $report = shift;
	my $date = `date +%Y-%m-%d`;
	chomp($date);
	
	my $from = 'FROM ADDRESS';
	
	my @to = ('threat.monitor@sh3llbox.com');
	my $subject= "DNS Change Alert $date";
	
	
	my $message = "\n\n\nIP Change Report \n\n\n$report
	";
	
	my ($user,$pass) = ('EMAILADDRESS','PASSWORD');
	
	MIME::Lite->send('smtp','MAILSERVER:PORT',AuthUser=>$user, AuthPass=>$pass);
	foreach my $recipient(@to){
		my $msg = MIME::Lite->new(
		From     => $from,
		To       => $recipient,
		Subject  => $subject,
		Data     => $message,
		Type	 => 'Text/text',
		);
		
		$msg->send or die "Message Send Faied";
		print " [+] Email Sent - $subject /$recipient !\n";
	}
}









