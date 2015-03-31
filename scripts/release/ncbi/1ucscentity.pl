#!/usr/local/bin/perl  -w
use strict;

use lib '/usr/local/gkb/modules';
use lib "$ENV{HOME}/bioperl-1.0";
#use lib "$ENV{HOME}/GKB/modules";
use GKB::ClipsAdaptor;
use GKB::DBAdaptor;
use Data::Dumper;
use Getopt::Long;

my $count =0;
my $count1 =0;

our ( $opt_user, $opt_host, $opt_pass, $opt_port, $opt_db);
(@ARGV)  || die "Usage: $0 -user db_user -host db_host -pass db_pass -port db_port -db db_name\n";
&GetOptions( "user:s", "host:s", "pass:s", "port:i", "db:s");
$opt_db  || die "Need database name (-db).\n";

my ($num) = $opt_db =~ /(\d+)/;

my $entity_base_url = "http://www.reactome.org/content/query?q=UniProt:";
my $event_base_url = "http://www.reactome.org/PathwayBrowser/#";

my $archive = 'archive/';
my $out_put = $archive . 'ucsc_errorfile.txt';

my $out_put2 = $archive . 'ucsc_events'.$num;

my $out_put3 = $archive . 'ucsc_entity'.$num;

open (OUTPUT, ">$out_put");

open (OUTPUT2, ">$out_put2"); 

open (OUTPUT3, ">$out_put3");

print OUTPUT2  "URL for events: $event_base_url\n\n";

print OUTPUT2  "Reactome Entity\tEvent ST_ID\tEvent_name\n\n";

print OUTPUT3 "URL for entity_identifier: $entity_base_url\n\n";

print OUTPUT3  "Reactome Entity\n\n";


my @out_classes = ('Event');


my %hash;

my $dbid;

my $dba = GKB::DBAdaptor->new(
     -dbname => $opt_db,
     -user   => $opt_user,
     -host   => $opt_host, # host where mysqld is running
     -pass   => $opt_pass,
     -port   =>  3306
);

# gets Entrez Gene
    
my $gene_db = $dba->fetch_instance_by_attribute('ReferenceDatabase', [['name', ['UniProt']]]) ||  die("No ReferenceDatabase with name 'UniProt'.\n");
    
#print Dumper( $gene_db);

#print $gene_db->[0]->db_id."\n";


my $s =0;
my @input;
my %test;
my $species;
my $xy =0;

my $protein_class = &GKB::Utils::get_reference_protein_class($dba);

my $gp = $dba->fetch_instance($protein_class, [['referenceDatabase',[$gene_db->[0]->db_id]]]);

foreach (@{$gp}){
   
   my $sp = $gp->[$s]->species->[0]->_displayName->[0];
   
   #print $sp."\n";
   
   if ($sp =~ /Homo|Rattus|Mus/){
      push (@input,$gp->[$s]->Identifier->[0]."\n");      
      print OUTPUT3 $gp->[$s]->identifier->[0]."\t". get_stable_identifier($gp->[$s])."\n";
   }else{
      $xy++;
   }
   $s++;
} 

my $l = @input;
 
#To get a list of proteins, print this array to another output file

print "Total number of proteins:".$l."\n";
print "Second step starts now\n";

my $sdi;
my $sdis;
my $entity = "Reactome Entity:";
my $event = "Reactome Event:";
my $tag2 = "Reactome ST_ID:";

