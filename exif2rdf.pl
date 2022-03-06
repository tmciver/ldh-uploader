=head1 NAME

exif2rdf.pl - Extracts RDF metadata from Exif

=head1 METADATA

@prefix : <http://purl.org/net/ns/doas#> .
<> a :PerlScript ;
 :title "Extracts RDF metadata from Exif" ;
 :created "2007-12-14" ;
 :release [:revision "0.32"; :created "2007-12-16"] ;
 :author [:name "KANZAKI, Masahide"; :home <http://www.kanzaki.com/> ] ;
 :license <http://creativecommons.org/licenses/by/3.0/> .

=head1 SYNOPSIS

perl exif2rdf.pl <imagefile>

Provide image file path as an argument, then it outputs the resulting RDF/XML to STDOUT. Requires definition file "exif-tags.json" in the same directory.

=cut

use Image::ExifTool;
use JSON;
use strict;

my $imgfile = shift;

##@ global variables
my $json_file = 'exif-tags.json'; # find at <http://www.kanzaki.com/ns/exif-tags.json>
my @target_ifds = ('IFD0','ExifIFD','InteropIFD','GPS','PrintIM');
my $ifd = {
	'ExifIFD' => {'pfx'=>'', 'prop'=>'exif-info', 'class'=>'Exif_IFD'},
	'InteropIFD' => {'pfx'=>'i', 'prop'=>'interop-info', 'class'=>'Interop_IFD'},
	'GPS' => {'pfx'=>'g', 'prop'=>'gps-info', 'class'=>'GPS_IFD'},
	'PrintIM' => {'pfx'=>'p', 'prop'=>'pim-info', 'class'=>'PIM_IFD'}
};
my $ifd_pat = join '|', @target_ifds;
my $res = {};

##@ prepares definition from JSON file
my $js = new JSON;
open IN, $json_file or die "$! $json_file.";
my $exif_prop = $js->decode(join "\n",<IN>);
close IN;

##@ prepares Exif analyzer and read the image file
my $exifTool = new Image::ExifTool;
$exifTool->Options(DateFormat => "%Y-%m-%dT%H:%M:%S", CoordFormat => "%.5f", Unknown => 1);
my $info = $exifTool->ImageInfo($imgfile);

##@ assigns property to each tag
foreach my $tag ($exifTool->GetFoundTags('Group0')){
	##@ find which group (IFD) the tag comes from
	my $group = $exifTool->GetGroup($tag,1);
	next unless($group =~ /^($ifd_pat)$/o);

	##@ get value of the tag
 	my $data = $exifTool->GetValue($tag, 'ValueConv'); #converted machine-readable value
	my $val = $exifTool->GetValue($tag, 'PrintConv'); #human-readable value

	##@ find tag_id for the tag, and corresponding property name
	my $tag_number = $exifTool->GetTagID($tag);
	my $tag_id =  $ifd->{$group}->{'pfx'} . $tag_number; # to distinguish same tag number in different IFD
	my $prop = $exif_prop->{$tag_id}->{'propName'};
	my $proptype = 'Datatype'; #default type

	if($prop){
		##@ if property found in JSON
		if($exif_prop->{$tag_id}->{'values'}){
			##@ if pre-defined value found, it is an ObjectProperty
			if(my $val_resource = $exif_prop->{$tag_id}->{'values'}->{$data}){
				$proptype = 'Object';
				$val = $val_resource;
			}elsif($tag_id == 37121){
				##@ componentsConfiguration is something special (exifTool's ValueConv is not usable at this moment)
				$proptype = 'Object';
			}else{
				$proptype = 'unknown';
			}
		}elsif($exif_prop->{$tag_id}->{'datatype'}){
			##@ rdf:datatype
			$proptype = $exif_prop->{$tag_id}->{'datatype'};
			
			if($exif_prop->{$tag_id}->{'datatype'} eq '&xsd;decimal'){
				##@ exifTool's ValueConv is not in APEX unit
				if($tag_id == 37377){
					$data = -log($data)/log(2) ;
				}elsif($tag_id == 37378 or $tag_id == 37381){
					$data = 2 * log($data)/log(2);
				}
				#$val = sprintf("%.2f", $data);
				$val = $data;
			}
		}

	}else{
		##@ otherwise, it is unknown tag
		$prop = 'exifTag';
	}
	##@ record property name, value and type for later output
	$res->{$group}->{$tag_id} = {'prop' => $prop, 'val' => $val, 'proptype' => $proptype, 'tagnum' => $tag_number};
}

##@ outputs RDF/XML
print <<EOF;
<!DOCTYPE rdf:RDF [
<!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
<!ENTITY exif "http://www.kanzaki.com/ns/exif#">
]>
<rdf:RDF
  xmlns="&exif;"
  xmlns:exif="&exif;"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
>
<foaf:Image rdf:about="$imgfile">
EOF

##@ for each target IFD
foreach my $i (@target_ifds){
	next unless($res->{$i});
	my $indent = '';
	##@ if IFD is other than IFD0, make it a child node of IFD0 (image itself)
	if($ifd->{$i}->{'prop'}){
		print " <$ifd->{$i}->{'prop'}>\n  <$ifd->{$i}->{'class'}>\n";
		$indent = '  ';
	}
	##@ proc each property in the IFD
	foreach my $tagid (keys %{$res->{$i}}){
		&print_elt($res->{$i}->{$tagid}, $indent);
	}
	print "  </$ifd->{$i}->{'class'}>\n </$ifd->{$i}->{'prop'}>\n" if($ifd->{$i}->{'prop'});
}
print "</foaf:Image>\n</rdf:RDF>\n";



##@ prints an property element according to its type
sub print_elt{
	my $ref = shift;
	my $indent = shift;

	if($ref->{'proptype'} eq 'unknown'){
		print qq( $indent<$ref->{'prop'} exif:unknownValue="&exif;$ref->{'val'}"/>\n);
	}elsif($ref->{'prop'} eq 'exifTag'){
		print qq( $indent<$ref->{'prop'} exif:tagNumer="$ref->{'tagnum'}" exif:value="$ref->{'val'}"/>\n);
	}elsif($ref->{'proptype'} eq 'Object'){
		print qq( $indent<$ref->{'prop'} rdf:resource="&exif;$ref->{'val'}"/>\n);
	}elsif($ref->{'proptype'} =~ /^&/){
		print qq( $indent<$ref->{'prop'} rdf:datatype="$ref->{'proptype'}">$ref->{'val'}</$ref->{'prop'}>\n);
	}else{
		print qq( $indent<$ref->{'prop'}>$ref->{'val'}</$ref->{'prop'}>\n);
	}
}
