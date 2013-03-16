
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A Perl debugger implemented as a REST service and accompanying browser program",
  "AUTHOR" => "Anthony Brummett <brummett\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Temp" => 0,
    "IO::Socket" => 0,
    "Test::More" => 0,
    "Time::HiRes" => 0,
    "WWW::Mechanize" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Devel-hdb",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Devel::hdb",
  "PREREQ_PM" => {
    "HTTP::Server::PSGI" => 0,
    "IO::File" => 0,
    "IO::Socket::INET" => 0,
    "JSON" => 0,
    "PadWalker" => 0,
    "Plack::Request" => 0,
    "Scalar::Util" => 0,
    "Socket" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



