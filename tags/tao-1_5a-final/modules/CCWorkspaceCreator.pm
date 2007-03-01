package CCWorkspaceCreator;

# ************************************************************
# Description   : A Code Composer Workspace creator
# Author        : Chad Elliott
# Create Date   : 9/18/2006
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use CCProjectCreator;
use WinWorkspaceBase;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WinWorkspaceBase WorkspaceCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub compare_output {
  #my($self) = shift;
  return 1;
}


sub workspace_file_extension {
  #my($self) = shift;
  return '.code_composer';
}


sub write_comps {
  my($self)    = shift;
  my($fh)      = shift;
  my($creator) = shift;
  my($crlf)    = $self->crlf();

  foreach my $project ($self->sort_dependencies($self->get_projects(), 0)) {
    print $fh "$project$crlf";
    $self->add_dependencies($creator, $project);
  }
}


sub add_dependencies {
  my($self)    = shift;
  my($creator) = shift;
  my($proj)    = shift;
  my($fh)      = new FileHandle();
  my($outdir)  = $self->get_outdir();
  $outdir      = $self->getcwd() if ($outdir eq '.');

  if (open($fh, "$outdir/$proj")) {
    my($write) = 0;
    my(@read)  = ();
    my($cwd)   = $self->getcwd();
    while(<$fh>) {
      if (/MPC\s+ADD\s+DEPENDENCIES/) {
        my(@projs) = ();
        my($crlf)  = $self->crlf();
        my($deps)  = $self->get_validated_ordering($proj);
        foreach my $dep (@$deps) {
          my($relative) = $self->get_relative_dep_file($creator,
                                                       "$cwd/$proj",
                                                       $dep);
          if (defined $relative) {
            if (!$write) {
              $write = 1;
              push(@read, "[Project Dependencies]$crlf");
            }
            push(@read, "Source=\"$relative\"$crlf");
            push(@projs, $relative);
          }
        }
        if ($write) {
          push(@read, $crlf);
          foreach my $proj (@projs) {
            push(@read, "[\"$proj\" Settings]$crlf",
                        "MatchConfigName=true$crlf",
                        $crlf);
          }
        }
        else {
          last;
        }
      }
      else {
        push(@read, $_);
      }
    }
    close($fh);

    if ($write && open($fh, ">$outdir/$proj")) {
      foreach my $line (@read) {
        print $fh $line;
      }
      close($fh);
    }
  }
}

1;
