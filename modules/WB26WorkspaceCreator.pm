package WB26WorkspaceCreator;

# ************************************************************
# Description   : Workbench 2.6 / VxWorks 6.4 generator
# Author        : Johnny Willemsen
# Create Date   : 07/01/2008
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use WB26ProjectCreator;
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
  return '.bdsgroup';
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '﻿<?xml version="1.0" encoding="utf-8"?>', $crlf;
  $self->print_workspace_comment($fh,
            '<!-- $Id$ -->', $crlf,
            '<!-- MPC Command -->', $crlf,
            '<!-- ', $self->create_command_line_string($0, @ARGV), ' -->',
            $crlf);
}


sub write_comps {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '<BorlandProject>', $crlf;
  print $fh '  <PersonalityInfo>', $crlf;
  print $fh '    <Option>', $crlf;
  print $fh '      <Option Name="Personality">Default.Personality</Option>', $crlf;
  print $fh '      <Option Name="ProjectType"></Option>', $crlf;
  print $fh '      <Option Name="Version">1.0</Option>', $crlf;
  print $fh '      <Option Name="GUID">{93D77FAD-C603-4FB1-95AB-34E0B6FBF615}</Option>', $crlf;
  print $fh '    </Option>', $crlf;
  print $fh '  </PersonalityInfo>', $crlf;
  print $fh '  <Default.Personality>', $crlf;
  print $fh '    ', $crlf;
  print $fh '    <Projects>', $crlf;

  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh '      <Projects Name="$project">$project</Projects>', $crlf,
  }

  print $fh '    </Projects>', $crlf;
  print $fh '    <Dependencies/>', $crlf;
  print $fh '  </Default.Personality>', $crlf;
  print $fh '</BorlandProject>', $crlf;
}


1;
