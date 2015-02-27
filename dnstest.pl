#!/usr/bin/perl
#Written by Robert "RSnake" Hansen
use strict;
use Net::DNS;
my $res = Net::DNS::Resolver->new;

##########################################################################
# Make the following lines match where you want your config file to be
# and your email address where you want alerts to be sent.  Then add this
# to crontab with a "crontab -e" with whichever user you want it to run
# under (preferably non-root):
# 0 * * * * /usr/bin/perl /path/to/dnstest.pl >/dev/null
##########################################################################
my $config = '/PATH/TO/dnstable.dat'; #format is hostname<tab>IP<newline>
my $email  = 'EMAIL@EXAMPLE.COM';
##########################################################################

open (FILE, "$config") or
  die ("Cannot open $config\n");

my @email;
foreach (<FILE>) {
  s/\s+$//g;
  my @line = split (/\t/, $_);
  my $query = $res->search($line[0]);
  
  if (($line[0] =~ /^#/) || (!$line[0])) {
    next;
  }

  $line[0] =~ s/#.*//g;
  
  if ($query) {
    my $flag = 0;
    my $var;
    foreach my $rr ($query->answer) {
      unless (($rr->type eq 'A') || ($rr->type eq 'AAAA')) {
        next;
      }
      $var = $rr->address;
      if ($var eq $line[1]) {
        $flag = 1;
        last;
      } 
    }
    if ($flag == 0) {
      push @email, "$line[0] should be at $line[1] but it's actually at $var\n";
    }
  } else {
    push @email, "Query failed: for $line[0] ", $res->errorstring, "\n";
  }
}

if ($#email > -1) {
  open(SENDMAIL, "|/usr/sbin/sendmail -t") or die "Cannot open sendmail: $!";
  print SENDMAIL "Reply-to: $email\n";
  print SENDMAIL "Subject: DNS failed\n";
  print SENDMAIL "To: $email\n";
  print SENDMAIL "From: $email\n";
  print SENDMAIL "Content-type: text/plain\n\n";
  print SENDMAIL "DNS failed for the following:\n\n";
  foreach (@email) {
    print SENDMAIL "\t$_";
  }
  close(SENDMAIL);
}
