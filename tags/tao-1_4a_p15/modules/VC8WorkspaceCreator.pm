package VC8WorkspaceCreator;

# ************************************************************
# Description   : A VC8 Workspace Creator
# Author        : Johnny Willemsen
# Create Date   : 4/21/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC8ProjectCreator;
use VC71WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(VC71WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************

my(%lang_map) = ('cplusplus' => 'Visual C#',
                 'csharp'    => 'Visual C#',
                 'vb'        => 'Visual Basic',
                 'java'      => 'Visual J#');

# ************************************************************
# Subroutine Section
# ************************************************************

sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh '﻿', $crlf,
            'Microsoft Visual Studio Solution File, Format Version 9.00', $crlf,
            '# Visual Studio 2005', $crlf,
            '# $Id$', $crlf,
            '#', $crlf,
            '# This file was generated by MPC.  Any changes made directly to', $crlf,
            '# this file will be lost the next time it is generated.', $crlf,
            '#', $crlf,
            '# MPC Command:', $crlf,
            '# ', $self->create_command_line_string($0, @ARGV), $crlf;
}

sub adjust_names {
  my($self) = shift;
  my($name) = shift;
  my($proj) = shift;
  my($lang) = shift;

  if ($lang eq 'website') {
    $proj = $self->mpc_dirname($proj);
    $proj =~ s/\.vcproj$//;
    $proj .= '\\';
    $name .= '\\';
  }

  $proj =~ s/\//\\/g; 
  return $name, $proj;
}

sub get_short_config_name {
  my($self) = shift;
  my($cfg)  = shift;
  return $cfg;
}

sub get_solution_config_section_name {
  #my($self) = shift;
  return 'SolutionConfigurationPlatforms';
}

sub get_project_config_section_name {
  #my($self) = shift;
  return 'ProjectConfigurationPlatforms';
}

sub print_additional_sections {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh "\tGlobalSection(SolutionProperties) = preSolution$crlf",
            "\t\tHideSolutionNode = FALSE$crlf",
            "\tEndGlobalSection$crlf";
}

sub allow_empty_dependencies {
  #my($self) = shift;
  return 0;
}

sub print_inner_project {
  my($self)             = shift;
  my($fh)               = shift;
  my($gen)              = shift;
  my($currguid)         = shift;
  my($deps)             = shift;
  my($name)             = shift;
  my($name_to_guid_map) = shift;
  my($proj_language)    = shift;
  my($cfgs)             = shift;

  if ($proj_language eq 'website') {
    my($crlf)      = $self->crlf();
    my($language)  = $self->get_language();
    my($directory) = ($name eq '.\\' ?
                        $self->get_workspace_name() . '\\' : $name);
    my($notrail)   = $directory;
    $notrail =~ s/\\$//;

    # Print the website project.
    print $fh "\tProjectSection(WebsiteProperties) = preProject", $crlf;

    my($references) = undef;
    foreach my $dep (@$deps) {
      if (defined $$name_to_guid_map{$dep}) {
        $references = "\t\t" .
                      'ProjectReferences = "' if (!defined $references);
        $references .= "{$$name_to_guid_map{$dep}}|$dep;";
      }
    }
    if (defined $references) {
      print $fh $references, '"', $crlf;
    }

    my(%cfg_seen) = ();
    foreach my $config (@$cfgs) {
      $config =~ s/\|.*//;
      if (!$cfg_seen{$config}) {
        print $fh "\t\t$config.AspNetCompiler.VirtualPath = \"/$notrail\"", $crlf,
                  "\t\t$config.AspNetCompiler.PhysicalPath = \"$directory\"", $crlf,
                  "\t\t$config.AspNetCompiler.TargetPath = \"PrecompiledWeb\\$directory\"", $crlf,
                  "\t\t$config.AspNetCompiler.Updateable = \"true\"", $crlf,
                  "\t\t$config.AspNetCompiler.ForceOverwrite = \"true\"", $crlf,
                  "\t\t$config.AspNetCompiler.FixedNames = \"true\"", $crlf,
                  "\t\t$config.AspNetCompiler.Debug = \"",
                  ($config =~ /debug/i ? 'True' : 'False'), "\"", $crlf;
        $cfg_seen{$config} = 1;
      }
    }
    print $fh "\t\tVWDPort = \"1573\"", $crlf,
              "\t\tDefaultWebSiteLanguage = \"", $lang_map{$language}, "\"", $crlf,
              "\tEndProjectSection", $crlf;
  }
  else {
    # We can ignore this project and pass it to the
    # SUPER since it's not a website.
    $self->SUPER::print_inner_project($fh,
                                      $gen,   
                                      $currguid,
                                      $deps,    
                                      $name,
                                      $name_to_guid_map);
  }
}

1;