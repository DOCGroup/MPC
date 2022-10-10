package CMakeWorkspaceCreator;

# ************************************************************
# Description   : A CMake Workspace creator
# Author        : Chad Elliott
# Create Date   : 10/10/2022
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Basename;

use CMakeProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub write_and_compare_file {
  my($self, $outdir, $oname, $func, @params) = @_;
  my $status = 1;
  my $errorString = '';

  ## Rename the first (and hopefully the only) project in the directory to what
  ## CMake expects.
  my %dirs;
  foreach my $entry (@{$self->get_projects()}) {
    my $dir = dirname($entry);
    if (!exists $dirs{$dir}) {
      ## Keep track of the project existing in this directory
      $dirs{$dir} = 1;

      ## Rename the project file to CMakeLists.txt and if it fails, we need to
      ## propagate that back to the caller.
      if (rename($entry, "$dir/CMakeLists.txt") == 0) {
        $status = 0;
        $errorString = "Unable to rename $entry";
        last;
      }
    }
    else {
      $self->warning("Multiple projects in the same workspace are not supported");
    }
  }

  return $status, $errorString;
}

1;
