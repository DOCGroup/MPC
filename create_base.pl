eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 9/13/2007
#         $Id$
# Description: Generate a base project based on a library project
# ******************************************************************

# ******************************************************************
# Pragma Section
# ******************************************************************

use strict;
use FindBin;
use FileHandle;
use File::Spec;
use File::Basename;

my($basePath) = $FindBin::Bin;
if ($^O eq 'VMS') {
  $basePath = File::Spec->rel2abs(dirname($0)) if ($basePath eq '');
    $basePath = VMS::Filespec::unixify($basePath);
}
unshift(@INC, $basePath . '/modules');

require Creator;

# ******************************************************************
# Data Section
# ******************************************************************

my($version) = '0.1';

# ******************************************************************
# Subroutine Section
# ******************************************************************

sub gather_info {
  my $name = shift;
  my $fh   = new FileHandle();

  if (open($fh, $name)) {
    my @lines = ();
    my $pname = undef;
    while(<$fh>) {
      my $line = $_;
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;

      if ($line =~ /^project\s*(\(([^\)]+)\))?\s*(:.+)?\s*{$/) {
        $pname = $2;
        my $parents = $3 || '';
        my $def = basename($name);
        $def =~ s/\.[^\.]+$//;
        $def =~ s/\\/_/g;
        $def =~ s/[\s\-]/_/g;
        if (!defined $pname || $pname eq '') {
          $pname = $def;
        }
        else {
          $pname =~ s/\\/_/g;
          $pname =~ s/[\s\-]/_/g;
        }
        $pname = Creator::fill_type_name(undef, $pname, $def);
        push(@lines, "project$parents {");
      }
      elsif ($line =~ /^(shared|static)name\s*=\s*(.+)$/) {
        my $lib = $2;
        if (defined $pname && $lib ne '') {
          push(@lines, "  libs  += $2",
                       "  after += $pname",
                       "}");
        }
        last;
      }
    }
    close($fh);

    return @lines if ($#lines > 0);
  }

  return ();
}

sub write_base {
  my($in, $out) = @_;
  my @lines = gather_info($in);

  if ($#lines >= 0) {
    my $fh = new FileHandle();
    if (-r $out) {
      print STDERR "ERROR: $out already exists\n";
    }
    else {
      if (open($fh, ">$out")) {
        foreach my $line (@lines) {
          print $fh "$line\n";
        }
        close($fh);
        return 0;
      }
      else {
        print STDERR "ERROR: Unable to write to $out\n";
      }
    }
  }
  else {
    if (-r $in) {
      print STDERR "ERROR: $in is not a valid MPC file\n";
    }
    else {
      print STDERR "ERROR: Unable to read from $in\n";
    }
  }

  return 1;
}

sub usageAndExit {
  my $str = shift;
  if (defined $str) {
    print STDERR "$str\n";
  }
  print STDERR "Create Base Project v$version\n",
               "Usage: ", basename($0), " <mpc files> <output file or ",
               "directory>\n";
  exit(0);
}

# ******************************************************************
# Main Section
# ******************************************************************

if ($#ARGV > 1) {
  my $dir = pop(@ARGV);
  if (!-d $dir) {
    usageAndExit("Creating multiple base projects, but the " .
                 "last argument, $dir, is not a directory");
  }
  my $status = 0;
  foreach my $input (@ARGV) {
    my $output = $dir . '/' . lc(basename($input));
    $output =~ s/mpc$/mpb/;
    $status += write_base($input, $output);
  }
  exit($status);
}
else {
  my $input  = shift;
  my $output = shift;

  if (!defined $input) {
    usageAndExit();
  }
  elsif (index($input, '-') == 0) {
    usageAndExit();
  }

  if (!defined $output) {
    usageAndExit();
  }
  elsif (-d $output) {
    $output .= '/' . lc(basename($input));
    $output =~ s/mpc$/mpb/;
  }

  exit(write_base($input, $output));
}