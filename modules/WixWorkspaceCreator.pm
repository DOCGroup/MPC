package WixWorkspaceCreator;

# ************************************************************
# Description   : A Wix Workspace creator
# Author        : James H. Hill
# Create Date   : 6/23/2009
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use WixProjectCreator;
use WorkspaceCreator;
use WinWorkspaceBase;
use File::Basename;

use vars qw(@ISA);
@ISA = qw(WinWorkspaceBase WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************


# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_extension {
  return '.wxs';
}

sub workspace_file_name {
  my $self = shift;
  return $self->get_modified_workspace_name($self->get_workspace_name(),
                                            '.wxi');
}

sub pre_workspace {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();
  my $name = $self->get_workspace_name();

  ## Begin the project definition for the workspace
  print $fh '<?xml version="1.0" encoding="utf-8" standalone="yes"?>', $crlf,
            '<Include>', $crlf;
}

sub write_comps {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();


  # print the target for clean
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh "  <?include $project ?>", $crlf;
  }
}


sub normalize {
  my $val = shift;
  $val =~ tr/ \t\/\\\-$()./_/;
  return $val;
}

sub post_workspace {
  my($self, $fh) = @_;
  my $info = $self->get_project_info();
  my $crlf = $self->crlf();

  # Create a component group consisting of all the projects.
  print $fh $crlf,
            '  <Fragment>', $crlf,
            '    <ComponentGroup Id="',
            $self->get_workspace_name(), '">', $crlf;

  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh '      <ComponentGroupRef Id="ComponentGroup.',
              $$info{$project}->[0], '" />', $crlf;
  }

  print $fh '    </ComponentGroup>', $crlf,
            '  </Fragment>', $crlf;



  print $fh $crlf;

  # For every project marked with "make_group", create a ComponentGroup that references all dependencies
  my %project_dependencies = ();
  my $projects = $self->get_projects();
  my @list = $self->sort_dependencies($projects, 0);
  foreach my $project (@list) {
	my $deps = $self->get_validated_ordering($project);
	$project_dependencies{$project} = [ @$deps ];
  }

  # for each project, find all dependencies
  foreach my $project (keys %project_dependencies) {
  	# foreach my $cfg (@cfgs_main) -> <configuration|platform> could be <Debug|AnyCPU Release|AnyCPU> or <Debug|Win32 Release|Win32 Debug|x64 Release|x64>
    #my($pname_main, $rawdeps_main, $guid_main, $language_main, $custom_only_main, $nocross_main, $managed_main, $make_group_main, @cfgs_main) = @{$$info{$project}};
    my($pname_main, $rawdeps_main, $guid_main, $language_main, $custom_only_main, $nocross_main, $managed_main, @cfgs_main) = @{$$info{$project}};
    
    my $make_group_main = 1;  # for now
    
    # only generate a group if "make_group = 1"
    if ($make_group_main) {
	  my %all_deps = ();  # all dependencies used by any project referenced by $project
      my @dep_stack = ($project);
      while (my $top = pop @dep_stack) {
        # add current project to dependencies (use hash key as set)
        $all_deps{$top} = 1;
        my $deps = $project_dependencies{$top};
        foreach my $dep (@$deps) {
          # add current project's dependencies to stack for processing, if not already processed
          push(@dep_stack, $dep) if !exists $all_deps{$dep};
        }
      }

      # for every config/platform pairing, emit a MainGroup
      foreach my $cfg (@cfgs_main) {
        my ($config, $platform) = split('\|', $cfg);

        print $fh '  <Fragment>'.$crlf;
        print $fh '    <ComponentGroup Id="MainGroup.'.normalize($config).'_'.normalize($platform).'_'.$pname_main.'">'.$crlf;

        # add main project - pattern is "ComponentGroup.<Debug|Release>_<Win32|x64|AnyCPU>_<projectname>"
        print $fh '      <ComponentGroupRef Id="ComponentGroup.'.normalize($config).'_'.normalize($platform).'_'.$pname_main.'" />'.$crlf;

        # loop over each dependency, and obtain its parameters
        foreach my $dep (keys %all_deps) {
          foreach my $p (@{$self->{'projects'}}) {
            if ($dep eq $self->{'project_info'}->{$p}->[0] || $dep eq $self->mpc_basename($p)) {
              my($pname_dep, $rawdeps_dep, $guid_dep, $language_dep, $custom_only_dep, $nocross_dep, $managed_dep, $make_group_main, @cfgs_dep) = @{$$info{$p}};

              # add dependency - include AnyCPU if no dependency configuration matches exactly (if the AnyCPU platform exists, that is)
              my $pform = $platform;
              if (!exists {map { $_ => 1 } @cfgs_dep}->{$config.'|'.$pform}) {
                $pform = 'AnyCPU';
              }
              if (exists {map { $_ => 1 } @cfgs_dep}->{$config.'|'.$pform}) {
                print $fh '      <ComponentGroupRef Id="ComponentGroup.'.normalize($config).'_'.normalize($pform).'_'.$pname_dep.'" />'.$crlf;
              }

              last;
            }
          }
        }

        print $fh '    </ComponentGroup>'.$crlf;
        print $fh '  </Fragment>'.$crlf;
        print $fh $crlf;
      }

    }
  }


  print $fh '</Include>'.$crlf;
}

1;
