eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 7/12/2006
#         $Id$
# ******************************************************************

# ******************************************************************
# Pragma Section
# ******************************************************************

use strict;
use FileHandle;
use FindBin;
use File::Spec;
use File::Basename;

my($basePath) = $FindBin::Bin;
if ($^O eq 'VMS') {
  $basePath = File::Spec->rel2abs(dirname($0)) if ($basePath eq '');
  $basePath = VMS::Filespec::unixify($basePath);
}
$basePath = dirname($basePath);
unshift(@INC, $basePath . '/modules');

require ProjectCreator;
require TemplateParser;
require ConfigParser;
require StringProcessor;

# ******************************************************************
# Data Section
# ******************************************************************

my(%keywords) = ();
my(%arrow_op) = ();
my($doc_ext)  = '.txt';
my($version)  = '1.1';

# ******************************************************************
# Subroutine Section
# ******************************************************************

sub setup_keywords {
  my($language) = shift;

  ## Get the main MPC keywords
  my($keywords) = ProjectCreator::getKeywords();
  foreach my $key (keys %$keywords) {
    $keywords{$key} = 1;
  }

  ## Get the MPC valid components
  $keywords = ProjectCreator::getValidComponents($language);
  foreach my $key (keys %$keywords) {
    $keywords{lc($key)} = 1;
  }

  ## Get the pseudo template variables
  my($pjc) = new ProjectCreator();
  $keywords = $pjc->get_command_subs();
  foreach my $key (keys %$keywords) {
    $keywords{$key} = 1;
  }

  ## Get the template function names
  $keywords = TemplateParser::getKeywords();
  foreach my $key (keys %$keywords) {
    $keywords{$key} = 1;
  }

  ## Get the template parser arrow operator keys
  $keywords = TemplateParser::getArrowOp();
  foreach my $key (keys %$keywords) {
    $arrow_op{$key} = 1;
  }
}


sub display_template {
  my($fh)    = shift;
  my($cp)    = shift;
  my($input) = shift;
  my($tkeys) = shift;

  print $fh '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">', "\n",
            "<head>\n",
            "  <title>$input</title>\n",
            "</head>\n",
            "<body>\n",
            "  <h1>$input</h1>\n",
            "  <table border=2 cellspacing=1>\n",
            "    <tr>\n",
            "      <th>Template Variable</th>\n",
            "      <th>Default Value</th>\n",
            "      <th>Description</th>\n",
            "    </tr>\n";
  foreach my $key (sort keys %$tkeys) {
    my($desc) = $cp->get_value($key) || '&nbsp;';
    my($def)  = undef;
    if (defined $$tkeys{$key}) {
      foreach my $ikey (sort keys %{$$tkeys{$key}}) {
        if (defined $def) {
          $def .= ' <b>or</b> ';
        }
        else {
          $def = '';
        }
        $def .= StringProcessor::process_special(undef, $ikey);
      }
    }
    print $fh "    <tr>\n",
              "      <td>$key</td>\n",
              "      <td>", (defined $def ? $def : '&nbsp'), "</td>\n",
              "      <td>$desc</td>\n",
              "    </tr>\n";
  }
  print $fh "  </table>\n",
            "</body>\n";
}


sub usageAndExit {
  print "document_template.pl v$version\n",
        "Usage: ", basename($0), " <template> [<html output> [language]]\n\n",
        "language can be any of the valid language settings for MPC.\n";
  exit(0);
}

# ******************************************************************
# Main Section
# ******************************************************************

my($status)   = 0;
my($fh)       = new FileHandle();
my($input)    = $ARGV[0];
my($output)   = $ARGV[1];
my($language) = $ARGV[2];

if (!defined $input || $input =~ /^-/) {
  usageAndExit();
}

if (!defined $output) {
  $output = $input;
  $output =~ s/\.mpd$//;
  $output .= '.html';
}

