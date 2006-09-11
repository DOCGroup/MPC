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

use Options;
use Parser;
use Version;
use ConfigParser;

use vars qw(@ISA);
@ISA = qw(Parser Options);

# ************************************************************
# Data Section
# ************************************************************

my($index)    = 0;
my(@progress) = ('|', '/', '-', '\\');
my($cmdenv)   = 'MPC_COMMANDLINE';

my(%valid_cfg) = ('command_line'     => 1,
                  'dynamic_types'    => 1,
                  'includes'         => 1,
                  'logging'          => 1,
                  'verbose_ordering' => 1,
                 );

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
  $self->{'basepath'} = ::getBasePath();
  $self->{'name'}     = $name;
  $self->{'types'}    = {};
  $self->{'creators'} = \@creators;
  $self->{'default'}  = $creators[0];
  $self->{'reldefs'}  = {};
  $self->{'relorder'} = [];

  return $self;
}


sub locate_dynamic_directories {
  my($self)   = shift;
  my($dtypes) = shift;

  if (defined $dtypes) {
    my(@directories) = ();
    foreach my $dir (split(/\s*,\s*/, $dtypes)) {
      if (-d "$dir/modules" || -d "$dir/config" || -d "$dir/templates") {
        push(@directories, $dir);
      }
    }
    return \@directories;
  }

  return undef;
}


