package RpmSpecWorkspaceCreator;

# ************************************************************
# Description   : An RPM .spec file Workspace Creator
# Author        : Adam Mitz (OCI)
# Create Date   : 11/23/2010
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
#use Dumpvalue;
use File::Path;

use RpmSpecProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

# ************************************************************
# Data Section
# ************************************************************

my $ext = '.spec'; # extension of files written by this WorkspaceCreator

# ************************************************************
# Subroutine Section
# ************************************************************

sub workspace_file_name {
  my $self = shift;
  return $self->get_modified_workspace_name($self->get_workspace_name(), $ext);
}

# Don't actually write the .spec file for the workspace.  Instead just invoke
# the $func callback so that post_workspace() and other parts of the normal
# workspace processing are called.  We don't want a .spec file for each MPC
# workspace because that is too course-grained.  Instead, post_workspace() will
# create one .spec for each aggregated workspace inside the primary workspace.
# Using the workspace aggregation mechanism this way allows multiple .spec
# files per workspace with MPC deriving their dependencies based on the
# projects they contain.
sub write_and_compare_file {
  my($self, $outdir, $oname, $func, @params) = @_;
  &$func($self, undef, @params);
  return undef;
}

sub rpmname {
  my($self, $mwc, $rpm2mwc, $check_unique) = @_;
  my $outfile = $mwc;
  $outfile =~ s/\.mwc$//i;
  $outfile = $self->get_modified_workspace_name($outfile, $ext, 1);
  my $base = lc $self->mpc_basename($outfile);
             # RPM requires lower-case .spec file names
  $base =~ tr/-/_/; # - is special for RPM, we translate it to _
  if ($check_unique && $rpm2mwc->{$base}) {
    die "ERROR: Can't create a duplicate RPM name: $base for mwc file $mwc\n" .
        "\tsee corresponding mwc file $rpm2mwc->{$base}\n";
  }
  $rpm2mwc->{$base} = $mwc;
  return $base;
}

sub post_workspace {
  my($self, $fh, $prjc) = @_;

  # for debugging only
#  my $dv = new Dumpvalue();
#  foreach my $key ('aggregated_mpc', 'mpc_to_output') {
#    print ">>> $key\n";
#    $dv->dumpValue($self->{$key});
#  }

  my $prjext = '\\' . # regexp escape for the dot that begins the extension
      $prjc->project_file_extension();

  my %rpm2mwc;  # rpm name (basename of spec file) => aggregated mwc w/ path
  my %mwc2rpm;  # inverse of the above hash
  my %proj2rpm; # project name (output of mpc) => rpm name that it belongs to
  # first pass to build the hashes above
  foreach my $agg (keys %{$self->{'aggregated_mpc'}}) {
    my $rpm = $mwc2rpm{$agg} = $self->rpmname($agg, \%rpm2mwc, 1);
    foreach my $m (@{$self->{'aggregated_mpc'}->{$agg}}) {
      foreach my $p (@{$self->{'mpc_to_output'}->{$m}}) {
        $proj2rpm{$p} = $rpm;
      }
    }
  }

  my $outdir = $self->get_outdir();

  foreach my $agg (keys %{$self->{'aggregated_mpc'}}) {
    my $name = "$outdir/$agg"; # $agg may contain directory parts
    my $dir  = $self->mpc_dirname($name);
    my $base = $mwc2rpm{$agg};
    $name = "$dir/$base";
    mkpath($dir, 0, 0777) if ($dir ne '.');

    open OUT, ">$name" or die "can't open $name";
    print OUT "Mock RPM spec file for '$base'\n\n";
#    my %dep; # keys are projects that projects in this RPM depend on
    my %rpm_requires; # keys are RPMs that this RPM depends on
    my @projects;
    foreach my $m (@{$self->{'aggregated_mpc'}->{$agg}}) {
      my $projdir = $self->mpc_dirname($m);
      foreach my $p (@{$self->{'mpc_to_output'}->{$m}}) {
        my $proj = $p;
        $proj =~ s/$prjext$//;
        push @projects, $proj;
        my $deps = $self->get_validated_ordering("$projdir/$p");
        foreach my $d (@$deps) {
#          $dep{$d} = 1;
          my $rpmdep = $proj2rpm{$d};
          if (defined $rpmdep && $rpmdep ne $base) {
            $rpm_requires{$rpmdep} = 1;
          }
        }
      }
    }
    print OUT "Contains projects: \n\t", join("\n\t", sort @projects), "\n\n";
#    print OUT "Depends on projects: ",
#      join(' ', sort map {s/$prjext$//; $_} keys %dep), "\n\n";
    print OUT "Depends on RPMs: ", join(' ', sort keys %rpm_requires), "\n\n";
    close OUT;
  }
}

1;
