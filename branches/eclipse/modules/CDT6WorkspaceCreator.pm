package CDT6WorkspaceCreator;

# ************************************************************
# Description   : Eclipse CDT 6 generator
# Author        : Chris Cleeland, Object Computing, Inc.
# Create Date   : 23-Apr-2010
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use CDT6ProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub requires_make_coexistence {
  #my $self = shift;
  return 1;
}

sub supports_make_coexistence {
  #my $self = shift;
  return 1;
}

sub workspace_file_name {
  #my $self = shift;
  return 'org.eclipse.core.resources.prefs';
}

sub pre_workspace {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  ## Optionally print the workspace comment
  $self->print_workspace_comment($fh,
            '#----------------------------------------------------------------------------', $crlf,
            '#       Eclipse CDT 6 generator', $crlf,
            '#', $crlf,
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,
#            '# This file should be placed in the .metadata\.plugins\org.eclipse.core.runtime\.settings directory', $crlf,
            '#', $crlf,
            '# MPC Command:', $crlf,
            "# $0 @ARGV", $crlf,
            '#----------------------------------------------------------------------------', $crlf);

  ## Unchanging initial settings
  print $fh 'version=1', $crlf,
            'eclipse.preferences.version=1', $crlf,
            'description.defaultbuildorder=false', $crlf;
}

sub write_comps {
  my($self, $fh) = @_;
  my $pjs  = $self->get_project_info();
  my @list = $self->sort_dependencies($self->get_projects(), 0);

  ## Print out the target
  print $fh 'description.buildorder=';
  foreach my $project (@list) {
    print $fh "$$pjs{$project}->[0]/";
  }
  print $fh $self->crlf();
}

sub post_workspace {
  my($self, $fh, $creator) = @_;
  my $crlf = $self->crlf();

  ## Clear out the seen dependency hash for use within the
  ## add_dependencies method.
  $self->{'seen_deps'} = {};

  ## Print out the project dependencies
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh "$project$crlf";
    $self->add_dependencies($creator, $project);
  }
}

sub get_additional_output {
  ## Create the accompanying list file.  It always goes in the same
  ## directory as the first workspace output file.  See
  ## WorkspaceCreator.pm for a description of the array elements.
  return [[undef, 'wb26projects.lst', \&list_file_body]];
}

sub list_file_body {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  ## Optionally print the workspace comment
  $self->print_workspace_comment($fh,
            '#----------------------------------------------------------------------------', $crlf,
            '#       Eclipse CDT 6 generator', $crlf,
            '#', $crlf,
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,
            '# MPC Command:', $crlf,
            "# $0 @ARGV", $crlf,
            '#----------------------------------------------------------------------------', $crlf);

  ## Print out each target separately
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh Cwd::abs_path($self->mpc_dirname($project)), '/.project', $crlf;
  }
}

sub add_dependencies {
  my($self, $creator, $proj) = @_;
  my $outdir = $self->mpc_dirname($proj);

  ## These values will be changed after the first time through the for
  ## loop below.
  my $pre     = "\t\t" . '<project>';
  my $post    = '</project>';
  my $outfile = $outdir . '/.project';

  ## Go through twice to edit both the .project and .wrproject files
  for(my $i = 0; $i < 2; $i++) {
    my $fh = new FileHandle();
    if (open($fh, $outfile)) {
      ## Get the dependencies and store them based on the directory of
      ## the project file.  We will check them later.
      my $deps = $self->get_validated_ordering($proj);
      my $key = $self->mpc_basename($self->mpc_dirname($proj));
      $self->{'seen_deps'}->{$key} = {};
      foreach my $dep (@$deps) {
        $self->{'seen_deps'}->{$key}->{$dep} = 1;
      }

      my @read = ();
      my $cwd  = $self->getcwd();
      while(<$fh>) {
        ## This is a comment found in wb26.mpd and wb26wrproject.mpd if
        ## the project is an executable, contains the 'after' keyword
        ## setting, and the 'enable_subprojects' template variable.
        if (/MPC\s+ADD\s+DEPENDENCIES/) {
          my $crlf = $self->crlf();
          my %seen = ();
          my @lines;
          foreach my $dep (reverse @$deps) {
            ## If we've seen this dependency, we don't need to add it
            ## again.  The build tool will handle it correctly.
            if (!$seen{$dep}) {
              my $relative = $self->get_relative_dep_file($creator,
                                                          "$cwd/$proj", $dep);
              ## Since we're looking at the dependencies in reverse order
              ## now, we need to unshift them into another array to keep
              ## the correct order.
              unshift(@lines, "$pre$dep$post$crlf") if (defined $relative);

              ## We've now seen this dependency and all of the
              ## projects upon which this one depends.
              $seen{$dep} = 1;
              foreach my $key (keys %{$self->{'seen_deps'}->{$dep}}) {
                $seen{$key} = 1;
              }
            }
          }

          ## Add the dependency lines to the project file
          push(@read, @lines);
        }
        else {
          push(@read, $_);
        }
      }
      close($fh);

      ## We will always rewrite the project file (with or without
      ## dependencies).
      if (open($fh, ">$outfile")) {
        foreach my $line (@read) {
          print $fh $line;
        }
        close($fh);
      }
    }

    ## The dependencies need to go into the .wrproject too, so transform
    ## the name and the pre and post values.
    $outfile = $outdir . '/.wrproject';
    $pre = '        <subproject project="/';
    $post = '"/>';
  }
}


1;
