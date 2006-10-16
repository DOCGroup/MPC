package HTMLWorkspaceCreator;

# ************************************************************
# Description   : An html workspace creator
# Author        : Justin Michel
# Create Date   : 8/25/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use HTMLProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_name {
  my($self) = shift;
  return $self->get_modified_workspace_name($self->get_workspace_name(),
                                            '_workspace.html');
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">', $crlf,
            '<html>', $crlf,
            '<!-- $Id$ -->', $crlf,
            '<!-- MPC Command: -->', $crlf,
            '<!-- ', $self->create_command_line_string($0, @ARGV),' -->', $crlf,
            '<head>', $crlf,
            '<title>', $self->get_workspace_name(), '</title>', $crlf,
            '  <style type="text/css">', $crlf,
            '    a {font: 12pt bold verdana, lucida; color: white; padding: 3px;}', $crlf,
            '    td {font: 12pt bold verdana, lucida; color: white; padding: 3px; background-color: cadetblue;}', $crlf,
            '    thead tr td {font: 18pt "trebuchet ms", helvetica; color: white; padding: 3px; background-color: teal;}', $crlf,
            '  </style>', $crlf,
            '</head>', $crlf,
            '<body>', $crlf;
}


sub write_comps {
  my($self)         = shift;
  my($fh)           = shift;
  my($creator)      = shift;
  my($project_info) = $self->get_project_info();
  my($crlf)         = $self->crlf();

  print $fh "<table style=\"table-layout:fixed\" width=\"400\" " .
            "summary=\"MPC Projects\">$crlf" .
            "<col style=\"background-color: darkcyan;\">$crlf" .
            "<thead>$crlf" .
            "<tr><td>Projects In Build Order</td></tr>$crlf" .
            "</thead>$crlf" .
            "<tbody>$crlf";

  ## Sort the projects in build order instead of alphabetical order
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    my($name) = $$project_info{$project}->[0];
    print $fh "<tr><td>" .
              "<a href='$project'>$name</a>" .
              "</td></tr>$crlf";
  }

  print $fh "</tbody></table>";
}


sub post_workspace {
  my($self) = shift;
  my($fh)   = shift;
  print $fh "</body></html>" . $self->crlf();
}


1;
