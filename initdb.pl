#!/usr/bin/perl
##########################################################################################
#	hivemind
#		- Interface wth 
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
# Define the database parameters && Commnect Locally 
my $host = "localhost";
my $database = "HiveMindDB";

# If the /-nuke/ is specified, it will DROP the current database
if ($#ARGV == 0 ) {
	if ($ARGV[0] =~ /nuke/){
		print "Wiping Database - $database!!!\n\n";
		system ("mysql -e \"drop database HiveMindDB\" ");
		exit;
	};
	exit;
}

##########################################################################################
####  Main
##########################################################################################


#my $dbh = DBI->connect($host, undef);

### Create database.

print "Creating Database Scheme . . .\n\n";
	system ("mysql -e \"create database $database\" ");

my $dbh = DBI->connect('dbi:mysql:'.$database,'root')
 or die "Connection Error: $DBI::errstr\n";


#Create Table samples 
print "Processing . . . table = ip_addresses\n";
my $sql_statement = "
	CREATE TABLE ip_addresses (
		ip_address_id INT(200) NOT NULL AUTO_INCREMENT,
		ip_address text,
		added text,
			PRIMARY KEY (ip_address_id)
		)";

#Submit Query 
my $sth = $dbh->prepare($sql_statement);
 $sth->execute;

# Create Table sample - outbound connections
print "Processing . . . table = ip_addresses_notes\n";
$sql_statement = "
	CREATE TABLE ip_addresses_notes (
		ip_address_id INT(200) NOT NULL REFERENCES ip_addresses(ip_address_id),
		ip_address_notes text,
		added text

	)
	";

#Submit Query 
$sth = $dbh->prepare($sql_statement);
 $sth->execute;

print "Processing . . . table = dns_addresses\n";
$sql_statement = "
	CREATE TABLE dns_addresses (
		dns_address_id INT(200) NOT NULL AUTO_INCREMENT,
		dns_address text,
		added text,

			PRIMARY KEY (dns_address_id)
		)";

#Submit Query 
$sth = $dbh->prepare($sql_statement);
 $sth->execute;

# Create Table sample - outbound connections
print "Processing . . . table = dns_addresses_notes\n";
$sql_statement = "
	CREATE TABLE dns_addresses_notes (
		dns_address_id INT(200) NOT NULL REFERENCES dns_addresses(dns_address_id),
		dns_address_notes text,
		added text
	)
	";
#Submit Query 
$sth = $dbh->prepare($sql_statement);
 $sth->execute;	
	

print "Database Scheme Created!!\n\n";