foreach (@input) { s/\s//g;}

   $sdis = $dba->fetch_instance(-CLASS => $protein_class,
				-QUERY => [{-ATTRIBUTE => 'identifier',
                                -VALUE => \@input                                          
                                }]);
#print $_."===>x"."\n";				  
				  


   my %instructions = (-INSTRUCTIONS =>
		    {
			$protein_class => {'reverse_attributes' => [qw(referenceEntity referenceSequence)]},
			'PhysicalEntity' => {'reverse_attributes' => [qw(hasComponent hasMember hasCandidate input output physicalEntity)]},
			'CatalystActivity' => {'reverse_attributes' =>[qw(catalystActivity regulator)]},
			'Event' => {'reverse_attributes' =>[qw(hasComponent hasMember hasEvent)]}
		    },
		    -OUT_CLASSES => \@out_classes
		    );

foreach $sdi (@{$sdis}) {
   unless ($sdi->Identifier->[0]) {
	print STDERR $sdi->extended_displayName . " has no identifier!\n";
	next;
    }
    
	 
   my $str;
   # print "====>".$sdi->Identifier->[0]."\n";

    my $ar = $sdi->follow_class_attributes(%instructions);

   if (@{$ar}) {
       @{$ar} = grep {! @{$_->reverse_attribute_value('hasInstance')}} grep {! @{$_->reverse_attribute_value('hasComponent')}} @{$ar};
   }
       
   if (@{$ar}){	 
	 
      my $label = 'reactions';
      my @pathways = grep {$_->is_a('Pathway')} @{$ar};
      my @reactions = grep {$_-> is_a('Reaction')} @{$ar};
	   
      if(@reactions){
   	 @{$ar} = @reactions;
		 
		#foreach(@{$ar}){
	 if (@{$ar} == 1) {
	    $str = $ar->[0]->Name->[0];
	 	
	    fix_name($str);

	    print OUTPUT2 $sdi->Identifier->[0]."\t";
	 	
	    print OUTPUT2 get_stable_identifier($ar->[0])."\t";
		 
	    print OUTPUT2 "$str\n";
	   	
	   	
		 
	 } else{
	      
            my $p = 0;
	       
	    foreach(@{$ar}){  
	    	
	       $str = $ar->[$p]->Name->[0];
		 
		 
	       fix_name($str);

	       print OUTPUT2 $sdi->Identifier->[0]."\t";
	 
	       print OUTPUT2 get_stable_identifier($ar->[$p])."\t"; 
		
	       print OUTPUT2 "$str\n";
		 
	        
	       $p++; 
	       
	    }		
	 }
      }
		
	 
      if(@pathways){
         @{$ar} = @pathways;
         if (@{$ar} == 1) {
	    $str = $ar->[0]->Name->[0];
   	       
	    fix_name($str);
   
	    print OUTPUT2  $sdi->Identifier->[0]."\t";
	 	
	    print OUTPUT2 get_stable_identifier($ar->[0])."\t";
	 	 
	    print OUTPUT2  "$str\n";
	 	 
	 } else{
	      
	    my $p = 0;
	        
	    foreach(@{$ar}){  
	 	   	# use join to have an array of evenly split elements
	       $str =$ar->[$p]->Name->[0];
	    		
	       fix_name($str);
	 			
	       print OUTPUT2 $sdi->Identifier->[0]."\t";
	 	 
	       print OUTPUT2 get_stable_identifier($ar->[$p])."\t"; 
	  	
	       print OUTPUT2 "$str\n";
		  
	       $p++;		     
	    }	
	 }	    	
      }
      $count1++;
   }else{
      print OUTPUT "$entity_base_url",$sdi->Identifier->[0]."\n".$sdi->extended_displayName . " participates in Event(s) but no top Pathway can be found, i.e. there seem to be a pathway which contains or is an instance of itself.\n";
      $count++;
   }
}	
print "Number of entities with events is  ".$count1."\n";
print "Number of not those entities is: ".$xy."\n";
print STDERR  "total no.of errors:$count\n";
      
sub find_top_events {
   my ($events) = @_;
   my @out;
   foreach my $e (@{$events}) {
      @{$e->reverse_attribute_value('hasComponent')} && next;
      @{$e->reverse_attribute_value('hasInstance')} && next;
      push @out, $e;
   }
   return \@out;
}	


sub fix_name{
   my ($str)= @_;
   if ($str =~ /amino acids/){
      $str = "Metabolism of nitrogenous molecules";
   }

   if ($str =~ /Cycle, Mitotic/){
      $str = "Cell Cycle (Mitotic)";
   }
   
   if ($str =~ /L13a-mediated translational/){
      $str = "L13a-mediated translation";
   }

   if ($str =~ /Abortive initiation after/){
      $str = "Abortive initiation";
   }

   if ($str =~ /Formation of the Cleavage and Polyadenylation/){
      $str = "Cleavage and Polyadenylation";
   }

   if ($str =~ /energy metabolism/){
      $str = "Energy Metabolism";
   }
 
   if ($str =~ /sugars/){
      $str = "Metabolism of sugars";
   }
 
   return $str;
}

sub get_stable_identifier {
   my $instance = shift;
   
   return '' unless $instance && $instance->stableIdentifier->[0];
   
   return $instance->stableIdentifier->[0]->identifier->[0];
}
