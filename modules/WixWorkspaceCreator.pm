package WIXWorkspaceCreator;

# ************************************************************
# Description   : A Wix Workspace creator
# Author        : James H. Hill
# Create Date   : 6/23/2009
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use WIXProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************


# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_extension {
  return '.wxs';
}

sub workspace_file_name {
  my($self) = shift;
  my($name) = $self->get_workspace_name();

  return $self->get_modified_workspace_name($name, '.wxi');
}

sub pre_workspace {
  my($self, $fh) = @_;
  my($crlf) = $self->crlf();
  my($name) = $self->get_workspace_name();

  ## Begin the project definition for the workspace
  print $fh '<?xml version="1.0" encoding="utf-8" standalone="yes"?>', $crlf,
            '<Include>', $crlf;
}

sub write_comps {
  my($self)     = shift;
  my($fh)       = shift;
  my($projects) = $self->get_projects();
  my(@list)     = $self->sort_dependencies($projects);
  my($crlf)     = $self->crlf();


  # print the target for clean
  foreach my $project (@list) {
    print $fh "  <?include $project ?>", $crlf;
  }
}

sub post_workspace {
  my($self, $fh) = @_;
  my($projects)  = $self->get_projects();
  my($info)      = $self->get_project_info();
  my(@list)      = $self->sort_dependencies($projects);
  my($crlf)      = $self->crlf();
  my($wname)      = $self->get_workspace_name();

  # Create a component group consisting of all the projects.
  print $fh $crlf,
            '  <Fragment>', $crlf,
            '    <ComponentGroup Id="', $wname, '">', $crlf;

  foreach my $project (@list) {
    my($pname, $rawdeps, $guid, $language, $custom_only, $nocross, @cfgs) = @{$$info{$project}};
    my($name, $proj) = $self->adjust_names($pname, $project, $language);

    print $fh '      <ComponentRef Id="', $name, '" />', $crlf;
  }

  print $fh '    </ComponentGroup>', $crlf,
            '  </Fragment>', $crlf,
            '</Include>', $crlf;
}

sub adjust_names {
  my($self, $name, $proj, $lang) = @_;
  $proj =~ s/\//\\/g;
  return $name, $proj;
}

1;
