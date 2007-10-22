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
# Data Section
# ************************************************************

my($acfile) = 'configure.ac.Makefiles';

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
            "## $0 @ARGV", $crlf, $crlf;
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
    unlink($acfile);
    $mfh = new FileHandle();
    open($mfh, ">$acfile");
    ## The top-level is never listed as a dependency, so it needs to be
    ## added explicitly.
    print $mfh "AC_CONFIG_FILES([ Makefile ])$crlf";
  }

  ## If we're writing a configure.ac.Makefiles file, every seen project
  ## goes into it. Since we only write this at the starting directory
  ## level, it'll include all projects processed at this level and below.
  foreach my $dep (@list) {
    if ($mfh) {
      ## There should be a Makefile at each level, but it's not a project,
      ## it's a workspace; therefore, it's not in the list of projects.
      ## Since we're consolidating all the project files into one workspace
      ## Makefile.am per directory level, be sure to add that Makefile.am
      ## entry at each level there's a project dependency.
      my($dep_dir) = dirname($dep);
      if (!defined $proj_dir_seen{$dep_dir}) {
        $proj_dir_seen{$dep_dir} = 1;
        ## If there are directory levels between project-containing
        ## directories (for example, at this time in
        ## ACE_wrappers/apps/JAWS/server, there are no projects at the
        ## apps or apps/JAWS level) we need to insert the Makefile
        ## entries for the levels without projects. They won't be listed
        ## in @list but are needed for make to traverse intervening directory
        ## levels down to where the project(s) to build are.
        my(@dirs) = split /\//, $dep_dir;
        my $inter_dir = "";
        foreach my $dep (@dirs) {
          $inter_dir = "$inter_dir$dep";
          if (!defined $proj_dir_seen{$inter_dir}) {
            $proj_dir_seen{$inter_dir} = 1;
            print $mfh "AC_CONFIG_FILES([ $inter_dir" . "/Makefile ])$crlf";
          }
          $inter_dir = "$inter_dir/";
        }
        print $mfh "AC_CONFIG_FILES([ $dep_dir" . "/Makefile ])$crlf";
      }
    }

    ## Get a unique list of next-level directories for SUBDIRS.
    my($dir) = $self->get_first_level_directory($dep);
    if ($dir ne '.') {
      if (!defined $unique{$dir}) {
        $unique{$dir} = 1;
        unshift(@dirs, $dir);
      }
    }
    else {
      ## At each directory level, each project is written into a separate
      ## Makefile.<project>.am file. To bring these back into the build
      ## process, they'll be sucked back into the workspace Makefile.am file.
      ## Remember which ones to pull in at this level.
      unshift(@locals, $dep);
    }
  }
  if ($mfh) {
    close($mfh);
  }

  ## Print out the Makefile.am.  If there are local projects, insert
  ## "." as the first SUBDIR entry.
  if (@dirs) {
    print $fh 'SUBDIRS =';
    if (@locals) {
      print $fh " \\$crlf        .";
    }
    foreach my $dir (reverse @dirs) {
      print $fh " \\$crlf        $dir";
    }
    print $fh $crlf, $crlf;
  }

  # The Makefile.<project>.am files always append values to macros,
  # but automake will fails if the first isn't a plain assignment.  To
  # address this we parse the Makefile.<project>.am files as we insert
  # them, changinng the first instance of += to = for each macro.
  #
  # We should consider extending this to support all macros that match
  # automake's uniform naming convention.  A true perl wizard probably
  # would be able to do this in a single line of code.

  my($seen_bin_programs) = 0;
  my($seen_noinst_programs) = 0;
  my($seen_lib_libraries) = 0;
  my($seen_noinst_libraries) = 0;
  my($seen_lib_ltlibraries) = 0;
  my($seen_noinst_ltlibraries) = 0;
  my($seen_noinst_headers) = 0;
  my($seen_built_sources) = 0;
  my($seen_cleanfiles) = 0;
  my($seen_template_files) = 0;
  my($seen_header_files) = 0;
  my($seen_inline_files) = 0;

  ## Take the local Makefile.<project>.am files and insert each one here,
  ## then delete it.
  if (@locals) {
    foreach my $local (@locals) {
      my($pfh) = new FileHandle();
      if (open($pfh,$local)) {
        print $fh "## $local $crlf";

        while (<$pfh>) {
          # Don't emit comments
          next if (/^#/);

          if (/^bin_PROGRAMS\s*\+=\s*/) {
            if (! $seen_bin_programs) {
              s/\+=/=/;
              $seen_bin_programs = 1;
            }
          } elsif (/^noinst_PROGRAMS\s*\+=\s*/) {
            if (! $seen_noinst_programs) {
              s/\+=/=/;
              $seen_noinst_programs = 1;
            }
          } elsif (/^lib_LIBRARIES\s*\+=\s*/) {
            if (! $seen_lib_libraries ) {
              s/\+=/=/;
              $seen_lib_libraries = 1;
            }
          } elsif (/^noinst_LIBRARIES\s*\+=\s*/) {
            if (! $seen_noinst_libraries ) {
              s/\+=/=/;
              $seen_noinst_libraries = 1;
            }
          } elsif (/^lib_LTLIBRARIES\s*\+=\s*/) {
            if (! $seen_lib_ltlibraries ) {
              s/\+=/=/;
              $seen_lib_ltlibraries = 1;
            }
          } elsif (/^noinst_LTLIBRARIES\s*\+=\s*/) {
            if (! $seen_noinst_ltlibraries ) {
              s/\+=/=/;
              $seen_noinst_ltlibraries = 1;
            }
          } elsif (/^noinst_HEADERS\s*\+=\s*/) {
            if (! $seen_noinst_headers) {
              s/\+=/=/;
              $seen_noinst_headers = 1;
            }
          } elsif (/^BUILT_SOURCES\s*\+=\s*/) {
            if (! $seen_built_sources) {
              s/\+=/=/;
              $seen_built_sources = 1;
            }
          } elsif (/^CLEANFILES\s*\+=\s*/) {
            if (! $seen_cleanfiles) {
              s/\+=/=/;
              $seen_cleanfiles = 1;
            }
          } elsif (/^TEMPLATE_FILES\s*\+=\s*/) {
            if (! $seen_template_files) {
              s/\+=/=/;
              $seen_template_files = 1;
            }
          } elsif (/^HEADER_FILES\s*\+=\s*/) {
            if (! $seen_header_files) {
              s/\+=/=/;
              $seen_header_files = 1;
            }
          } elsif (/^INLINE_FILES\s*\+=\s*/) {
            if (! $seen_inline_files) {
              s/\+=/=/;
              $seen_inline_files = 1;
            }
          }

          print $fh $_;
        }

        close($pfh);
##        unlink($local);
        print $fh $crlf;
      }
      else {
        $self->error("Unable to open $local for reading.");
      }
    }
  }

  ## If this is the top-level Makefile.am, it needs the directives to pass
  ## autoconf/automake flags down the tree when running autoconf.
  ## *** This may be too closely tied to how we have things set up in ACE,
  ## even though it's recommended practice. ***
  if ($toplevel) {
    print $fh $crlf,
              'ACLOCAL = @ACLOCAL@', $crlf,
              'ACLOCAL_AMFLAGS = -I m4', $crlf,
              $crlf;
  }

  ## Insert pkginclude_HEADERS if we saw TEMPLATE_FILES, HEADER_FILES,
  ## or INLINE_FILES in the Makefile.<project>.am files.
  if ($seen_template_files || $seen_inline_files || $seen_header_files) {
    print $fh 'pkginclude_HEADERS =';
    print $fh ' $(TEMPLATE_FILES)' if ($seen_template_files);
    print $fh ' $(INLINE_FILES)' if ($seen_inline_files);
    print $fh ' $(HEADER_FILES)' if ($seen_header_files);
    print $fh $crlf,
              $crlf;
  }

  ## Finish up with the cleanup specs.
  print $fh '## Clean up template repositories, etc.', $crlf,
            'clean-local:', $crlf,
            "\t-rm -f *.bak *.rpo *.sym lib*.*_pure_* Makefile.old core",
            $crlf,
            "\t-rm -f gcctemp.c gcctemp so_locations", $crlf,
            "\t-rm -rf ptrepository SunWS_cache Templates.DB", $crlf;
}


1;