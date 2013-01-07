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

use strict;
use warnings;
use DBI;
use Net::DNS;
use Getopt::Long;
use Proc::Daemon;

my $res = Net::DNS::Resolver->new;
my $threads = 10;
my $running :shared= "true";
my $core_time = time;
my $continue = 1;
	



#Input Handling.
my ($debug,$help, $daemon);
usage() if ( ( 
        ! GetOptions(
                'help|?'          			      =>              \$help,
                'debug|Dbg'          			  =>              \$debug,
                'daemon|D'                        =>              \$daemon
                        )
        or defined $help  )  );


#############

sub usage{
        print "HiveMind - resolver 0.1 \n - Silas Cutler 2012\n\n";
        print "usage: ./$0
        -debug (-D)		- Debug
			\n";
  exit;
}

if (defined($daemon)){
	Proc::Daemon::Init;
}

$SIG{TERM} = sub { $continue = 0 };


# ----- ARGUMENTS ----- #
my $database_name = "HiveMindDB";
my $database_user = "root";
my $database_password = "";


my $dbh = DBI->connect('dbi:mysql:'. $database_name,$database_user,$database_password) or die "Connection Error: $DBI::errstr\n";
$dbh->{mysql_auto_reconnect} = 1;

my $sth_dns_request = $dbh->prepare('INSERT INTO dns_address_resolved 
										(dns_address_id, dns_type, dns_ttl, dns_resolved, dns_first_seen, dns_last_seen) 
										VALUES ( ? , ? , ? ,  ? , ?, ?) 
										ON DUPLICATE KEY UPDATE dns_last_seen= ? ');
										



print "[*] Spinning up...\n";
print "[*] Pulling Domains for Processing up...\n";
my %domains_ = ();

print "[*] Launch!\n";
while ($running eq "true"){
pull_domain_list();

		
        foreach my $to_resolve_domain (keys %domains_){
                my $domain_id = $domains_{$to_resolve_domain};
				resolve_handler($to_resolve_domain , $domain_id);
        }
  #      exit;
}

#######

sub pull_domain_list{
	%domains_ = ();
    my ($dns_address, $dns_id);
    my $request_handle = $dbh->prepare('select dns_address_id, dns_address from dns_addresses where ip_monitor = "1"');
    $request_handle->execute();
    $request_handle->bind_columns(undef, \$dns_id, \$dns_address);
    while($request_handle->fetch()){
    	$domains_{$dns_address} = $dns_id;
    }
}

sub resolve_handler{
	my $domain = shift;
	my $domain_id = shift;
	print "Checking $domain";
	eval{
		resolve_ip($domain_id, $domain);
		
	};
	if ($@){
		print " [XXX] Failed lookup on $domain\n";
	}
}
sub resolve_ip{
		my $domain_id = shift;
        my $domain = shift;
		$res->nameservers('8.8.8.8', '8.8.4.4');

        my $a_query = $res->search($domain);

        my %resolved = ();
        if ($a_query) {
            foreach my $rr ($a_query->answer) {
                my $resolved_domain = "";
                if ($rr->type  eq "CNAME"){
                    $resolved_domain = $rr->cname;
                }
                elsif ($rr->type  eq "A"){
                        $resolved_domain = $rr->address;
                }
                print " - Resolved to " . $resolved_domain . "\n";
                update_ip( $domain_id, $rr->type , $rr->ttl , $resolved_domain);
            }
        }else{
        	update_ip( $domain_id, "0" , "0" , "NULL");
        	print " - Failed to resolve\n";
        }
        
}

sub update_ip{
	my $dns_id = shift;
	my $dns_type = shift;
	my $dns_ttl = shift;
	my $dns_res = shift;


	eval{
		$sth_dns_request->execute($dns_id, $dns_type, $dns_ttl, $dns_res, time, time, time);
		$sth_dns_request->finish;
	};
	if ($@) {
		print " [X] Failed to Add Connection entry\n";
		return 1;
	}
	return 0;

}









