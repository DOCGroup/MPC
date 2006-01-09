package BDSWorkspaceCreator;

# ************************************************************
# Description   : A BDS Workspace Creator
# Author        : Johnny Willemsen
# Create Date   : 14/12/2005
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use BDSProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************


sub compare_output {
  #my($self) = shift;
  return 1;
}


sub workspace_file_name {
  my($self) = shift;
  return $self->get_modified_workspace_name($self->get_workspace_name(),
                                            '.bdsgroup');
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '﻿<?xml version="1.0" encoding="utf-8"?>', $crlf,
            '<!-- $Id$ -->', $crlf,
            '<!-- MPC Command -->', $crlf,
            "<!-- $0 @ARGV -->", $crlf;
}


sub write_comps {
  my($self)     = shift;
  my($fh)       = shift;
  my($projects) = $self->get_projects();
  my(@list)     = $self->sort_dependencies($projects);
  my($crlf)     = $self->crlf();

  print $fh '<BorlandProject>', $crlf;
  print $fh '  <PersonalityInfo>', $crlf;
  print $fh '    <Option>', $crlf;
  print $fh '      <Option Name="Personality">Default.Personality</Option>', $crlf;
  print $fh '      <Option Name="ProjectType"></Option>', $crlf;
  print $fh '      <Option Name="Version">1.0</Option>', $crlf;
  print $fh '      <Option Name="GUID">{93D77FAD-C603-4FB1-95AB-34E0B6FBF615}</Option>', $crlf;
  print $fh '    </Option>', $crlf;
  print $fh '  </PersonalityInfo>', $crlf;
  print $fh '<Default.Personality>', $crlf;
  print $fh '    ', $crlf;
  print $fh '    <Projects>', $crlf;

  foreach my $project (@list) {
    print $fh '      <Projects Name="$project">$project</Projects>', $crlf,
  }

  print $fh '    </Projects>', $crlf;
  print $fh '    <Dependencies/>', $crlf;
  print $fh '  </Default.Personality>', $crlf;
}


1;
