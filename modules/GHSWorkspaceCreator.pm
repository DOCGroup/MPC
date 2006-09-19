package GHSWorkspaceCreator;

# ************************************************************
# Description   : A GHS Workspace creator for version 4.x
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

my(%directives) = ('I'          => 1,
                   'L'          => 1,
                   'D'          => 1,
                   'l'          => 1,
                   'G'          => 1,
                   'non_shared' => 1,
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
  return $self->get_modified_workspace_name('default', '.gpj');
}


sub pre_workspace {
  my($self) = shift;
  my($fh)   = shift;
  my($crlf) = $self->crlf();
  my($prjs) = $self->get_projects();
  my($tgt)  = undef;

  ## Take the primaryTarget from the first project in the list
  if (defined $$prjs[0]) {
    my($fh)      = new FileHandle();
    my($outdir)  = $self->get_outdir();
    if (open($fh, "$outdir/$$prjs[0]")) {
      while(<$fh>) {
        if (/^#primaryTarget=(.+)$/) {
          $tgt = $1;
          last;
        }
      }
      close($fh);
    }
  }

  ## Print out the preliminary information
  print $fh "#!gbuild$crlf",
            "primaryTarget=$tgt$crlf",
            "[Project]$crlf",
            "\t-I.$crlf",
            "\t:sourceDir=.$crlf",
            "\t--std$crlf",
            "\t--exceptions$crlf",
            "\t-language=cxx$crlf",
            "\t--long_long$crlf",
            "\t--new_style_casts$crlf";
}


sub mix_settings {
  my($self)    = shift;
  my($project) = shift;
  my($crlf)    = $self->crlf();
  my($rh)      = new FileHandle();
  my($mix)     = '';
  my($outdir)  = $self->get_outdir();

  ## Things that seem like they should be set in the project
  ## actually have to be set in the controlling project file.
  if (open($rh, "$outdir/$project")) {
    while(<$rh>) {
      if (/^\s*(\[(Program|Library|Subproject)\])\s*$/) {
        $mix .= "\t\t$1$crlf" .
                "\t-object_dir=" . $self->mpc_dirname($project) .
                '/.obj' . $crlf;
      }
      elsif (/^\s*(\[Shared Object\])\s*$/) {
        $mix .= "\t\t$1$crlf" .
                "\t-pic$crlf" .
                "\t-object_dir=" . $self->mpc_dirname($project) .
                '/.shobj' . $crlf;
      }
      else {
        if (/^\s*\-((\w)\w*)/) {
          if (defined $directives{$2} || defined $directives{$1}) {
            $mix .= $_;
          }
        }
      }
    }
    close($rh);
  }
  $mix .= $crlf if ($mix eq '');

  return $mix;
}


sub write_comps {
  my($self) = shift;
  my($fh)   = shift;

  ## Print out each projet
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh "$project", $self->mix_settings($project);
  }
}



1;
