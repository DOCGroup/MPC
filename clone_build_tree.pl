eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 4/8/2004
#         $Id$
# Description: Clone a build tree into an alternate location.
#              This script is a rewrite of create_ace_build.pl and
#              does not restrict the user to place the build
#              in any particular location or that it be used with
#              ACE_wrappers.  Some of the functions were barrowed
#              from create_ace_build.pl, but were modified quite a
#              bit.
# ******************************************************************

# ******************************************************************
# Pragma Section
# ******************************************************************

use strict;
use Cwd;
use FileHandle;
use File::Copy;
use File::Find;
use File::Path;
use File::stat;
use File::Basename;

# ******************************************************************
# Data Section
# ******************************************************************

my($version)    = '0.1';
my($exclude)    = undef;
my($verbose)    = 0;
my(@foundFiles) = ();

# ******************************************************************
# Subroutine Section
# ******************************************************************

sub findCallback {
  my($matches) = !(/^CVS\z/s && ($File::Find::prune = 1)            ||
                   defined $exclude &&
                   /^$exclude\z/s && ($File::Find::prune = 1)       ||
                   /^build\z/s && ($File::Find::prune = 1)          ||
                   /^\..*obj\z/s && ($File::Find::prune = 1)        ||
                   /^Templates\.DB\z/s && ($File::Find::prune = 1)  ||
                   /^Debug\z/s && ($File::Find::prune = 1)          ||
                   /^Release\z/s && ($File::Find::prune = 1)        ||
                   /^Static_Debug\z/s && ($File::Find::prune = 1)   ||
                   /^Static_Release\z/s && ($File::Find::prune = 1)
                  );

  if ($matches) {
    $matches &&= (! -l $_           &&
                  ! /^core\z/s      &&
                  ! /^.*\.state\z/s &&
                  ! /^.*\.so\z/s    &&
                  ! /^.*\.[oa]\z/s  &&
                  ! /^.*\.dll\z/s   &&
                  ! /^.*\.lib\z/s   &&
                  ! /^.*\.obj\z/s   &&
                  ! /^.*~\z/s       &&
                  ! /^\.\z/s        &&
                  ! /^\.#.*\z/s     &&
                  ! /^.*\.log\z/s
                 );

    if ($matches) {
      $matches = (! /^.*\.dsp\z/s       &&
                  ! /^.*\.dsw\z/s       &&
                  ! /^.*\.vcproj\z/s    &&
                  ! /^.*\.sln\z/s       &&
                  ! /^Makefile.*\z/s    &&
                  ! /^GNUmakefile.*\z/s &&
                  ! /^.*\.am\z/s        &&
                  ! /^\.depend\..*\z/s  &&
                  ! /^.*\.vcn\z/s       &&
                  ! /^.*\.vcp\z/s       &&
                  ! /^.*\.vcw\z/s       &&
                  ! /^.*\.vpj\z/s       &&
                  ! /^.*\.vpw\z/s       &&
                  ! /^.*\.cbx\z/s       &&
                  ! /^.*\.bpgr\z/s      &&
                  ! /^.*\.bmak\z/s      &&
                  ! /^.*\.bmake\z/s     &&
                  ! /^.*\.mak\z/s       &&
                  ! /^.*\.nmake\z/s     &&
                  ! /^.*\.bld\z/s       &&
                  ! /^.*\.icc\z/s       &&
                  ! /^.*\.icp\z/s       &&
                  ! /^.*\.ncb\z/s       &&
                  ! /^.*\.opt\z/s       &&
                  ! /^.*\.bak\z/s       &&
                  ! /^.*\.ilk\z/s       &&
                  ! /^.*\.pdb\z/s
                );

      if ($matches) {
        ## Remove the beginning dot slash and save the file
        my($file) = $File::Find::name;
        $file =~ s/^\.[\\\/]+//;
        push(@foundFiles, $file);
      }
    }
  }
}


sub getFileList {
  File::Find::find({wanted => \&findCallback}, '.');
  return \@foundFiles;
}


sub backupAndMoveModified {
  my($realpath) = shift;
  my($linkpath) = shift;
  my($mltime)   = -M $linkpath;
  my($mrtime)   = -M $realpath;
  my($status)   = 1;

  ## -M returns the number of days since modification.  Therefore,
  ## a smaller time means that it has been modified more recently.
  ## This is different than what stat() returns.
  if ($mltime < $mrtime) {
    $status = 0;

    ## Move the real file to a backup
    if (rename($realpath, "$realpath.bak")) {
      ## Move the linked file to the real file name
      if (move($linkpath, $realpath)) {
        $status = 1;
      }
      else {
        ## The move failed, so we will attempt to put
        ## the original file back.
        unlink($realpath);
        rename("$realpath.bak", $realpath);
      }
    }
  }
  elsif ($mltime != $mrtime) {
    $status = 0;
  }
  elsif (-s $linkpath != -s $realpath) {
    $status = 0;
  }

  if (!$status) {
    ## We were not able to properly deal with this file.  We will
    ## attempt to preserve the modified file.
    rename($linkpath, "$linkpath.bak");
  }
}


