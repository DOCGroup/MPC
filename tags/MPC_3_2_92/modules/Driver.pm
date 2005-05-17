package Driver;

# ************************************************************
# Description   : Functionality to call a workspace or project creator
# Author        : Chad Elliott
# Create Date   : 5/28/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Basename;

use Options;
use Parser;
use Version;

use vars qw(@ISA);
@ISA = qw(Parser Options);

# ************************************************************
# Data Section
# ************************************************************

my($index)    = 0;
my(@progress) = ('|', '/', '-', '\\');
my($cmdenv)   = 'MPC_COMMANDLINE';
my($minperl)  = 5.005;

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class)    = shift;
  my($path)     = shift;
  my($name)     = shift;
  my(@creators) = @_;
  my($self)     = $class->SUPER::new();

  $self->{'path'}     = $path;
  $self->{'name'}     = $name;
  $self->{'types'}    = {};
  $self->{'creators'} = \@creators;
  $self->{'default'}  = $creators[0];
  $self->{'reldefs'}  = {};
  $self->{'relorder'} = [];

  return $self;
}


sub convert_slashes {
  #my($self) = shift;
  return 0;
}


sub parse_line {
  my($self)        = shift;
  my($ih)          = shift;
  my($line)        = shift;
  my($status)      = 1;
  my($errorString) = undef;

  if ($line eq '') {
  }
  elsif ($line =~ /^([\w\*]+)(\s*,\s*(.*))?$/) {
    my($name)  = $1;
    my($value) = $3;
    if (defined $value) {
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
    }
    if ($name =~ /\*/) {
      $name =~ s/\*/.*/g;
      foreach my $key (keys %ENV) {
        if ($key =~ /^$name$/ && !exists $self->{'reldefs'}->{$key}) {
          ## Put this value at the front since it doesn't need
          ## to be built up from anything else.  It is a stand-alone
          ## relative definition.
          $self->{'reldefs'}->{$key} = undef;
          unshift(@{$self->{'relorder'}}, $key);
        }
      }
    }
    else {
      $self->{'reldefs'}->{$name} = $value;
      if (defined $value) {
        ## This relative definition may need to be built up from an
        ## existing value, so it needs to be put at the end.
        push(@{$self->{'relorder'}}, $name);
      }
      else {
        ## Put this value at the front since it doesn't need
        ## to be built up from anything else.  It is a stand-alone
        ## relative definition.
        unshift(@{$self->{'relorder'}}, $name);
      }
    }
  }
  else {
    $status = 0;
    $errorString = "Unrecognized line: $line";
  }

  return $status, $errorString;
}


sub optionError {
  my($self) = shift;
  my($line) = shift;

  $self->printUsage($line, $self->{'name'}, Version::get(),
                    $self->extractType($self->{'default'}),
                    keys %{$self->{'types'}});
  exit(0);
}