sub add_dynamic_creators {
  my($self) = shift;
  my($dirs) = shift;
  my($type) = (index($self->{'creators'}->[0], 'Workspace') > 0 ?
                             'WorkspaceCreator' : 'ProjectCreator');
  foreach my $dir (@$dirs) {
    my($fh) = new FileHandle();
    if (opendir($fh, "$dir/modules")) {
      foreach my $file (readdir($fh)) {
        if ($file =~ /(.+$type)\.pm$/i) {
          $self->debug("Pulling in $1\n");
          push(@{$self->{'creators'}}, $1);
        }
      }
      closedir($fh);
    }
  }
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
    if ($name =~ s/\*/.*/g) {
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


sub find_file {
  my($self)     = shift;
  my($includes) = shift;
  my($file)     = shift;

  foreach my $inc (@$includes) {
    if (-r $inc . '/' . $file) {
      $self->debug("$file found in $inc");
      return $inc . '/' . $file;
    }
  }
  return undef;
}


sub determine_cfg_file {
  my($self) = shift;
  my($cfg)  = shift;
  my($odir) = shift;
  my($ci)   = $self->case_insensitive();

  $odir = lc($odir) if ($ci);
  foreach my $name (@{$cfg->get_names()}) {
    my($value) = $cfg->get_value($name);
    if (index($odir, ($ci ? lc($name) : $name)) == 0) {
      my($cfgfile) = $value . '/MPC.cfg';
      return $cfgfile if (-e $cfgfile);
    }
  }

  return undef;
}


sub run {
  my($self)    = shift;
  my(@args)    = @_;
  my($cfgfile) = undef;

  ## Save the original directory outside of the loop
  ## to avoid calling it multiple times.
  my($orig_dir) = $self->getcwd();

  ## Read the code base config file from the config directory
  ## under $MPC_ROOT
  my($cbcfg)  = new ConfigParser();
  my($cbfile) = "$self->{'basepath'}/config/base.cfg";
  if (-r $cbfile) {
    my($status, $error) = $cbcfg->read_file($cbfile);
    if (!$status) {
      $self->error("$error at line " . $cbcfg->get_line_number() .
                   " of $cbfile");
      return 1;
    }
    $cfgfile = $self->determine_cfg_file($cbcfg, $orig_dir);
  }

  ## If no MPC config file was found and
  ## there is one in $MPC_ROOT/config, we will use that.
  if (!defined $cfgfile) {
    $cfgfile = $self->{'basepath'} . '/config/MPC.cfg';
    $cfgfile = undef if (!-e $cfgfile);
  }

  ## Read the MPC config file
  my($cfg) = new ConfigParser(\%valid_cfg);
  if (defined $cfgfile) {
    my($status, $error) = $cfg->read_file($cfgfile);
    if (!$status) {
      $self->error("$error at line " . $cfg->get_line_number() .
                   " of $cfgfile");
      return 1;
    }
    OutputMessage::set_levels($cfg->get_value('logging'));
  }

  $self->debug("CMD: $0 @ARGV");

  ## After we read the config file, see if the user has provided
  ## dynamic types
  my($dynamic) = $self->locate_dynamic_directories(
                          $cfg->get_value('dynamic_types'));
  if (defined $dynamic) {
    ## If so, add in the creators found in the dynamic directories
    $self->add_dynamic_creators($dynamic);

    ## Add the each dynamic path to the include paths
    foreach my $dynpath (@$dynamic) {
      unshift(@INC, $dynpath . '/modules');
      unshift(@args, '-include', "$dynpath/config",
                     '-include', "$dynpath/templates");
    }
  }

  ## Dynamically load in each perl module and set up
  ## the type tags and project creators
  my($creators) = $self->{'creators'};
  foreach my $creator (@$creators) {
    my($tag) = $self->extractType($creator);
    $self->{'types'}->{$tag} = $creator;
  }

  ## Before we process the arguments, we will prepend the $cmdenv
  ## environment variable.
  my($cmd) = $cfg->get_value('command_line');
  if (!defined $cmd) {
    $cmd = $ENV{$cmdenv};
    if (defined $cmd) {
      print "NOTE: $cmdenv is deprecated.  See the USAGE file for details.\n";
    }
  }
  if (defined $cmd) {
    my($envargs) = $self->create_array($cmd);
    unshift(@args, @$envargs);
  }

  ## Now add in the includes to the command line arguments.
  ## It is done this way to allow the Options module to process
  ## the include path as it does all others.
  my($incs) = $cfg->get_value('includes');
  if (defined $incs) {
    foreach my $inc (split(/\s*,\s*/, $incs)) {
      push(@args, '-include', $inc);
    }
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

  ## Set up a hash that we can use to keep track of what
  ## has been 'required'
  my(%loaded) = ();

  ## Set up the default creator, if no type is selected
  if (!defined $options->{'creators'}->[0]) {
    push(@{$options->{'creators'}}, $self->{'default'});
    $self->warning("In the future, there will no longer be a default " .
                   "project type.  You should specify one with the " .
                   "-type option.");
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

  ## Add the default include paths.  If the user has used the dynamic
  ## types method of adding types to MPC, we need to push the paths
  ## on.  Otherwise, we unshift them onto the front.
  if ($self->{'path'} eq $self->{'basepath'}) {
    push(@{$options->{'include'}}, $self->{'path'} . '/config',
                                   $self->{'path'} . '/templates');
  }
  else {
    unshift(@{$options->{'include'}}, $self->{'path'} . '/config',
                                      $self->{'path'} . '/templates');
  }

  ## All includes (except the current directory) have been added by this time
  $self->debug("INCLUDES: @{$options->{'include'}}");

  ## Set the global feature file
  my($global_feature_file) = (defined $options->{'gfeature_file'} &&
                              -r $options->{'gfeature_file'} ?
                                 $options->{'gfeature_file'} : undef);
  if (!defined $global_feature_file) {
    my($gf) = 'global.features';
    $global_feature_file = $self->find_file($options->{'include'}, $gf);
    if (!defined $global_feature_file) {
      $global_feature_file = $self->{'basepath'} . '/config/' . $gf;
    }
  }

  ## Set up default values
  if (!defined $options->{'input'}->[0]) {
    push(@{$options->{'input'}}, '');
  }
  if (!defined $options->{'feature_file'}) {
    $options->{'feature_file'} = $self->find_file($options->{'include'},
                                                  'default.features');
  }
  if (!defined $options->{'global'}) {
    $options->{'global'} = $self->find_file($options->{'include'},
                                            'global.mpb');
  }
  if ($options->{'reldefs'}) {
    ## Only try to read the file if it exists
    my($rel) = $self->find_file($options->{'include'}, 'default.rel');
    if (defined $rel) {
      my($srel, $errorString) = $self->read_file($rel);
      if (!$srel) {
        $self->error("$errorString\nin $rel");
        return 1;
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
  }

  ## Always add the current path to the include paths
  unshift(@{$options->{'include'}}, $orig_dir);

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
    ## mpc_basename() always expects UNIX file format.
    $cfile =~ s/\\/\//g;
    my($base) = ($cfile eq '' ? '' : $self->mpc_basename($cfile));

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
                                $options->{'expand_vars'},
                                $options->{'gendot'});

      ## Update settings based on the configuration file
      $creator->set_verbose_ordering($cfg->get_value('verbose_ordering'));

      if ($base ne $file) {
        my($dir) = ($base eq '' ? $file : $self->mpc_dirname($file));
        if (!$creator->cd($dir)) {
          $self->error("Unable to change to directory: $dir");
          $status++;
          last;
        }
        $file = $base;
      }
      my($diag) = 'Generating \'' . $self->extractType($name) .
                  '\' output using ';
      if ($file eq '') {
        $diag .= 'default input';
      }
      else {
        my($partial)  = $self->getcwd();
        my($oescaped) = $self->escape_regex_special($orig_dir) . '(/)?';
        $partial =~ s!\\!/!g;
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
