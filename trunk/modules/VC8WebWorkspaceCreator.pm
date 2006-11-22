package VC8WebWorkspaceCreator;

# ************************************************************
# Description   : A VC8 Website Workspace Creator
# Author        : James H. Hill
# Create Date   : 6/7/2006
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC8WebProjectCreator;
use VC8WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(VC8WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub write_workspace {
  my($self)      = shift;
  my($creator)   = shift;
  my($addfile)   = shift;

  if ($addfile) {
    $self->add_webapps(['.']);
  }

  $self->SUPER::write_workspace($creator, $addfile);
}


1;
