package GHSWorkspaceCreator;

# ************************************************************
# Description   : An incomplete GHS Workspace creator
# Author        : Chad Elliott
# Create Date   : 7/3/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use GHSProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

my(%directives) = ('sysincdirs' => 1,
                   'libdirs'    => 1,
                   'syslibdirs' => 1,
                   'libraries'  => 1,
                   'defines'    => 1,
                   'staticlink' => 1,
                   'deflibdirs' => 1,
                  );

# ************************************************************
# Subroutine Section
# ************************************************************

sub compare_output {
  #my($self) = shift;
  return 1;
}


sub workspace_file_name {
  my($self) = shift;
  return $self->get_modified_workspace_name('default', '.bld');
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  print $fh "#!build$crlf",
            "default:$crlf",
            "\tnobuild$crlf",
            "\t:cx_option=exceptions$crlf",
            "\t:cx_option=std_namespaces$crlf",
            "\t:language=cxx$crlf",
            "\t:config_setting=longlong$crlf",
            "\t:cx_mode=ansi$crlf";
}


sub mix_settings {
  my($self)    = shift;
  my($project) = shift;
  my($crlf)    = $self->crlf();
  my($rh)      = new FileHandle();
  my($mix)     = '';

  ## Things that seem like they should be set in the project
  ## actually have to be set in the controlling build file.
  if (open($rh, $project)) {
    while(<$rh>) {
      if (/^\s*(program|library|subproject)\s*$/) {
        $mix .= "\t$1$crlf" .
                "\t:object_dir=" . $self->mpc_dirname($project) .
                '/.obj' . $crlf;
      }
      elsif (/^\s*(shared_library)\s*$/) {
        $mix .= "\t$1$crlf" .
                "\t:config_setting=pic$crlf" .
                "\t:object_dir=" . $self->mpc_dirname($project) .
                '/.shobj' . $crlf;
      }
      else {
        if (/^\s*:(\w+)=/) {
          if (defined $directives{$1}) {
            $mix .= $_;
          }
        }
      }
    }
    close($rh);
  }

  return $mix;
}


sub write_comps {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();

  ## Print out each projet
  foreach my $project ($self->sort_dependencies($self->get_projects())) {
    print $fh "$project$crlf",
              $self->mix_settings($project);
  }
}



1;
