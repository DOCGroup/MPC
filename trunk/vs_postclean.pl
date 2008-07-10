eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 7/10/2008
# Description: Visual Studio doesn't support a post clean build step,
#              so this script will do it.
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

my $version = '1.0';

# ******************************************************************
# Subroutine Section
# ******************************************************************

sub read_proj {
  my($cfg, $file) = @_;
  my $fh = new FileHandle();
  my $cmd;

  if (open($fh, $file)) {
    my $cfg_ok;
    my $next_name;
    my $next_command;
    while(<$fh>) {
      ## Locate the start of a Configuration section
      if (/<Configuration\s*$/) {
        $next_name = 1;
      }
      ## Next, find the configuration name
      elsif ($next_name && /Name="(.+)"/) {
        $cfg_ok = ($1 eq $cfg);
        $next_name = undef;
      }
      ## Next, find the post clean event
      elsif ($cfg_ok && /Name="VCPostCleanEventTool"/) {
        $next_command = 1;
      }
      ## And finally, get the postclean command line
      elsif ($next_command && /CommandLine="(.+)"/) {
        $cmd = $1;
        last;
      }
    }
    close($fh);
  }

  ## Return the command line (undef if there was no postclean)
  return $cmd;
}

sub clean_proj {
  my($cfg, $file) = @_;

  ## Read the postclean command from the project
  my $cmd = read_proj($cfg, $file);

  ## Move to the directory of the project and run the command
  if (defined $cmd) {
    if (chdir(dirname($file))) {
      system($cmd);
    }
    else {
      print "WARNING: Unable to postclean $file\n";
    }
  }
}

# ******************************************************************
# Main Section
# ******************************************************************

if ($#ARGV == -1) {
  print "PostClean v$version\n",
        "Usage: ", basename($0), " [CFG=<configuration>] <project files>\n";
  exit(0);
}

my $cfg = 'Debug|Win32';
if ($ARGV[0] =~ /^CFG=(.+)/) {
  $cfg = $1;
  shift(@ARGV);
}

foreach my $file (@ARGV) {
  clean_proj($cfg, $file);
}
