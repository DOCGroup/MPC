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

# ************************************************************
# Data Section
# ************************************************************

my(%directives) = ('I'          => 1,
                   'L'          => 1,
                   'D'          => 1,
                   'l'          => 1,
                   'G'          => 1,
                   'non_shared' => 1,
                   'bsp'        => 1,
                   'os_dir'     => 1,
                  );
my($tgt)        = undef;
my($integrity)  = '[INTEGRITY Application]';
my(@integ_bsps) = ();

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
            "\t-language=cxx$crlf",
            "\t--long_long$crlf",
            "\t--new_style_casts$crlf";
}


sub create_integrity_project {
  my($self)     = shift;
  my($int_proj) = shift;
  my($project)  = shift;
  my($type)     = shift;
  my($crlf)     = $self->crlf();
  my($fh)       = new FileHandle();

  if (open($fh, ">$int_proj")) {
    print $fh "#!gbuild$crlf",
              "\t$integrity$crlf",
              "\t-dynamic$crlf",
              "$project\t\t$type$crlf";
    foreach my $bsp (@integ_bsps) {
      print $fh "$bsp$crlf";
    }
    close($fh);
  }
}


sub mix_settings {
  my($self)    = shift;
  my($project) = shift;
  my($crlf)    = $self->crlf();
  my($rh)      = new FileHandle();
  my($mix)     = $project;
  my($outdir)  = $self->get_outdir();

  ## Things that seem like they should be set in the project
  ## actually have to be set in the controlling project file.
  if (open($rh, "$outdir/$project")) {
    my($integrity_project) = (index($tgt, 'integrity') >= 0);
    my($int_proj) = undef;
    my($int_type) = undef;
    while(<$rh>) {
      if (/^\s*(\[(Program|Library|Subproject)\])\s*$/) {
        my($type) = $1;
        if ($integrity_project && $type eq '[Program]') {
          $int_proj = $project;
          $int_proj =~ s/(\.gpj)$/_int$1/;
          $int_type = $type;
          $mix =~ s/(\.gpj)$/_int$1/;
          $type = $integrity;
        }
        $mix .= "\t\t$type$crlf" .
                "\t-object_dir=" . $self->mpc_dirname($project) .
                '/.obj' . $crlf;
      }
      elsif (/^\s*(\[Shared Object\])\s*$/) {
        $mix .= "\t\t$1$crlf" .
                "\t-pic$crlf" .
                "\t-object_dir=" . $self->mpc_dirname($project) .
                '/.shobj' . $crlf;
      }
      elsif ($integrity_project && /^(.*\.bsp)\s/) {
        push(@integ_bsps, $1);
      }
      else {
        if (/^\s*\-((\w)\w*)/) {
          if (defined $directives{$2} || defined $directives{$1}) {
            $mix .= $_;
          }
        }
      }
    }
    if (defined $int_proj) {
      $self->create_integrity_project($int_proj, $project, $int_type);
    }
    close($rh);
  }

  return $mix;
}


sub write_comps {
  my($self) = shift;
  my($fh)   = shift;

  ## Print out each projet
  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh $self->mix_settings($project);
  }
}



1;
