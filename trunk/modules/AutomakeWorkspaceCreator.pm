package AutomakeWorkspaceCreator;

# ************************************************************
# Description   : A Automake Workspace (Makefile) creator
# Author        : Chad Elliott
# Create Date   : 5/13/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Basename;

use AutomakeProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_name {
  my($self) = shift;
  return $self->get_modified_workspace_name('Makefile', '.am');
}


sub workspace_per_project {
  #my($self) = shift;
  return 1;
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '##  Process this file with automake to create Makefile.in', $crlf,
            '##', $crlf,
            '## $Id$', $crlf,
            '##', $crlf,
            '## This file was generated by MPC.  Any changes made directly to', $crlf,
            '## this file will be lost the next time it is generated.', $crlf,
            '##', $crlf,
            '## MPC Command:', $crlf,
            "## $0 @ARGV", $crlf, $crlf,
            'bin_PROGRAMS =', $crlf,
            'noinst_PROGRAMS =', $crlf,
            'noinst_HEADERS =', $crlf,
            'lib_LTLIBRARIES =', $crlf,
            'BUILT_SOURCES =', $crlf,
            'CLEANFILES =', $crlf,
            'TEMPLATE_FILES =', $crlf,
            'HEADER_FILES =', $crlf,
            'INLINE_FILES =', $crlf, $crlf;
}


sub write_comps {
  my($self)          = shift;
  my($fh)            = shift;
  my($creator)       = shift;
  my($toplevel)      = shift;
  my($projects)      = $self->get_projects();
  my(@list)          = $self->sort_dependencies($projects);
  my($crlf)          = $self->crlf();
  my(%unique)        = ();
  my(@dirs)          = ();
  my(@locals)        = ();
  my(%proj_dir_seen) = ();

  ## This step writes a configure.ac.Makefiles list into the starting
  ## directory. The list contains of all the Makefiles generated down
  ## the tree. configure.ac can include this to get an up-to-date list
  ## of all the involved Makefiles.
  my($mfh);
  if ($toplevel) {
    unlink('configure.ac.Makefiles');
    $mfh = new FileHandle();
    open($mfh, '>configure.ac.Makefiles');
    ## The top-level is never listed as a dependency, so it needs to be
    ## added explicitly.
    print $mfh "AC_CONFIG_FILES([ Makefile ])$crlf";
  }

  ## If we're writing a configure.ac.Makefiles file, every seen project
  ## goes into it. Since we only write this at the starting directory
  ## level, it'll include all projects processed at this level and below.
  foreach my $dep (reverse @list) {
    if ($mfh) {
      ## There should be a Makefile at each level, but it's not a project,
      ## it's a workspace; therefore, it's not in the list of projects.
      ## Since we're consolidating all the project files into one workspace
      ## Makefile.am per directory level, be sure to add that Makefile.am
      ## entry at each level there's a project dependency.
      my($dep_dir) = dirname($dep);
      if (!defined $proj_dir_seen{$dep_dir}) {
        $proj_dir_seen{$dep_dir} = 1;
        print $mfh "AC_CONFIG_FILES([ $dep_dir" . "/Makefile ])$crlf";
      }
    }

    ## Get a unique list of next-level directories for SUBDIRS.
    my($dir) = $self->get_first_level_directory($dep);
    if (!defined $unique{$dir}) {
      $unique{$dir} = 1;
      unshift(@dirs, $dir);
    }

    ## At each directory level, each project is written into a separate
    ## Makefile.<project>.am file. To bring these back into the build
    ## process, they'll be sucked back into the workspace Makefile.am file.
    ## Remember which ones to pull in at this level.
    if ($dir eq '.') {
      unshift(@locals, $dep);
    }
  }
  if ($mfh) {
    close($mfh);
  }

  ## Print out the subdirectories
  print $fh 'SUBDIRS =';
  foreach my $dir (@dirs) {
    print $fh " \\$crlf        $dir";
  }
  print $fh $crlf, $crlf;

  ## Take the local Makefile.<project>.am files and insert each one here,
  ## then delete it.
  if (@locals) {
    foreach my $local (@locals) {
      my($pfh);
      $pfh = new FileHandle();
      open($pfh,$local) || print "Error opening $local" . $crlf;
      print $fh "## $local $crlf";
      while (<$pfh>) {
        print $fh $_;
      }
      close($pfh);
##      unlink($local);
      print $fh $crlf;
    }
  }

  ## If this is the top-level Makefile.am, it needs the directives to pass
  ## autoconf/automake flags down the tree when running autoconf.
  ## *** This may be too closely tied to how we have things set up in ACE,
  ## even though it's recommended practice. ***
  if ($self->getstartdir() eq $self->getcwd()) {
    print $fh $crlf;
    print $fh 'ACLOCAL = @ACLOCAL@' . $crlf;
    print $fh 'ACLOCAL_AMFLAGS = -I m4' . $crlf;
  }

  ## Finish up with the cleanup specs.
  print $fh $crlf;
  print $fh 'pkginclude_HEADERS = $(TEMPLATE_FILES)',
            ' $(INLINE_FILES) $(HEADER_FILES)', $crlf;
  print $fh $crlf;
  print $fh '## Clean up template repositories, etc.' . $crlf;
  print $fh 'clean-local:' . $crlf;
  print $fh "\t-rm -f *.bak *.rpo *.sym lib*.*_pure_* Makefile.old core" . $crlf;
  print $fh "\t-rm -f gcctemp.c gcctemp so_locations" . $crlf;
  print $fh "\t-rm -rf ptrepository SunWS_cache Templates.DB" . $crlf;
}


1;