sub run {
  my($self) = shift;
  my(@args) = @_;

  ## Dynamically load in each perl module and set up
  ## the type tags and project creators
  my($creators) = $self->{'creators'};
  foreach my $creator (@$creators) {
    my($tag) = $self->extractType($creator);
    $self->{'types'}->{$tag} = $creator;
  }

  ## Before we process the arguments, we will prepend the $cmdenv
  ## environment variable.
  if (defined $ENV{$cmdenv}) {
    my($envargs) = $self->create_array($ENV{$cmdenv});
    unshift(@args, @$envargs);
  }

  my($options) = $self->options($self->{'name'},
                                $self->{'types'},
                                1,
                                @args);
  if (!defined $options) {
    ## If options are not defined, that means that calling options
    ## took care of whatever functionality that was required and
    ## we can now return with a good status.
    return 0;
  }

  ## If the minimum version of perl is not met, then it is an error
  if ($] < $minperl) {
    $self->error("Perl version $minperl is required.");
    return 1;
  }

  ## Set up a hash that we can use to keep track of what
  ## has been 'required'
  my(%loaded) = ();

  ## Set up the default creator, if no type is selected
  if (!defined $options->{'creators'}->[0]) {
    push(@{$options->{'creators'}}, $self->{'default'});
  }

  if ($options->{'recurse'}) {
    if (defined $options->{'input'}->[0]) {
      ## This is an error.
      ## -recurse was used and input files were specified.
      $self->optionError('No files should be ' .
                         'specified when using -recurse');
    }
    else {
      ## We have to load at least one creator here in order
      ## to call the generate_recursive_input_list virtual function.
      my($name) = $options->{'creators'}->[0];
      if (!$loaded{$name}) {
        require "$name.pm";
        $loaded{$name} = 1;
      }

      ## Generate the recursive input list
      my($creator) = $name->new();
      my(@input) = $creator->generate_recursive_input_list(
                                              '.', $options->{'exclude'});
      $options->{'input'} = \@input;

      ## If no files were found above, then we issue a warning
      ## that we are going to use the default input
      if (!defined $options->{'input'}->[0]) {
        $self->information('No files were found using the -recurse option. ' .
                           'Using the default input.');
      }
    }
  }

  ## Set the global feature file
  my($global_feature_file) = $self->{'path'} . '/config/global.features';

  ## Set up default values
  if (!defined $options->{'input'}->[0]) {
    push(@{$options->{'input'}}, '');
  }
  if (!defined $options->{'feature_file'}) {
    my($feature_file) = $self->{'path'} . '/config/default.features';
    if (-r $feature_file) {
      $options->{'feature_file'} = $feature_file;
    }
  }
  if (!defined $options->{'global'}) {
    my($global) = $self->{'path'} . '/config/global.mpb';
    if (-r $global) {
      $options->{'global'} = $global;
    }
  }
  ## Save the original directory outside of the loop
  ## to avoid calling it multiple times.
  my($orig_dir) = $self->getcwd();

  ## Always add the default include paths
  unshift(@{$options->{'include'}}, $orig_dir);
  unshift(@{$options->{'include'}}, $self->{'path'} . '/templates');
  unshift(@{$options->{'include'}}, $self->{'path'} . '/config');

  if ($options->{'reldefs'}) {
    ## Only try to read the file if it exists
    my($rel) = $self->{'path'} . '/config/default.rel';
    if (-r $rel) {
      my($srel, $errorString) = $self->read_file($rel);
      if (!$srel) {
        $self->error("$errorString\nin $rel");
        return 1;
      }
    }

    foreach my $key (@{$self->{'relorder'}}) {
      if (defined $ENV{$key} &&
          !defined $options->{'relative'}->{$key}) {
        $options->{'relative'}->{$key} = $ENV{$key};
      }
      if (defined $self->{'reldefs'}->{$key} &&
          !defined $options->{'relative'}->{$key}) {
        my($value) = $self->{'reldefs'}->{$key};
        if ($value =~ /\$(\w+)(.*)?/) {
          my($var)   = $1;
          my($extra) = $2;
          $options->{'relative'}->{$key} =
                     (defined $options->{'relative'}->{$var} ?
                              $options->{'relative'}->{$var} : '') .
                     (defined $extra ? $extra : '');
        }
        else {
          $options->{'relative'}->{$key} = $value;
        }
      }

      ## If a relative path is defined, remove all trailing slashes
      ## and replace any two or more slashes with a single slash.
      if (defined $options->{'relative'}->{$key}) {
        $options->{'relative'}->{$key} =~ s/([\/\\])[\/\\]+/$1/g;
        $options->{'relative'}->{$key} =~ s/[\/\\]$//g;
      }
    }
  }

  ## Set up un-buffered output for the progress callback
  $| = 1;

  ## Keep the starting time for the total output
  my($startTime) = time();
  my($loopTimes) = 0;

  ## Generate the files
  my($status) = 0;
  foreach my $cfile (@{$options->{'input'}}) {
    ## To correctly reference any pathnames in the input file, chdir to
    ## its directory if there's any directory component to the specified path.
    my($base) = basename($cfile);

    if (-d $cfile) {
      $base = '';
    }

    foreach my $name (@{$options->{'creators'}}) {
      ++$loopTimes;

      if (!$loaded{$name}) {
        require "$name.pm";
        $loaded{$name} = 1;
      }
      my($file) = $cfile;
      my($creator) = $name->new($options->{'global'},
                                $options->{'include'},
                                $options->{'template'},
                                $options->{'ti'},
                                $options->{'dynamic'},
                                $options->{'static'},
                                $options->{'relative'},
                                $options->{'addtemp'},
                                $options->{'addproj'},
                                (-t 1 ? \&progress : undef),
                                $options->{'toplevel'},
                                $options->{'baseprojs'},
                                $global_feature_file,
                                $options->{'feature_file'},
                                $options->{'features'},
                                $options->{'hierarchy'},
                                $options->{'exclude'},
                                $options->{'coexistence'},
                                $options->{'name_modifier'},
                                $options->{'apply_project'},
                                $options->{'genins'},
                                $options->{'into'},
                                $options->{'language'},
                                $options->{'use_env'},
                                $options->{'expand_vars'});
      if ($base ne $file) {
        my($dir) = ($base eq '' ? $file : $self->mpc_dirname($file));
        if (!$creator->cd($dir)) {
          $self->error("Unable to change to directory: $dir");
          $status++;
          last;
        }
        $file = $base;
      }
      my($diag) = 'Generating ' . $self->extractType($name) . ' output using ';
      if ($file eq '') {
        $diag .= 'default input';
      }
      else {
        my($partial)  = $self->getcwd();
        my($oescaped) = $self->escape_regex_special($orig_dir) . '(/)?';
        $partial =~ s/^$oescaped//;
        $diag .= ($partial ne '' ? "$partial/" : '') . $file;
      }
      $self->diagnostic($diag);
      my($start) = time();
      if (!$creator->generate($file)) {
        $self->error("Unable to process: " .
                     ($file eq '' ? 'default input' : $file));
        $status++;
        last;
      }
      my($total) = time() - $start;
      $self->diagnostic('Generation Time: ' .
                        (int($total / 60) > 0 ? int($total / 60) . 'm ' : '') .
                        ($total % 60) . 's');
      $creator->cd($orig_dir);
    }
    if ($status) {
      last;
    }
  }

  ## If we went through the loop more than once, we need to print
  ## out the total amount of time
  if ($loopTimes > 1) {
    my($total) = time() - $startTime;
    $self->diagnostic('     Total Time: ' .
                      (int($total / 60) > 0 ? int($total / 60) . 'm ' : '') .
                      ($total % 60) . 's');
  }

  return $status;
}


sub progress {
  ## This method will be called before each output file is written.
  print "$progress[$index]\r";
  $index++;
  if ($index > $#progress) {
    $index = 0;
  }
}


1;
