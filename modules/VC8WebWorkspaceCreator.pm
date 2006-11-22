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
    my($projects)     = $self->get_projects();
    my($project_info) = $self->get_project_info();

    # Add the website to the list of project names
    my($pname) = '.';
    push(@$projects, $pname);

    # Generate the GUID for the website.  We have to explicitly
    # create a new project using . as the 'project_name'.
    my($guid) = GUID::generate($self->workspace_file_name(),
                               $pname,
                               $self->getcwd());

    # Add the website project to the 'project_info'.
    @{$project_info->{$pname}} = ($pname,
                                  '',
                                  $guid,
                                  'website');
    foreach my $cpu ('.NET', 'Any CPU') {    
      foreach my $configuration ('Debug', 'Release') {
        push(@{$project_info->{$pname}}, "$configuration|$cpu");
      }
    }
  }

  $self->SUPER::write_workspace($creator, $addfile);
}


1;
