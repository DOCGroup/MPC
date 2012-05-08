package VC11WorkspaceCreator;

# ************************************************************
# Description   : A VC11 Workspace Creator
# Author        : Johnny Willemsen
# Create Date   : 12/12/2011
# $Id$
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC11ProjectCreator;
use VC10WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(VC10WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub pre_workspace {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  print $fh '﻿', $crlf,
            'Microsoft Visual Studio Solution File, Format Version 11.00', $crlf;
  $self->print_workspace_comment($fh,
            '# Visual Studio 2011', $crlf,
            '# $Id$', $crlf,
            '#', $crlf,
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,
            '#', $crlf,
            '# MPC Command:', $crlf,
            '# ', $self->create_command_line_string($0, @ARGV), $crlf);
}


1;
