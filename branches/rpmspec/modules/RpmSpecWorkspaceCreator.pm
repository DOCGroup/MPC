package RpmSpecWorkspaceCreator;

# put comments here

use strict;
use Dumpvalue;
use RpmSpecProjectCreator;
use WorkspaceCreator;

use vars qw(@ISA);
@ISA = qw(WorkspaceCreator);

sub workspace_file_name {
  my $self = shift;
  return $self->get_modified_workspace_name($self->get_workspace_name(),
                                            '.rpmspec');
}

sub write_and_compare_file {
  my($self, $outdir, $oname, $func, @params) = @_;
  &$func($self, undef, @params);
  return undef;
}

sub post_workspace {
  my($self, $fh, $prjc) = @_;
  my $dv = new Dumpvalue();
  foreach my $key ('aggregated_mpc', 'mpc_to_output') {
    print ">>> $key\n";
    $dv->dumpValue($self->{$key});
  }

  my $ext = '\\' . $prjc->project_file_extension();

  foreach my $agg (keys %{$self->{'aggregated_mpc'}}) {
    my $outfile = lc $agg;
    $outfile =~ s/\.mwc$//;
#    $outfile =~ tr/_/-/;
    open OUT, ">$outfile.spec" or die "can't open"; #TODO get_outdir(), etc.
    print OUT "Mock RPM spec file for '$outfile'\n\n";
    foreach my $m (@{$self->{'aggregated_mpc'}->{$agg}}) {
      foreach my $p (@{$self->{'mpc_to_output'}->{$m}}) {
        my $proj = $p;
        $proj =~ s/$ext$//;
        print OUT "Contains project: $proj\n";
      }
    }
    close OUT;
  }
}

1;
