#!/usr/bin/perl

use autodie;
use strict;
use warnings;

use File::Slurp;
use Archive::Zip;
use LWP::UserAgent;

my $userAgent = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0});
$userAgent->agent("reshade-on-unix/0.1");
$userAgent->show_progress(1);

sub reShadeVersion {
    my $req = HTTP::Request->new(GET => "https://api.github.com/repos/crosire/reshade/tags");
    my $response = $userAgent->request($req);
    $response->is_success or die $response->status_line;
    my ($version) = $response->decoded_content =~ /v([\d.]+)/ 
        or die "Could not extract version info";
    return $version;
}

sub downloadFile {
    my $url = $_[0];
    my $file = $_[1];
    my $req = HTTP::Request->new(GET => $url);
    my $response = $userAgent->request($req, $file);
    $response->is_success or die $response->status_line;
}

sub getGamePath {
    if (defined $ARGV[0]) {
        if (-d $ARGV[0]) {
            return $ARGV[0]
        }
        else {
            print "Supplied argument [${ARGV[0]}] is not a valid directory!\n"
        }
    }
    if ($^O eq "darwin") {
        my $xomGamePath = `defaults read dezent.XIV-on-Mac GamePath`;
        chomp $xomGamePath;
        $xomGamePath = $xomGamePath . "/game/";
        if (-d $xomGamePath) {
            return $xomGamePath;
        }
    }
    print "Please enter the directory ReShade should be installed into: ";
    my $path = <STDIN>;
    chomp $path;
    if (-d $path) {
        return $path;
    }
    die "Provided path [${path}] is not a folder!"
}

my $gamePath = getGamePath;
print "Installing ReShade into: [${gamePath}]\n";

my $reshadeSetup = $gamePath . "reshade_setup.exe";
downloadFile("https://reshade.me/downloads/ReShade_Setup_" . reShadeVersion . "_Addon.exe", $reshadeSetup);
my $exeContent = read_file $reshadeSetup;
unlink $reshadeSetup;

my $magicBytes = pack "CC", 0x50, 0x4b, 0x03, 0x04;
my $zipOffset = index $exeContent, $magicBytes;
my $zipContent = substr $exeContent, $zipOffset;
my $reshadeZip = $gamePath . "reshade.zip";
write_file($reshadeZip, $zipContent);
my $zip = Archive::Zip->new($reshadeZip);
$zip->extractMember("ReShade64.dll", $gamePath . "dxgi.dll");
unlink $reshadeZip;

downloadFile("https://lutris.net/files/tools/dll/d3dcompiler_47.dll", $gamePath . "d3dcompiler_47.dll");
