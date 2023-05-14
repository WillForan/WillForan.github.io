#!/usr/bin/env perl
use strict; use warnings; use feature qq/say/;

say "WF Log";
say "[0|images/|images/|server|70]";
my %files;
foreach my $file (@ARGV){
 my $url = $file =~ s/.*\///r;
 my ($date, $title) = ("NA","NA");
 open my $fh, '<', $file;
 while($_=<$fh>){
   $date=$1 if m/^#\+DATE:.*([0-9]{4}.?[0-9]{2}.?[0-9]{2})/i;
   $title=$1 if m/^#\+TITLE: *(.*)/i;
   last if $date ne "NA" and $title ne "NA";
 }
 $files{$url} = {date=>$date, title=>$title};
}
for my $url (sort {$files{$b}->{'date'} cmp $files{$a}->{'date'}} (keys %files)) {
  say "[0|$files{$url}->{'date'} - $files{$url}->{'title'}|$url|server|70]";
}
