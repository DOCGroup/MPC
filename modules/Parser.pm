package Parser;

# ************************************************************
# Description   : A basic parser that requires a parse_line override
# Author        : Chad Elliott
# Create Date   : 5/16/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use FileHandle;

use OutputMessage;
use StringProcessor;
use DirectoryManager;

use vars qw(@ISA);
@ISA = qw(OutputMessage StringProcessor DirectoryManager);

# ************************************************************
# Data Section
# ************************************************************

my(%filecache) = ();
my($silent)    = 'MPC_SILENT';
my($logging)   = 'MPC_LOGGING';

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class) = shift;
  my($inc)   = shift;
  my($log)   = $ENV{$logging};

  ## The order of these array variables must correspond to the
  ## order of the parameters to OutputMessage::new().
  my($params) = (defined $ENV{$silent} ||
                 defined $log ? [0, 0, 0, 0] : [0, 1, 1, 1]);

  if (defined $log) {
    if ($log =~ /info(rmation)?\s*=\s*(\d+)/i) {
      $$params[0] = $2;
    }
    if ($log =~ /warn(ing)?\s*=\s*(\d+)/i) {
      $$params[1] = $2;
    }
    if ($log =~ /diag(nostic)?\s*=\s*(\d+)/i) {
      $$params[2] = $2;
    }
    if ($log =~ /detail(s)?\s*=\s*(\d+)/i) {
      $$params[3] = $2;
    }
  }

  my($self) = $class->SUPER::new(@$params);

  $self->{'line_number'} = 0;
  $self->{'include'}     = $inc;

  return $self;
}


sub strip_line {
  my($self) = shift;
  my($line) = shift;

  ++$self->{'line_number'};
  $line =~ s/\/\/.*//;
  $line =~ s/^\s+//;
  $line =~ s/\s+$//;

  return $line;
}


sub preprocess_line {
  #my($self) = shift;
  #my($fh)   = shift;
  #my($line) = shift;
  return $_[0]->strip_line($_[2]);
}


sub read_file {
  my($self)        = shift;
  my($input)       = shift;
  my($cache)       = shift;
  my($ih)          = new FileHandle();
  my($status)      = 1;
  my($errorString) = undef;

  $self->{'line_number'} = 0;
  if (open($ih, $input)) {
    if ($cache) {
      ## If we don't have an array for this file, then start one
      if (!defined $filecache{$input}) {
        $filecache{$input} = [];
      }

      while(<$ih>) {
        my($line) = $self->preprocess_line($ih, $_);

        ## Push the line onto the array for this file
        push(@{$filecache{$input}}, $line);

        ($status, $errorString) = $self->parse_line($ih, $line);

        if (!$status) {
          last;
        }
      }
    }
    else {
      while(<$ih>) {
        ($status, $errorString) = $self->parse_line(
                                    $ih, $self->preprocess_line($ih, $_));

        if (!$status) {
          last;
        }
      }
    }
    close($ih);
  }
  else {
    $errorString = "Unable to open \"$input\" for reading";
    $status = 0;
  }

  return $status, $errorString;
}


sub cached_file_read {
  my($self)  = shift;
  my($input) = shift;
  my($lines) = $filecache{$input};

  if (defined $lines) {
    my($status) = 1;
    my($error)  = undef;
    $self->{'line_number'} = 0;
    foreach my $line (@$lines) {
      ++$self->{'line_number'};
      ($status, $error) = $self->parse_line(undef, $line);

      if (!$status) {
        last;
      }
    }
    return $status, $error;
  }

  return $self->read_file($input, 1);
}


sub get_line_number {
  my($self) = shift;
  return $self->{'line_number'};
}


sub set_line_number {
  my($self)   = shift;
  my($number) = shift;
  $self->{'line_number'} = $number;
}


sub slash_to_backslash {
  my($self) = shift;
  my($file) = shift;
  $file =~ s/\//\\/g;
  return $file;
}


sub get_include_path {
  my($self) = shift;
  return $self->{'include'};
}


sub search_include_path {
  my($self)  = shift;
  my($file)  = shift;

  foreach my $include ('.', @{$self->{'include'}}) {
    if (-r "$include/$file") {
      return "$include/$file";
    }
  }

  return undef;
}


sub escape_regex_special {
  my($self) = shift;
  my($name) = shift;

  $name =~ s/([\+\-\\\$\[\]\(\)\.])/\\$1/g;
  return $name;
}


# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub parse_line {
  #my($self) = shift;
  #my($ih)   = shift;
  #my($line) = shift;
}


1;
