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

use GUID;
use VC8WebProjectCreator;
use VC8WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(VC8WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************

my(%lang_map) = ('cplusplus'  => 'Visual C#',
                 'csharp'     => 'Visual C#',
                 'vb'         => 'Visual Basic',
                 'java'       => 'Visual J#');

my($guid) = undef;

# ************************************************************
# Subroutine Section
# ************************************************************

sub write_workspace {
  my($self)      = shift;
  my($creator)   = shift;
  my($addfile)   = shift;

  # Generate the GUID for the website. Apparently, VC8 assumes
  # the base workspace directory is the project. Therefore we
  # have to explicitly create a new project using the workspace
  # directory as the 'project_name'.
  $guid = GUID::generate($self->workspace_file_name(),
                         $self->{'current_input'},
                         $self->getcwd());

  # Add the website to the list of project names
  my($projects) = $self->get_projects();
  my($pname) = $self->getcwd();
  $pname =~ s/\//\\/g;
  push(@$projects, $pname);

  # Add the website project to the 'project_info'.
  my($project_info) = $self->get_project_info();
  @{$project_info->{$pname}} = ($pname,
                                '',
                                $guid,
                                'website',
                                'Debug|',
                                'Release|',
                                'Debug|Any CPU',
                                'Release|Any CPU');

  $self->SUPER::write_workspace($creator, $addfile);
}


sub print_inner_project {
  my($self)             = shift;
  my($fh)               = shift;
  my($gen)              = shift;
  my($currguid)         = shift;
  my($deps)             = shift;
  my($name)             = shift;
  my($name_to_guid_map) = shift;

  if ($guid eq $currguid) {
    my($crlf)       = $self->crlf();
    my($workspace)  = $self->get_workspace_name();
    my($language)   = $self->get_language();

    # Print the website project.
    print $fh "\tProjectSection(WebsiteProperties) = preProject", $crlf,
              "\t\tDebug.AspNetCompiler.VirtualPath = \"/$workspace\"", $crlf,
              "\t\tDebug.AspNetCompiler.PhysicalPath = \"..\\$workspace\\\"", $crlf,
              "\t\tDebug.AspNetCompiler.TargetPath = \"PrecompiledWeb\\$workspace\\\"", $crlf,
              "\t\tDebug.AspNetCompiler.Updateable = \"true\"", $crlf,
              "\t\tDebug.AspNetCompiler.ForceOverwrite = \"true\"", $crlf,
              "\t\tDebug.AspNetCompiler.FixedNames = \"false\"", $crlf,
              "\t\tDebug.AspNetCompiler.Debug = \"True\"", $crlf,
              "\t\tRelease.AspNetCompiler.VirtualPath = \"/$workspace\"", $crlf,
              "\t\tRelease.AspNetCompiler.PhysicalPath = \"..\\$workspace\\\"", $crlf,
              "\t\tRelease.AspNetCompiler.TargetPath = \"PrecompiledWeb\\$workspace\\\"", $crlf,
              "\t\tRelease.AspNetCompiler.Updateable = \"true\"", $crlf,
              "\t\tRelease.AspNetCompiler.ForceOverwrite = \"true\"", $crlf,
              "\t\tRelease.AspNetCompiler.FixedNames = \"false\"", $crlf,
              "\t\tRelease.AspNetCompiler.Debug = \"False\"", $crlf,
              "\t\tVWDPort = \"1573\"", $crlf,
              "\t\tDefaultWebSiteLanguage = \"", $lang_map{$language}, "\"", $crlf,
              "\tEndProjectSection", $crlf;
  }
  else {
    # We can ignore this project and pass it to the
    # SUPER since it's not the website.
    $self->SUPER::print_inner_project($fh,
                                      $gen,
                                      $currguid,
                                      $deps,
                                      $name,
                                      $name_to_guid_map);
  }
}

1;
