#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;

my ($host, $port, $user, $pass);
GetOptions( "host=s" => \$host, "port=s" => \$port, "user=s" => \$user, 'pass=s' => \$pass );

my $conn     = "-h $host -P $port -u $user -p$pass";
my $core     = $ARGV[0];
my $userdata = (split /core/, $core)[0] . 'userdata';

`mysqldump  $conn --no-data $core > schema_$core.sql`;
`mysqldump  $conn $core analysis meta meta_coord coord_system seq_region > data_$core.sql`;
`mysqladmin $conn create $userdata`;
`cat schema_$core.sql | mysql $conn $userdata`;
`cat data_$core.sql   | mysql $conn $userdata`;