sub hardlink {
  my($realpath) = shift;
  my($linkpath) = shift;

  if ($^O eq 'MSWin32' && ! -e $realpath) {
    ## If the real file "doesn't exist", then we need to
    ## look up the short file name.
    my($short) = Win32::GetShortPathName($realpath);

    ## If we were able to find the short file name, then we need to
    ## try again.
    if (defined $short) {
      $realpath = $short;
    }
    else {
      ## This should never happen, but there appears to be a bug
      ## with the underlying Win32 APIs on Windows Server 2003.
      ## Long paths will cause an error which perl will ignore.
      ## Unicode versions of the APIs seem to work fine.
      ## To experiment try Win32 _fullpath() and CreateHardLink with
      ## long paths.
      print "WARNING: Skipping $realpath.\n";
      return 1;
    }
  }

  return link($realpath, $linkpath);
}


sub symlinkFiles {
  my($files)     = shift;
  my($fullbuild) = shift;
  my($dmode)     = shift;
  my($startdir)  = shift;
  my($absolute)  = shift;
  my($sdlength)  = length($startdir) + 1;
  my($partial)   = ($absolute ? undef :
                                substr($fullbuild, $sdlength,
                                       length($fullbuild) - $sdlength));

  foreach my $file (@$files) {
    my($fullpath) = "$fullbuild/$file";
    if (-e $fullpath) {
      ## We need to make sure that we're not attempting to mix hardlinks
      ## and softlinks.
      if (! -d $fullpath && ! -l $fullpath) {
        my($stat) = stat($fullpath);
        if ($stat->nlink() > 1) {
          print STDERR "ERROR: Attempting to mix softlinks ",
                       "with a hardlink build.\n";
          return 1;
        }
      }
    }
    else {
      if (-d $file) {
        if ($verbose) {
          print "Creating $fullpath\n";
        }
        if (!mkpath($fullpath, 0, $dmode)) {
          return 1;
        }
      }
      else {
        if ($absolute) {
          if ($verbose) {
            print "symlink $startdir/$file $fullpath\n";
          }
          if (!symlink("$startdir/$file", $fullpath)) {
            return 1;
          }
        }
        else {
          my($buildfile) = "$partial/$file";
          my($slashcount) = ($buildfile =~ tr/\///);
          my($real) = ($slashcount == 0 ? './' : ('../' x $slashcount)) .
                      $file;
          if ($verbose) {
            print "symlink $real $fullpath\n";
          }
          if (!symlink($real, $fullpath)) {
            return 1;
          }
        }
      }
    }
  }

  ## Remove links that point to non-existant files
  sub lcheck {
    if (-l $_ && ! -e $_) {
      unlink($_);
      if ($verbose) {
        print "Removing $File::Find::dir/$_\n";
      }
    }
  }
  File::Find::find({wanted => \&lcheck}, $fullbuild);

  return 0;
}


sub hardlinkFiles {
  my($files)     = shift;
  my($fullbuild) = shift;
  my($dmode)     = shift;
  my($startdir)  = shift;
  my(@hardlinks) = ();

  foreach my $file (@$files) {
    my($fullpath) = "$fullbuild/$file";
    if (-d $file) {
      if (! -e $fullpath) {
        if ($verbose) {
          print "Creating $fullpath\n";
        }
        if (!mkpath($fullpath, 0, $dmode)) {
          return 1;
        }
      }
    }
    else {
      if (-e $fullpath) {
        ## We need to make sure that we're not attempting to mix hardlinks
        ## and softlinks.
        if (-l $fullpath) {
          print STDERR "ERROR: Attempting to mix hardlinks ",
                       "with a softlink build.\n";
          return 1;
        }
        backupAndMoveModified($file, $fullpath);
      }
      if (! -e $fullpath) {
        if ($verbose) {
          print "hardlink $file $fullpath\n";
        }
        if (!hardlink($file, $fullpath)) {
          return 1;
        }
      }

      ## If we successfully linked the file or it already exists,
      ## we need to keep track of it.
      push(@hardlinks, $file);
    }
  }

  ## Remove links that point to non-existant files
  my($lfh) = new FileHandle();
  my($txt) = "$fullbuild/clone_build_tree.links";
  if (open($lfh, "$txt")) {
    while(<$lfh>) {
      my($line) = $_;
      $line =~ s/\s+$//;
      if (! -e $line) {
        unlink("$fullbuild/$line");
        if ($verbose) {
          print "Removing $fullbuild/$line\n";
        }
      }
    }
    close($lfh);
  }

  ## Rewrite the link file.
  unlink($txt);
  if (open($lfh, ">$txt")) {
    foreach my $file (@hardlinks) {
      print $lfh "$file\n";
    }
    close($lfh);
  }

  return 0;
}


sub linkFiles {
  my($absolute)  = shift;
  my($dmode)     = shift;
  my($hardlink)  = shift;
  my($builddir)  = shift;
  my($builds)    = shift;
  my($status)    = 0;
  my($starttime) = time();
  my($startdir)  = getcwd();

  ## Ensure that the build directory exists and is writable
  mkpath($builddir, 0, $dmode);
  if (! -d $builddir || ! -w $builddir) {
    return 1;
  }

  ## Search for the clonable files
  print "Searching $startdir for files...\n";
  my($files) = getFileList();
  print "Found $#foundFiles files and directories.\n";

  foreach my $build (@$builds) {
    my($fullbuild) = "$builddir/$build";

    ## Create all of the links for this build
    print "Creating or updating in $fullbuild\n";
    mkpath($fullbuild, 0, $dmode);
    if ($hardlink) {
      $status += hardlinkFiles($files, $fullbuild, $dmode, $startdir);
    }
    else {
      $status += symlinkFiles($files, $fullbuild,
                              $dmode, $startdir, $absolute);
    }
    print "Finished in $fullbuild\n";
  }

  if ($status == 0) {
    print "Total time: ", time() - $starttime, " seconds.\n";
  }

  return $status;
}


sub usageAndExit {
  my($msg) = shift;
  if (defined $msg) {
    print STDERR "$msg\n";
  }
  my($base) = basename($0);
  my($spc)  = ' ' x (length($base) + 8);
  if ($^O eq 'MSWin32') {
    print STDERR "$base v$version\n",
                 "Usage: $base [-b <builddir>] [-l] [-v] ",
                 "[build names...]\n\n",
                 "-b  Set the build directory. It defaults to the ",
                 "<current directory>/build.\n",
                 "-v  Enables verbose mode.\n";
  }
  else {
    print STDERR "$base v$version\n",
                 "Usage: $base [-a] [-b <builddir>] [-d <dmode>] ",
                 "[-l] [-v]\n",
                 $spc, "[build names...]\n\n",
                 "-a  Use absolute paths when creating soft links.\n",
                 "-b  Set the build directory. It defaults to the ",
                 "<current directory>/build.\n",
                 "-d  Set the directory permissions mode.\n",
                 "-l  Use hard links instead of soft links.\n",
                 "-v  Enables verbose mode.\n";
  }
  exit(0);
}


# ******************************************************************
# Main Section
# ******************************************************************

my($dmode)    = 0777;
my($absolute) = 0;
my($hardlink) = ($^O eq 'MSWin32');
my($builddir) = getcwd() . '/build';
my(@builds)   = ();

for(my $i = 0; $i <= $#ARGV; ++$i) {
  if ($ARGV[$i] eq '-a') {
    $absolute = 1;
  }
  elsif ($ARGV[$i] eq '-b') {
    ++$i;
    if (defined $ARGV[$i]) {
      $builddir = $ARGV[$i];

      ## Convert backslashes to slashes
      $builddir =~ s/\\/\//g;

      ## Remove trailing slashes
      $builddir =~ s/\/+$//;

      ## Remove duplicate slashes
      while($builddir =~ s/\/\//\//g) {
      }
    }
    else {
      usageAndExit('-b requires an argument');
    }
  }
  elsif ($ARGV[$i] eq '-d') {
    ++$i;
    if (defined $ARGV[$i]) {
      $dmode = $ARGV[$i];
    }
    else {
      usageAndExit('-d requires an argument');
    }
  }
  elsif ($ARGV[$i] eq '-l') {
    $hardlink = 1;
  }
  elsif ($ARGV[$i] eq '-v') {
    $verbose = 1;
  }
  elsif ($ARGV[$i] =~ /^-/) {
    usageAndExit('Unknown option: ' . $ARGV[$i]);
  }
  else {
    push(@builds, $ARGV[$i]);
  }
}

if (index($builddir, getcwd()) == 0) {
  $exclude = substr($builddir, length(getcwd()) + 1);
  $exclude =~ s/([\+\-\\\$\[\]\(\)\.])/\\$1/g;
}
else {
  $absolute = 1;
}

if (!defined $builds[0]) {
  my($cwd) = getcwd();
  if (chdir($builddir)) {
    @builds = glob("*");
    chdir($cwd);
  }
  else {
    usageAndExit('There are no builds to update.');
  }
}

exit(linkFiles($absolute, $dmode, $hardlink, $builddir, \@builds));
