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
use FileHandle;
use File::Basename;

use WB26ProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_name {
  #my $self = shift;
  return 'org.eclipse.core.resources.prefs';
}

sub pre_workspace {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  $self->print_workspace_comment($fh,
            '#----------------------------------------------------------------------------', $crlf,
            '#       WindRiver Workbench generator', $crlf,
            '#', $crlf,
            '# $Id$', $crlf,
            '#', $crlf,
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,
            '# This file should be placed in the .metadata\.plugins\org.eclipse.core.runtime\.settings directory', $crlf,
            '#', $crlf,
            '# MPC Command:', $crlf,
            "# $0 @ARGV", $crlf,
            '#----------------------------------------------------------------------------', $crlf);
  print $fh 'version=1', $crlf,
            'eclipse.preferences.version=1', $crlf,
            'description.defaultbuildorder=false', $crlf;
}

sub write_comps {
  my($self, $fh) = @_;
  my $pjs  = $self->get_project_info();
  my @list = $self->sort_dependencies($self->get_projects(), 0);
  my $all  = 'description.buildorder=';

  ## Construct the target
  foreach my $project (@list) {
    $all .= "$$pjs{$project}->[0]/";
  }
  print $fh $all, $self->crlf();
}

sub get_additional_output {
  ## Create the accompanying list file.  It always goes in the same
  ## directory as the first workspace output file.
  return [[undef, 'wb26projects.lst', \&list_file_body]];
}

sub list_file_body {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  $self->print_workspace_comment($fh,
            '#----------------------------------------------------------------------------', $crlf,
            '#       WindRiver Workbench generator', $crlf,                                        
            '#', $crlf,                                    
            '# $Id$', $crlf,
            '#', $crlf,                                                                          
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,        
            '# MPC Command:', $crlf,                                         
            "# $0 @ARGV", $crlf,    
            '#----------------------------------------------------------------------------', $crlf);

  ## Print out each target separately
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh Cwd::abs_path($self->mpc_dirname($project)),
              '/.project', $crlf;
  }
}

1;