#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use File::Slurp;
use FindBin qw($Bin);
use JSON;
use LWP::UserAgent;
use Parallel::ForkManager;
use Getopt::Long;

my $verbose         = undef;
my $duration        = 0;
my $har_dir         = "$Bin/http_archives/";
my $domain          = "https://pre.vectorbase.org"; 
my $max_connections = 6; # modern browsers tend to use 6 parallel connections

GetOptions (
  "verbose" => \$verbose,
  "duration=i" => \$duration
);

# random delay before we start
sleep rand $duration if $duration; 

# load specified or random http archive
my $file = $ARGV[0] || random_file($har_dir);
my $har  = from_json( read_file( "$har_dir/$file" ) );

# pull the request urls from the archive
my @urls = map { $_->{request}->{url} } @{$har->{log}->{entries}};
@urls = grep { /^$domain/ } @urls; # drop cross-domain requests
@urls = grep {$_ !~ /\.(png|gif|jpg|css|js)$/} @urls; # drop requests for static files (assume browser has cached)

# make the requests using parallel connections just like a browser would
my $pm = Parallel::ForkManager->new($max_connections);
foreach my $url ( @urls ) {
  $pm->start and next; # fork
  my $res = LWP::UserAgent->new->get($url);
  printf("%s: %s\n", $res->status_line, $url) if $verbose;
  $pm->finish;
}

# wait until all requests complete before exiting
$pm->wait_all_children;
print "Done\n";


sub random_file {
  my $dir = shift;
  opendir DIR, $dir or die "Can't open directory '$dir'";
  my @files = grep {-f "$dir/$_"} (readdir DIR);
  closedir DIR;
  return $files[rand @files];
}
