package NMakeWorkspaceCreator;

# ************************************************************
# Description   : A NMake Workspace (Makefile) creator
# Author        : Chad Elliott
# Create Date   : 6/10/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use NMakeProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************

my(@targets) = ('CLEAN', 'DEPEND', 'GENERATED', 'REALCLEAN',
                '$(CUSTOM_TARGETS)');

# ************************************************************
# Subroutine Section
# ************************************************************

sub supports_make_coexistence {
  #my($self) = shift;
  return 1;
}


sub crlf {
  my($self) = shift;
  return $self->windows_crlf();
}


sub workspace_per_project {
  #my($self) = shift;
  return 1;
}


sub workspace_file_name {
  my($self) = shift;
  if ($self->make_coexistence()) {
    return $self->get_modified_workspace_name($self->get_workspace_name(),
                                              '.nmake');
  }
  else {
    return $self->get_modified_workspace_name('Makefile', '');
  }
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '# Microsoft Developer Studio Generated NMAKE File', $crlf,
            '#', $crlf,
            '# $Id$', $crlf,
            '#', $crlf,
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,
            '#', $crlf,
            '# MPC Command:', $crlf,
            '# ', $self->create_command_line_string($0, @ARGV), $crlf, $crlf;
}


sub write_project_targets {
  my($self)     = shift;
  my($fh)       = shift;
  my($target)   = shift;
  my($list)     = shift;
  my($crlf)     = $self->crlf();
  my($cwd)      = $self->getcwd();

  foreach my $project (@$list) {
    my($dir)   = $self->mpc_dirname($project);
    my($chdir) = ($dir ne '.');

    print $fh ($chdir ? "\t\@cd $dir$crlf" : ''),
              "\t\$(MAKE) /f ", $self->mpc_basename($project),
              " $target$crlf",
              ($chdir ? "\t\@cd \$(MAKEDIR)$crlf" : '');
  }
}


sub write_comps {
  my($self)     = shift;
  my($fh)       = shift;
  my($projects) = $self->get_projects();
  my($pjs)      = $self->get_project_info();
  my($trans)    = $self->project_target_translation();
  my(%targnum)  = ();
  my(@list)     = $self->number_target_deps($projects, $pjs, \%targnum, 0);
  my($crlf)     = $self->crlf();
  my($default)  = 'Win32 Debug';

  ## Determine the default configuration
  foreach my $project (keys %$pjs) {
    my($name, $deps, $pguid, $lang, @cfgs) = @{$pjs->{$project}};
    @cfgs = sort @cfgs;
    if (defined $cfgs[0]) {
      $default = $cfgs[0];
      $default =~ s/(.*)\|(.*)/$2 $1/;
      last;
    }
  }

  ## Print out the content
  print $fh '!IF "$(CFG)" == ""', $crlf,
            'CFG=', $default, $crlf,
            '!MESSAGE No configuration specified. ',
            'Defaulting to ', $default, '.', $crlf,
            '!ENDIF', $crlf, $crlf,
            '!IF "$(CUSTOM_TARGETS)" == ""', $crlf,
            'CUSTOM_TARGETS=_EMPTY_TARGET_', $crlf,
            '!ENDIF', $crlf;

  ## Print out the "all" target
  print $fh $crlf, 'ALL:';
  foreach my $project (@list) {
    print $fh " $$trans{$project}";
  }
  print $fh $crlf;

  ## Print out all other targets here
  foreach my $target (@targets) {
    print $fh $crlf,
              $target, ':', $crlf;
    $self->write_project_targets($fh, 'CFG="$(CFG)" ' . $target, \@list);
  }

  ## Print out each target separately
  foreach my $project (@list) {
    print $fh $crlf, $$trans{$project}, ':';
    if (defined $targnum{$project}) {
      foreach my $number (@{$targnum{$project}}) {
        print $fh " $$trans{$list[$number]}";
      }
    }

    print $fh $crlf;
    $self->write_project_targets($fh, 'CFG="$(CFG)" ' . 'ALL', [ $project ]);
  }

  ## Print out the project_name_list target
  print $fh $crlf, "project_name_list:$crlf";
  foreach my $project (sort @list) {
    print $fh "\t\@echo $$trans{$project}$crlf";
  }
}



1;