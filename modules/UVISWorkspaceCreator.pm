package UVISWorkspaceCreator;

# ************************************************************
# Description   : The Keil uVision Workspace Creator
# Author        : Chad Elliott
# Create Date   : 11/1/2016
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use UVISProjectCreator;
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
  return '.uvmpw';
}


sub pre_workspace {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>$crlf",
            "<ProjectWorkspace xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"project_mpw.xsd\">$crlf$crlf",
            "  <SchemaVersion>1.0</SchemaVersion>$crlf$crlf",
            "  <Header>### uVision Project, (C) Keil Software</Header>$crlf$crlf";
}


sub write_comps {
  my($self, $fh) = @_;
  my $crlf = $self->crlf();

  print $fh '  <WorkspaceName>', $self->get_workspace_name(), ' - ',
            $self->create_command_line_string($0, @ARGV),
            '</WorkspaceName>', $crlf, $crlf;
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh "  <project>$crlf",
              "    <PathAndName>", $self->slash_to_backslash($project),
              "</PathAndName>$crlf",
              "  </project>$crlf$crlf";
  }
}


sub post_workspace {
  my($self, $fh) = @_;
  print $fh '</ProjectWorkspace>' . $self->crlf();
}


1;
