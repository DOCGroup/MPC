package BCB2007WorkspaceCreator;

# ************************************************************
# Description   : A BDS 4 Workspace Creator
# Author        : Johnny Willemsen
# Create Date   : 14/12/2005
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use BCB2007ProjectCreator;
use WinWorkspaceBase;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WinWorkspaceBase WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  #my($self) = shift;
  return "\n";
}


sub compare_output {
  #my($self) = shift;
  return 1;
}


sub workspace_file_extension {
  #my($self) = shift;
  return '.groupproj';
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '﻿<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">', $crlf;
#  $self->print_workspace_comment($fh,
#            '<!-- $Id$ -->', $crlf,
#            '<!-- MPC Command -->', $crlf,
#            '<!-- ', $self->create_command_line_string($0, @ARGV), ' -->',
#            $crlf);
}


sub write_comps {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();
  my($project_info) = $self->get_project_info();

  print $fh '  <PropertyGroup>', $crlf;
  print $fh '    <ProjectGuid>{1946f85e-487f-46b6-8e41-159cd446db35}</ProjectGuid>', $crlf;
  print $fh '  </PropertyGroup>', $crlf;
  print $fh '  <ItemGroup />', $crlf;
  print $fh '  <ItemGroup />', $crlf;
  print $fh '  <ProjectExtensions>', $crlf;
  print $fh '    <Borland.Personality>Default.Personality</Borland.Personality>', $crlf;
  print $fh '    <Borland.ProjectType />', $crlf;
  print $fh '    <BorlandProject>', $crlf;
  print $fh '  <BorlandProject xmlns=""> <Default.Personality> </Default.Personality> </BorlandProject></BorlandProject>', $crlf;
  print $fh '  </ProjectExtensions>', $crlf;

  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    my($name) = $$project_info{$project}->[0];
    print $fh '  <Target Name="', $name, '">', $crlf;
    print $fh '    <MSBuild Projects="', $self->mpc_basename($project), '" Targets="" />', $crlf;
    print $fh '  </Target>', $crlf;
    print $fh '  <Target Name="', $name, ':Make">', $crlf;
    print $fh '    <MSBuild Projects="', $self->mpc_basename($project), '" Targets="Make" />', $crlf;
    print $fh '  </Target>', $crlf;
    print $fh '  <Target Name="', $name, ':Clean">', $crlf;
    print $fh '    <MSBuild Projects="', $self->mpc_basename($project), '" Targets="Clean" />', $crlf;
    print $fh '  </Target>', $crlf;
  }

  print $fh '  <Target Name="Build">', $crlf;
  print $fh '    <CallTarget Targets="';
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    my($name) = $$project_info{$project}->[0];
    print $fh $name, ';';
  }
  print $fh '" />', $crlf;
  print $fh '  </Target>', $crlf;

  print $fh '  <Target Name="Make">', $crlf;
  print $fh '    <CallTarget Targets="';
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    my($name) = $$project_info{$project}->[0];
    print $fh $name, ':Make;';
  }
  print $fh '" />', $crlf;
  print $fh '  </Target>', $crlf;

  print $fh '  <Target Name="Clean">', $crlf;
  print $fh '    <CallTarget Targets="';
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    my($name) = $$project_info{$project}->[0];
    print $fh $name, ':Clean;';
  }
  print $fh '" />', $crlf;

  print $fh '  </Target>', $crlf;

  print $fh '</Project>', $crlf;
}


1;
