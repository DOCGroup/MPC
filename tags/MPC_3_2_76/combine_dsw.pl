eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 4/8/2004
#         $Id$
# Description: Combined multiple dsw's into a single dsw
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

my($version) = '$Id$';
$version =~ s/.*\s+(\d+[\.\d]+)\s+.*/$1/;

# ******************************************************************
# Subroutine Section
# ******************************************************************

sub usageAndExit {
  my($str) = shift;
  if (defined $str) {
    print STDERR "$str\n";
  }
  print STDERR "Combine DSW v$version\n",
               "Usage: ", basename($0),
               " [-u] <output file> <input files...>\n\n",
               "-u  Each input file will be removed after successful ",
               "combination\n\n",
               "Combined multiple dsw's into a single dsw.  You can use ",
               "MPC to generate\n",
               "dynamic projects and then generate static projects using ",
               "the -static,\n",
               "-name_modifier and -apply_project options together.  You ",
               "can then run this\n",
               "script to combine the workspaces into one.\n";
  exit(0);
}

# ******************************************************************
# Main Section
# ******************************************************************

my($output) = undef;
my($unlink) = undef;
my(@input)  = ();

for(my $i = 0; $i <= $#ARGV; $i++) {
  my($arg) = $ARGV[$i];
  if ($arg =~ /^-/) {
    if ($arg eq "-u") {
      $unlink = 1;
    }
    else {
      usageAndExit("Unknown option: $arg");
    }
  }
  else {
    if (!defined $output) {
      $output = $arg;
    }
    else {
      push(@input, $arg);
    }
  }
}

if (!defined $output || !defined $input[0]) {
  usageAndExit();
}

my($tmp) = "$output.tmp";
my($oh)  = new FileHandle();

if (open($oh, ">$tmp")) {
  my($msident) = 0;
  for(my $i = 0; $i <= $#input; ++$i) {
    my($input)  = $input[$i];
    my($fh)     = new FileHandle();
    my($global) = ($i == $#input);

    if (open($fh, $input)) {
      my($in_global) = 0;
      while(<$fh>) {
        if (/Microsoft\s+Developer\s+Studio/) {
          if ($msident == 0) {
            $msident = 1;
            print $oh $_;
          }
        }
        else {
          if (/^Global:/) {
            $in_global = 1;
          }
          elsif ($in_global && /^[#]{79,}/) {
            $in_global = 0;
            $_ = '';
          }
          if (!$in_global || ($global && $in_global)) {
            print $oh $_;
          }
        }
      }
      close($fh);
    }
    else {
      print STDERR "ERROR: Unable to open '$input' for reading\n";
      exit(2);
    }
  }
  close($oh);

  if ($unlink) {
    foreach my $input (@input) {
      unlink($input);
    }
  }

  unlink($output);
  rename($tmp, $output);
}
else {
  print STDERR "ERROR: Unable to open '$tmp' for writing\n";
  exit(1);
}
