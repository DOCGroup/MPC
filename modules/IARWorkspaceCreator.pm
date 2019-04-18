package IARWorkspaceCreator;

# ************************************************************
# Description   : The IAR Embedded Workbench IDE Workspace Creator
# Author        : Chad Elliott
# Create Date   : 4/18/2019
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use IARProjectCreator;
use WinWorkspaceBase;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WinWorkspaceBase WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************


sub compare_output {
  #my $self = shift;
  return 1;
}


sub workspace_file_extension {
  #my $self = shift;
  return '.eww';
}


sub pre_workspace {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>$crlf",
            "<workspace>$crlf";
}


sub write_comps {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  print $fh '  <!-- ', $self->get_workspace_name(), ' - ',
            $self->create_command_line_string($0, @ARGV),
            ' -->', $crlf;
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh "  <project>$crlf",
              "    <path>\$WS_DIR\$\\", $self->slash_to_backslash($project),
              "</path>$crlf",
              "  </project>$crlf";
  }
}


sub post_workspace {
  my($self, $fh) = @_;
  print $fh '</workspace>' . $self->crlf();
}


1;