if (open($fh, $input)) {
  if (!defined $language) {
    if (index($input, 'vb') != -1) {
      $language = 'vb';
    }
    elsif (index($input, 'csharp') != -1) {
      $language = 'csharp';
    }
    else {
      $language = 'cplusplus';
    }
  }

  my(%template_keys) = ();
  setup_keywords($language);

  my(@foreach) = ();
  my($findex)  = -1;
  while(<$fh>) {
    my($len) = length($_);
    for(my $start = 0; $start < $len;) {
      my($sindex) = index($_, '<%', $start);
      if ($sindex >= 0) {
        my($eindex) = index($_, '%>', $sindex);
        if ($eindex >= $sindex) {
          $eindex += 2;
        }
        else {
          $eindex = $len;
        }

        my($part)  = substr($_, $sindex, $eindex - $sindex);
        my($key)   = lc(substr($part, 2, length($part) - 4));
        my($name)  = $key;
        my($tvar)  = undef;
        my($def)   = undef;
        if ($key =~ /^([^\(]+)\((.*)\)/) {
          $name = $1;
          my($vname) = $2;

          if (defined $keywords{$name}) {
            $tvar = 1;
            if ($name eq 'foreach') {
              ++$findex;

              my($remove_s) = 1;
              if ($vname =~ /([^,]*),(.*)/) {
                my($n) = $1;
                my($v) = $2;
                $n =~ s/^\s+//;
                $n =~ s/\s+$//;
                $v =~ s/^\s+//;
                $v =~ s/\s+$//;

                if ($n =~ /^\d+$/) {
                  $n = $v;
                }
                else {
                  $remove_s = undef;
                }
                $vname = $n;
              }

              $name = $vname;

              $key = $vname;
              $vname =~ s/\s.*//;
              $vname =~ s/s$// if ($remove_s);

              $foreach[$findex] = $vname;
              $tvar = undef;
            }
            elsif ($name eq 'if') {
              $vname =~ s/(flag_overrides\(.*\)|!|&&|\|\|)//g;
              if ($vname !~ /^\s*$/) {
                $name = $vname;
                $key  = $vname;
                $tvar = undef;
              }
            }
          }
          else {
            $def = $2;
          }
        }

        my($otvar) = $tvar;
        foreach my $k (split(/\s+/, $key)) {
          $tvar = $otvar;
          if (defined $keywords{$k}) {
            $tvar = 1;
            if ($k eq 'endfor') {
              $foreach[$findex] = undef;
              --$findex;
            }
          }
          else {
            foreach my $ao (keys %arrow_op) {
              if ($k =~ /^$ao/) {
                $tvar = 1;
                last;
              }
            }
          }

          if (!$tvar) {
            for(my $index = 0; $index <= $findex; $index++) {
              if ($foreach[$index] eq $k) {
                $tvar = 1;
                last;
              }
            }
          }

          if (!$tvar) {
            foreach my $n (split(/\s+/, $name)) {
              $tvar = undef;
              if (defined $keywords{$n}) {
              }
              else {
                foreach my $ao (keys %arrow_op) {
                  if ($n =~ /^$ao/) {
                    $tvar = 1;
                    last;
                  }
                }
                if (!$tvar) {
                  if (defined $template_keys{$n}) {
                    if (defined $def) {
                      $template_keys{$n}->{$def} = 1;
                    }
                  }
                  else {
                    $template_keys{$n} = {};
                    if (defined $def) {
                      $template_keys{$n}->{$def} = 1;
                    }
                  }
                }
              }
            }
          }
        }
        $start = $eindex;
      }
      else {
        $start += ($len - $start);
      }
    }
  }
  close($fh);

  my($cp) = new ConfigParser();
  my($doc) = basename($input);
  $doc =~ s/\.[^\.]+$/$doc_ext/;
  $cp->read_file("$basePath/docs/templates/common$doc_ext");
  $cp->read_file("$basePath/docs/templates/$doc");

  if (open($fh, ">$output")) {
    display_template($fh, $cp, $input, \%template_keys);
    close($fh);
  }
  else {
    print STDERR "ERROR: Unable to open $output for writing\n";
    ++$status;
  }
}
else {
  print STDERR "ERROR: Unable to open $input for reading\n";
  ++$status;
}

exit($status);

