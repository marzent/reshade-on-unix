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
    my $req = HTTP::Request->new(GET => "https://reshade.me");
    my $response = $userAgent->request($req);
    $response->is_success or die $response->status_line;
    my ($version) = $response->decoded_content =~ /ReShade_Setup_([\d.]+)\.exe/
        or die "Could not extract version info";
    return $version
}

sub downloadFile {
    my $url = $_[0];
    my $file = $_[1];
    my $req = HTTP::Request->new(GET => $url);
    my $response = $userAgent->request($req, $file);
    $response->is_success or die $response->status_line;
}

# TODO: make this non-XOM specific in the future
my $gamePath = `defaults read dezent.XIV-on-Mac GamePath`;
$gamePath =~ s/\s+$//;
$gamePath = $gamePath . "/game/";


my $reshadeSetup = $gamePath . "reshade_setup.exe";
downloadFile("http://static.reshade.me/downloads/ReShade_Setup_" . reShadeVersion . "_Addon.exe", $reshadeSetup);

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
