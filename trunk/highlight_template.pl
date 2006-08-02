eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 2/16/2006
#         $Id$
# ******************************************************************

# ******************************************************************
# Pragma Section
# ******************************************************************

use strict;
use FileHandle;
use File::Basename;

# ******************************************************************
# Data Section
# ******************************************************************

my(%keywords) = (## These correspond to those in TemplateParser.pm
                 'if'              => 1,
                 'else'            => 1,
                 'endif'           => 1,
                 'noextension'     => 0,
                 'dirname'         => 0,
                 'basename'        => 0,
                 'basenoextension' => 0,
                 'foreach'         => 2,
                 'forfirst'        => 2,
                 'fornotfirst'     => 2,
                 'fornotlast'      => 2,
                 'forlast'         => 2,
                 'endfor'          => 2,
                 'eval'            => 0,
                 'comment'         => 0,
                 'marker'          => 0,
                 'uc'              => 0,
                 'lc'              => 0,
                 'ucw'             => 0,
                 'normalize'       => 0,
                 'flag_overrides'  => 0,
                 'reverse'         => 0,
                 'sort'            => 0,
                 'uniq'            => 0,
                 'multiple'        => 0,
                 'starts_with'     => 0,
                 'ends_with'       => 0,
                 'contains'        => 0,
                 'compares'        => 0,
                 'duplicate_index' => 0,
                 'transdir'        => 0,

                 ## These correspond to those in ProjectCreator.pm
                 'cat'   => 0,
                 'cmp'   => 0,
                 'cp'    => 0,
                 'mkdir' => 0,
                 'mv'    => 0,
                 'os'    => 0,
                 'rm'    => 0,
                 'nul'   => 0,
                 'gt'    => 0,
                 'lt'    => 0,
                 'and'   => 0,
                 'or'    => 0,
                 'quote' => 0,
                );

my($ifmod)     = 0;
my($formod)    = 0;
my($cmod)      = 50;
my(%keycolors) = (0 => [160, 32, 240],
                  1 => [255, 50, 50],
                  2 => [50, 50, 255],
                 );
my($version)   = '1.2';

# ******************************************************************
# Subroutine Section
# ******************************************************************

sub convert_to_html {
  my($line) = shift;
  $line =~ s/&/&amp;/g;
  $line =~ s/</&lt;/g;
  $line =~ s/>/&gt;/g;
  $line =~ s/"/&quot;/g;
  $line =~ s/ /&nbsp;/g;
  $line =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;/g;
  $line =~ s/\n/<br>/;
  return $line;
}


sub usageAndExit {
  print "highlight_template.pl v$version\n",
        "Usage: ", basename($0), " <template> [html output]\n\n",
        "This script will color highlight the template provided using\n",
        "varying colors for the different keywords, variables and text.\n",
        "Nested if's and foreach's will have slightly different colors.\n";
  exit(0);
}

# ******************************************************************
# Main Section
# ******************************************************************

my($status) = 0;
my($fh)     = new FileHandle();
my($input)  = $ARGV[0];
my($output) = $ARGV[1];

if (!defined $input || $input =~ /^-/) {
  usageAndExit();
}

if (!defined $output) {
  $output = $input;
  $output =~ s/\.mpd$//;
  $output .= '.html';
}

if (open($fh, $input)) {
  my($deftxt) = 'black';
  my(@codes)  = ();
  while(<$fh>) {
    my($len) = length($_);
    for(my $start = 0; $start < $len;) {
      my($sindex) = index($_, '<%', $start);
      if ($sindex >= 0) {
        my($left) = substr($_, $start, $sindex - $start);
        if ($left ne '') {
          push(@codes, [$deftxt, $left]);
        }
        my($eindex) = index($_, '%>', $sindex);
        if ($eindex >= $sindex) {
          $eindex += 2;
        }
        else {
          $eindex = $len;
        }

        my($part)  = substr($_, $sindex, $eindex - $sindex);
        my($key)   = substr($part, 2, length($part) - 4);
        my($name)  = $key;
        my($color) = 'green';
        my(@entry) = ();
        if ($key =~ /^([^\(]+)\(.*\)/) {
          $name = $1;
          if (defined $keywords{$name}) {
            @entry = @{$keycolors{$keywords{$1}}};
          }
        }
        elsif (defined $keywords{$key}) {
          @entry = @{$keycolors{$keywords{$key}}};
        }

        if (defined $entry[0]) {
          if ($name eq 'if') {
            $ifmod++;
            $entry[0] -= ($cmod * ($ifmod - 1));
          }
          elsif ($name eq 'endif') {
            $entry[0] -= ($cmod * ($ifmod - 1));
            $ifmod-- if ($ifmod > 0);
          }
          elsif (defined $keywords{$name} &&
                 $keywords{$name} == $keywords{'if'}) {
            $entry[0] -= ($cmod * ($ifmod - 1));
          }
          elsif ($name eq 'foreach') {
            $formod++;
            $entry[2] -= ($cmod * ($formod - 1));
          }
          elsif ($name eq 'endfor') {
            $entry[2] -= ($cmod * ($formod - 1));
            $formod-- if ($formod > 0);
          }
          elsif (defined $keywords{$name} &&
                 $keywords{$name} == $keywords{'foreach'}) {
            $entry[2] -= ($cmod * ($formod - 1));
          }
          foreach my $entry (@entry) {
            $entry = 0 if ($entry < 0);
          }
          $color = '#' . sprintf("%02x%02x%02x", @entry);
        }

        push(@codes, [$color, $part]);
        $start = $eindex;
      }
      else {
        my($part) = substr($_, $start, $len - $start);
        push(@codes, [$deftxt, $part]);
        $start += ($len - $start);
      }
    }
  }
  close($fh);

  if (open($fh, ">$output")) {
    print $fh "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n",
              "<html><head><title>", basename($input), "</title></head>\n",
              "<body>\n";
    foreach my $code (@codes) {
      $$code[1] = convert_to_html($$code[1]);
      my($newline) = ($$code[1] =~ s/<br>//);
      print $fh ($$code[1] ne '' ?
                   "<font color=\"$$code[0]\">$$code[1]</font>" : ''),
                ($newline ? "<br>\n" : '');
    }
    print $fh "</body></html>\n";
  }
  else {
    print STDERR "ERROR: Unable to open $output for writing\n";
    ++$status;
  }
}
else {
  print STDERR "ERROR: Unable to open $input for reading\n";
  ++$status;
}

exit($status);

