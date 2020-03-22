use Net::IRC;

my $protect_chat=0;
my $naive_audience=0;
my %characters=();
my %present=();
my %concealed=();
my %graveyard=();
my %defeated=();
my $lastsave=time();
my %lcnames=();
my $keep_log=1;
my $verbose=0;
my $mimicking='';

srand();

my $beng_nick='DDA';
my $channel='#DarkDragons';
my $server='phase.matrix-chat.net';
my $port=6667;

my @errors=();

while(@ARGV){
	my $arg=shift @ARGV;
	if($arg eq '-server'){
		$server=shift @ARGV;
	}elsif($arg eq '-channel'){
		$channel=shift @ARGV;
	}elsif($arg eq '-port'){
		$port=shift @ARGV;
	}elsif($arg eq '-nick'){
		$nick=shift @ARGV;
	}elsif($arg eq '-naive'){
		$naive_users=1;
	}elsif($arg eq '-chat'){
		$protect_chat=1;
	}elsif($arg eq '-nolog'){
		$keep_log=0;
	}elsif($arg eq '-verbose'){
		$verbose=1;
	}else{
		push @errors, "Invalid argument: $arg\n";
	}
}

if(!$beng_nick){
	push @errors, "Specified nick ($beng_nick) is invalid.\n";
}

if(!$channel){
	push @errors, "Specified channel ($channel) is invalid.\n";
}

if($server eq ''){
	push @errors, "You must specify a server with '-server [URL]'.\n";
}

if($channel eq ''){
	push @errors, "You must specify a channel with '-channel [CHANNEL]'.\n";
}

if(@errors){
	print STDERR @errors;
	exit(1);
}

if($keep_log){
	open LOG, ">>LOG.DDA";
}

sub logprint{
	if($verbose){
		print @_;
	}
	if($keep_log){
		print LOG @_;
		print @_;
	}
}

my $bold="\2";

my $irc=new Net::IRC;
my $conn= $irc->newconn(
	Nick  => $beng_nick,
	Server  => $server,
	Port    =>  $port,
	Ircname => 'Dark Dragons Advanced.'
);

sub sayto{ my $to=shift;
	foreach(@_){
		$conn->privmsg($to,$_);
		logprint("private($to) $_\n");
	}
}

sub say{ 
	foreach(@_){
		$conn->privmsg($channel,$_);
		logprint("out: $_\n");
	}
}

my %spells=(
#dragons
ancient_fire=>{cost=>'25',damage=>'0',description=>'fire breath hotter then hell.'},
fire_breath=>{cost=>'20',damage=>'0',description=>'fire breath'},
fireblast=>{cost=>'30',damage=>'0',description=>'a blast of fire from the mouth'},
#healing spells
cure=>{cost=>'5',damage=>'0',description=>'Cure minor wounds.'},
raise=>{cost=>'50',damage=>'0',description=>'Raise the recently deceased.'},
life=>{cost=>'100',damage=>'0',description=>'Raise any deceased.'},
forced_healing=>{cost=>'50',damage=>'0',description=>'quite speedy healing.'},
reverse_cure=>{cost=>'5',damage=>'0',description=>'Cause minor wounds.'},
reverse_heal=>{cost=>'10',damage=>'0',description=>'Cause wounds.'},
heal=>{cost=>'10',damage=>'0',description=>'heal wounds.'},
calculated_strike=>{cost=>'10',damage=>'0',description=>'damages.'},
#hiding-finding
sniff=>{cost=>'5',damage=>'0',description=>'FEE FIE FOE FUM.'},
scan=>{cost=>'5',damage=>'0',description=>'Learn about an enemy\'s state.'},
vanish=>{cost=>'5',damage=>'0',description=>'See, yet be unseen.'},
sneak=>{cost=>'10',damage=>'0',description=>'Don\'t mind me, I\'m just not fighting any more.'},
#rbite=>{cost=>'1',damage=>'0',description=>'This venom has been infused with H-band radiation!'},
#monsters/summoners
lame=>{cost=>'1',damage=>'0',description=>'A lame attack.'},
slime=>{cost=>'5',damage=>'0',description=>'A lame slime attack.'},
s_scan=>{cost=>'5',damage=>'0',description=>'Scan Technique only for a summon creature'},

#Mages
flare=>{cost=>'5',damage=>'0',description=>'Fire in its pure glory.'},
shard=>{cost=>'7',damage=>'0',description=>'a shard of ice.'},
bolt=>{cost=>'10',damage=>'0',description=>'a bolt of Electricity.'},
fire=>{cost=>'12',damage=>'0',description=>'a blast of Fire.'},
ice=>{cost=>'14',damage=>'0',description=>'a blast of ice.'},
lightning=>{cost=>'15',damage=>'0',description=>'a blast of Electricity.'},
fire_vortex=>{cost=>'15',damage=>'0',description=>'Fire in a swirling Vortex.'},
freeze=>{cost=>'10',damage=>'0',description=>'Freezes a person.'},
shock=>{cost=>'15',damage=>'0',description=>'shock of electrcity.'},
flaming_rain=>{cost=>'20',damage=>'0',description=>'Firey rain that sets fire to most enemies'},
icy_rain=>{cost=>'25',damage=>'0',description=>'Icy rain that freezes most enemies'},
electrical_rain=>{cost=>'25',damage=>'0',description=>'Electrically-driven rain that shocks most enemies into submission'},

#bards
solumn_song=>{cost=>'5',damage=>'0',description=>'Paralyze your enemies.'},
screech_song=>{cost=>'7',damage=>'0',description=>'An Amazing out of tune song.'},
comfort_song=>{cost=>'7',damage=>'0',description=>'A song of comfort that heals.'},
song_of_sorrow=>{cost=>'5',damage=>'0',description=>'a song of pain, that is delt to the target.'},
song_of_passion=>{cost=>'7',damage=>'0',description=>'a passionate love story with Firey romance'},
fright_story=>{cost=>'7',damage=>'0',description=>'A story that can kill.'},
dance_of_death=>{cost=>'5',damage=>'0',description=>'a dance that distracts and damages your target.'},
dance_of_strikes=>{cost=>'7',damage=>'0',description=>'An Amazing dance that alows you to dance around your target striking with relative succession.'},
stormy_story=>{cost=>'7',damage=>'0',description=>'A stormy story of a cold and stormy night'},
romance_story=>{cost=>'10',damage=>'0',description=>'a firey tale of pasionate romance'},
death_song=>{cost=>'15',damage=>'0',description=>'A tale of pain and sorrow'},

#fighters
slash=>{cost=>'2',damage=>'0',description=>'A simple Slash.'},
swift_slashes=>{'4',damage=>'0',description=>'several smooth slashes'},
flame_sword=>{cost=>'5',damage=>'0',description=>'the blade takes a firey aura for more damage in an attack.'},
ice_sword=>{cost=>'6',damage=>'0',description=>'the blade takes a icey aura for more damage in an attack.'},
elect_sword=>{cost=>'8',damage=>'0',description=>'the blade takes an electric charge for more damage in an attack.'},
dark_sword=>{cost=>'10',damage=>'0',description=>'the blade takes on a shadow aura to cause more damage.'},
bright_sword=>{cost=>'10',damage=>'0',description=>'the blade takes a light aura for more damage in an attack.'},
fluid_motion=>{cost=>'15',damage=>'0',description=>'A a fluid furry of slashes.'},
slice=>{cost=>'17',damage=>'0',description=>'A simple slice.'},
energy_slice=>{cost=>'20',damage=>'0',description=>'A glowing slice.'},
steel_glint=>{cost=>'25',damage=>'0',description=>'a glint of steel distracts.'},

#paladins
blessed_blade=>{cost=>'5',damage=>'0',description=>'A Blade blessed by the gods.'},
strike_of_fate=>{cost=>'5',damage=>'0',description=>'the gods deemed this strike necessary.'},
smash=>{cost=>'5',damage=>'0',description=>'a Holy Mace smashing into its target.'},
healthy_aura=>{cost=>'5',damage=>'0',description=>'a holy aura of calming peace.'},
bright_smash=>{cost=>'6',damage=>'0',description=>'the mace is blessed and does more damage'},
holy_strike=>{cost=>'10',damage=>'0',description=>'a strike blessed by the gods.'},
champion_slash=>{cost=>'10',damage=>'0',description=>'a slash blesssed by the gods.'},
champion_charge=>{cost=>'10',damage=>'0',description=>'a charge for the gods.'},
champion_strike=>{cost=>'10',damage=>'0',description=>'a strike blesssed by the gods.'},
holy_smash=>{cost=>'15',damage=>'0',description=>'a smash in the gods name.'},
holy_throw=>{cost=>'20',damage=>'0',description=>'a thrown mace, blessed by the gods.'},

#psychs
mental_blast=>{cost=>'5',damage=>'0',description=>'a blast from ones mind.'},
stop_hitting_yourself=>{cost=>'10',damage=>'0',description=>'takes controll of 1 arm and begins striking the creature with its own arm'},
psi_throw=>{cost=>'15',damage=>'0',description=>'a throw.'},
hold=>{cost=>'50',damage=>'0',description=>'Paralyze your enemies.'},
boulder_throw=>{cost=>'25',damage=>'0',description=>'throw rocks at your enemies.'},
teleport=>{cost=>'70',damage=>'0',description=>'teleport away.'},
knives=>{cost=>'25',damage=>'0',description=>'a throw of knives.'},
force_sleep=>{cost=>'50',damage=>'0',description=>'force a player to sleep'},
mental_alteration=>{cost=>'25',damage=>'0',description=>'makes them forget how much hp they have'},
psi_stab=>{cost=>'30',damage=>'0',description=>'stab them?'},

#berzerks
enrage=>{cost=>'2',damage=>'0',description=>'allows you to rage in combat.'},
pure_rage=>{cost=>'5',damage=>'0',description=>'makes you rage even stronger.'},
blood_rage=>{cost=>'10',damage=>'0',description=>'makes you rage even stronger.'},
grapple=>{cost=>'10',damage=>'0',description=>'it grabs them and pounds them'},
head_butt=>{cost=>'15',damage=>'0',description=>'you hit them with your head.'},
burning_rage=>{cost=>'10',damage=>'0',description=>'makes you rage even stronger.'},
body_slam=>{cost=>'15',damage=>'0',description=>'you hit them with your body.'},
fury=>{cost=>'15',damage=>'0',description=>'you beat them down.'},
burning_fury=>{cost=>'10',damage=>'0',description=>'you beat them down while burning them.'},
electric_grapple=>{cost=>'25',damage=>'0',description=>'grabs and shocks the foe'},
burning_grapple=>{cost=>'25',damage=>'0',description=>'grabs and burns the foe'},
burn_Slam=>{cost=>'25',damage=>'0',description=>'burns the foe as you slam them'},

#archer
long_shot=>{cost=>'1',damage=>'0',description=>'a carefully placed arrow at long range.'},
double_shot=>{cost=>'5',damage=>'0',description=>'2 arrows shot at the same time.'},
fire_shot=>{cost=>'10',damage=>'0',description=>'a fire arrow.'},
ice_shot=>{cost=>'10',damage=>'0',description=>'a Ice arrow.'},
flurry_of_arrows=>{cost=>'20',damage=>'0',description=>'a rain of arrows'},
exploding_arrow=>{cost=>'10',damage=>'0',description=>'an exploding arrow.'},
poison_arrow=>{cost=>'5',damage=>'0',description=>'a poison arrow'},
bow_attack=>{cost=>'10',damage=>'0',description=>'an attack with your bow'},
quick_thinking=>{cost=>'20',damage=>'0',description=>'swift and powerful attack'},
rappid=>{cost=>'20',damage=>'0',description=>'rappid shots'},
phase_shot=>{cost=>'25',damage=>'0',description=>'swift and skillfull'},

#GM
electrocute=>{cost=>'0',damage=>'0',description=>'pure death'},
);

my $last_twink=time();

my @canned_monsters=(slime,slime);


my %classes=(
#monster
#locals
slime=>{user=>0,hp=>20,mp=>2,xp=>20,damage=>3,spells=>{lame=>1}},
wolf=>{user=>0,hp=>30,mp=>5,xp=>75,damage=>5,spells=>{}},
goblin=>{user=>0,hp=>40,mp=>10,xp=>100,damage=>10,spells=>{}},
#orc'
orc_soldier=>{user=>0,hp=>200,mp=>100,xp=>200,damage=>50,spells=>{}},
orc_guard=>{user=>0,hp=>400,mp=>10,xp=>200,damage=>70,spells=>{}},
orc_commander=>{user=>0,hp=>500,mp=>10,xp=>300,damage=>100,spells=>{}},
orc_general=>{user=>0,hp=>500,mp=>10,xp=>400,damage=>120,spells=>{}},
#drow
drow_archer=>{user=>0,hp=>60,mp=>30,xp=>150,damage=>50,spells=>{long_shot=>1,double_shot=>1}},
drow_priestess=>{user=>1,hp=>50,mp=>50,xp=>150,damage=>5,spells=>{flare=>1,shard=>1}},
drow_fighter=>{user=>1,hp=>100,mp=>75,xp=>150,damage=>5,spells=>{slash=>1,swift_slashes=>3,flame_sword=>1,dark_sword=>1}},
#gryphons
elder_gryphon=>{user=>0,hp=>100,mp=>100,xp=>100,damage=>50,spells=>{flare=>1,mental_blast=>1,shard=>1}},
young_gryphon=>{user=>0,hp=>100,mp=>100,xp=>100,damage=>50,spells=>{flare=>1}},
gryphon=>{user=>0,hp=>100,mp=>100,xp=>100,damage=>50,spells=>{flare=>1,mental_blast=>1}},
mother_gryphon=>{user=>0,hp=>200,mp=>100,xp=>100,damage=>50,spells=>{flare=>1}},
#Dragons
grand_dragon=>{user=>0,hp=>500,mp=>100,xp=>500,damage=>50,spells=>{ancient_fire=>1}},
council_dragon=>{user=>0,hp=>300,mp=>100,xp=>400,damage=>50,spells=>{fire_breath=>1}},
red_dragon=>{user=>0,hp=>200,mp=>100,xp=>200,damage=>50,spells=>{fire_breath=>1,fireblast=>1}},
blue_dragon=>{user=>0,hp=>150,mp=>100,xp=>150,damage=>50,spells=>{fire_breath=>1}},
green_dragon=>{user=>0,hp=>150,mp=>100,xp=>150,damage=>50,spells=>{fire_breath=>1}},
drake=>{user=>0,hp=>100,mp=>100,xp=>100,damage=>100,spells=>{}},
#player
mage=>{user=>1,hp=>50,mp=>70,xp=>100,damage=>5,spells=>{flare=>1,shard=>3,bolt=>5,fire=>7,ice=>10,lightning=>12,fire_vortex=>15,shock=>17,freeze=>20,flaming_rain=>22,icy_rain=>25,electrical_rain=>28}},

summoner=>{user=>1,hp=>50,mp=>70,xp=>100,damage=>4,spells=>{}},

bard=>{user=>1,hp=>50,mp=>60,xp=>100,damage=>5,spells=>{screech_song=>1,solumn_song=>3,comfort_song=>5,song_of_sorrow=>7,song_of_passion=>10,fright_story=>12,dance_of_death=>15,dance_of_strikes=>17,stormy_story=>20,romance_story=>22,death_song=>25}},

fighter=>{user=>1,hp=>70,mp=>30,xp=>100,damage=>5,spells=>{slash=>1,swift_slashes=>3,flame_sword=>5,ice_sword=>7,elect_sword=>10,bright_sword=>12,dark_sword=>15,fluid_motion=>17,slice=>20,scan=>21,energy_slice=>22,steel_glint=>25}},

paladin=>{user=>1,hp=>60,mp=>40,xp=>100,damage=>5,spells=>{blessed_blade=>1,strike_of_fate=>3,holy_strike=>5,healthy_aura=>7,smash=>10,bright_smash=>12,champion_slash=>15,champion_charge=>17,champion_strike=>20,holy_smash=>22,holy_throw=>25}},

psionic=>{user=>1,hp=>50,mp=>70,xp=>100,damage=>5,spells=>{mental_blast=>1,scan=>2,stop_hitting_yourself=>5,psi_throw=>7,hold=>10,boulder_throw=>12,force_sleep=>13,teleport=>15,knives=>17,fire_vortex=>20,mental_alteration=>22,psi_stab=>25}},

berzerker=>{user=>1,hp=>80,mp=>20,xp=>100,damage=>5,spells=>{enrage=>1,pure_rage=>3,blood_rage=>5,grapple=>7,head_butt=>10,body_slam=>12,burning_rage=>15,fury=>17,burning_fury=>20,electric_grapple=>22,burning_grapple=>25,burn_slam=>28}},


archer=>{user=>1,hp=>60,mp=>20,xp=>100,damage=>5,spells=>{long_shot=>1,double_shot=>3,fire_shot=>5,ice_shot=>7,flurry_of_arrows=>10,exploding_arrow=>12,poison_arrow=>15,bow_attack=>17,quick_thinking=>20,rappid=>22,phase_shot=>25}},

healer=>{user=>1,hp=>50,mp=>45,xp=>100,damage=>2,spells=>{cure=>1,reverse_cure=>3,scan=>5,heal=>7,reverse_heal=>10,raise=>12,forced_healing=>15,calculated_strike=>17,life=>20}},
);

my %class_aliases=(
mage=>'mage',
summoner=>'summoner',
bard=>'bard',
fighter=>'fighter',
paladin=>'paladin',
psionic=>'psionic',
berzerker=>'berzerker',
archer=>'archer',
healer=>'healer',
);

my %summons=(
slime=>'slime',
drow_priestess=>'s_scan',
red_dragon=>'fireblast',
ancient_dragon=>'ancient_fire',
council_dragon=>'fire_breath'
);


sub summoner_study{my ($student,$subject)=@_;
	if(! exists $characters{$student}){
		return;
	}
	if($characters{$student}->{class} ne summoner){
		sayto($student, "Only a \2summoner\2 can study creatures and learn to summon them.");
		return;
	}
	if($characters{$student}->{isresting}){
		sayto($student, "You're resting.  You can't study while resting.");
		return;
	}
	if(!exists $characters{$subject}){
		sayto($student, "There is no \2$subject\2 to study!");
		return;
	}
	if(!$present{lc($subject)}){
		sayto($student, "You can't study \2$subject\2 when he's away!");
		return;
	}
	my $class=$characters{$subject}->{class};
	if(exists $characters{$student}->{summons}->{$class}){
		sayto($student, "There is nothing to be gained by studying a creature you can already summon.");
		return;
	}
	if($characters{$student}->{delay}<time()){
		say("\2$student\2 tries to study \2$subject\2...");
		if(exists($summons{$class}) && int(rand(4))==1){
			$characters{$student}->{summons}->{$class}=$summons{$class};
			say("and \2$student\2 learns to summon \2$class\2!");
			$characters{$student}->{xp}+=50;
			correct_points($student);
		}else{
			say("but \2$student\2 learns nothing");
		}
		$characters{$student}->{delay}=time()+5;
	}else{
		penalty($student);
	}
}

%special_spells=(
#dragons
fire_breath=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("the large dragon opens its mouth and blasts fire at \2$target\2 for $dmgfact then the fire disapates");
	$characters{$target}->{hp}-=$dmgfact;
},
ancient_fire=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("the grand dragon growls really load and then opens their mouth sending a blast of fire hotter then hell at \2$target\2 for $dmgfact then the fire disapates");
	$characters{$target}->{hp}-=$dmgfact;
},
fireblast=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(50));
	say("the dragon opens its mouth and blasts fire at \2$target\2 for $dmgfact then the fire disapates");
	$characters{$target}->{hp}-=$dmgfact;
},

#archer
quick_thinking=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(150));
	my $dmgfact2 = int(rand(200));
	say("\2$caster\2 nockes their arrow and draws back, aiming, and releasing at \2$target\2 for $dmgfact damage, and then jumps up and kicks the arrow even farther in for $dmgfact2 Damage");
	$characters{$target}->{hp}-=$dmgfact;
	$characters{$target}->{hp}-=$dmgfact2;
},
bow_attack=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(140));
	say("\2$caster\2 swings their bow around and brains \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
poison_arrow=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(135));
	say("\2$caster\2 nockes their arrow and draws back, aiming, and releasing at \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
exploding_arrow=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2 shoots an arrow that explodes on contact to \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
long_shot=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(25));
	say("\2$caster\2 nockes their arrow and draws back, aiming, and releasing at \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
flurry_of_arrows=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2 rappidly fires arrows at \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
double_shot=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	my $dmgfact2 = int(rand(25));
	say("\2$caster\2 fires the two arrows at \2$target\2 the first does $dmgfact Damage and the second does $dmgfact2");
	$characters{$target}->{hp}-=$dmgfact;
	$characters{$target}->{hp}-=$dmgfact2;
},
ice_shot=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2 fires an Ice arrow at \2$target\2 and does $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact
},
fire_shot=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 fires an firey arrow at \2$target\2 and does $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact
},
phase_shot=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(250));
	say("\2$caster\2 fires an arrow at \2$target\2 and it disapears, reapearing in the \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact
},
rappid=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(300));
	say("\2$caster\2 fires off arrows at \2$target\2 and does $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact
},


#berzerker
electric_grapple=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(250));
	say("\2$caster\2 grabs and shocks \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},


burning_grapple=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(280));
	say("\2$caster\2 grabs and burns \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},


burn_slam=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(300));
	say("\2$caster\2 slams on top of \2$target\2 and burns them for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
enrage=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(40));
	say("\2$caster\2 flips out and beats down on \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
pure_rage=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(55));
	say("\2$caster\2 looks emensly calm and then goes into a pure solid rage and thrashes \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
blood_rage=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(55));
	say("\2$caster\2 go red in their blood rage, they cry out and begin laying into \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
grapple=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("\2$caster\2 go red in their rage, they cry out and leap onto grabbing them roughly and beating them \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
head_butt=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2 in their blood rage, they slam their head into \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
body_slams=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2 in their blood rage, they slam their body into \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
burning_rage=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(135));
	say("\2$caster\2 cries out and burns with rage, punching with a single fist, a flash of fire hits \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
fury=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(150));
	say("\2$caster\2 beats on \2$target\2 with a fury of punches and kicks for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
burning_fury=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(170));
	say("\2$caster\2 cries out and burns with rage, punching and kicking rappidly, a flash of fire hits \2$target\2 for each blow landed, dealing $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},

#psionic

force_sleep=>sub {my ($caster, $target)=@_;
	$characters{$target}->{delay}=time()+60;
	$characters{$target}->{isresting}=1;
	say("\2$caster\2 pushes out a hand and a green aura appears around \2$caster\2 and then another one around \2$target\2");
},
mental_blast=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 puts their hands on their temples and fires a green bolt from their head to \2$target\2's head for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
stop_hitting_yourself=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 takes control of the \2$target\2 arm and thrashes them with it for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
psi_throw=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("\2$caster\2's holds out a hand that glows green as their other hand has two fingers on their temple and throws \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
boulder_throw=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2's holds out a hand that glows green as their other hand has two fingers on their temple and throws a boulder at \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
teleport=>sub {my ($caster, $target)=@_;
	delete $present{lc($caster)};
	$concealed{lc($caster)}=1;
	if($caster ne 'monster'){
		$characters{$caster}->{isresting}=1;
		$characters{$caster}->{delay}=time()+60;
		say("\2$caster\2 teleports out of combat");
	}
	return 0;
},
knives=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2's holds out a hand that glows green as their other hand has two fingers on their temple and throws alot of knives at \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
mental_alteration=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(200));
	say("\2$caster\2's holds out a hand that glows green as their other hand has two fingers on their temple and makes \2$target\2 forget $dmgfact HP");
	$characters{$target}->{hp}-=$dmgfact;
},
psi_stab=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(250));
	say("\2$caster\2 uses psionic energy to pull \2$target\2 onto a knife for $dmgfact damage");
	$characters{$target}->{hp}-=$dmgfact;
},


#paladin
blessed_blade=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 stabs \2$target\2 swiftly with their blessed blade for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
strike_of_fate=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(50));
	say("\2$caster\2 realises with startling calmness that \2$target\2 needs to be struck exactly so, as the gods decree necessary, dealing $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
holy_strike=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("\2$caster\2 raises their sword above their head and a beam of light comes down apon them, the blade glows as they strike \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
champion_slash=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2 raises their sword above their head and a beam of light comes down apon them, the blade glows as they slash \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
champion_charge=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("a beam of light comes down apon \2$caster\2, they glow as they charge at and attack \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
champion_strikes=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(150));
	say("\2$caster\2 raises their mace above their head and a beam of light comes down apon them, the blade glows as they smash \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
smash=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 Smashes down on \2$target\2 with a mace for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
healthy_aura=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(50));
	say("\2$caster\2's glowing aura heals \2$target\2 of $dmgfact Damage");
	$characters{$target}->{hp}+=$dmgfact;
},
bright_smash=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(65));
	say("\2$caster\2's mace glows with light as they smash down at \2$target\2 for $dmgfact then ceases to glow");
	$characters{$target}->{hp}-=$dmgfact;
},
holy_smash=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(200));
	say("\2$caster\2's mace glows with a blessed aura as they smash down at \2$target\2 for $dmgfact then ceases to glow");
	$characters{$target}->{hp}-=$dmgfact;
},
holy_throw=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(250));
	say("\2$caster\2 glows as they chunk their mace at \2$target\2 for $dmgfact the mace then springs back into their hand and they cease to glow");
	$characters{$target}->{hp}-=$dmgfact;
},


#fighter
slash=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 slashes at \2$target\2 with a sword for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
slice=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(150));
	say("\2$caster\2 slices at \2$target\2 with a sword for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
fluid_motion=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2 flluidly attacks \2$target\2 with a sword for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
swift_slashes=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 slashes at \2$target\2 with a sword several times for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
elect_sword=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(55));
	say("\2$caster\2's sword is charged with electricity slash at \2$target\2 for $dmgfact then the electricity disapates");
	$characters{$target}->{hp}-=$dmgfact;
},
flame_sword=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2's sword bursts into flames as they slash at \2$target\2 for $dmgfact then the fire disapates");
	$characters{$target}->{hp}-=$dmgfact;
},

ice_sword=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("\2$caster\2's sword chills and glows blue as they slash at \2$target\2 for $dmgfact then the ice disapates");
	$characters{$target}->{hp}-=$dmgfact;
},
dark_sword=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2's sword fades into shadow they slash at \2$target\2 for $dmgfact then the shadow disapates");
	$characters{$target}->{hp}-=$dmgfact;
},
bright_sword=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2's sword glows with light as they slash at \2$target\2 for $dmgfact then ceases to glow");
	$characters{$target}->{hp}-=$dmgfact;
},
energy_slice=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(200));
	say("\2$caster\2 slices at \2$target\2 with a sword of glowing energy for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
steel_glint=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(250));
	say("\2$caster\2 twists his gauntlet to shine a reflection into \2$target\2's eyes and slashes with a sword for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},


#bard
comfort_song=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 glows as they play and heals \2$target\2's wounds of $dmgfact Damage");
	$characters{$target}->{hp}+=$dmgfact;
},
screech_song=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 Sings a song way off key at \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},

song_of_sorrows=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2's sings the song causing \2$target\2 $dmgfact damage");
	$characters{$target}->{hp}-=$dmgfact;
},

song_of_passion=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("\2$caster\2's words heat the air as fire forms around \2$target\2 for $dmgfact then the fire disapates");
	$characters{$target}->{hp}-=$dmgfact;
},
fright_story=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2's sword chill \2$target\2 to the bones for $dmgfact damage");
	$characters{$target}->{hp}-=$dmgfact;
},

dance_of_death=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2 dances out the dance causing \2$target\2 $dmgfact damage");
	$characters{$target}->{hp}-=$dmgfact;
},
dance_of_strikes=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(125));
	say("\2$caster\2 dances around \2$target\2 striking for $dmgfact damage");
	$characters{$target}->{hp}-=$dmgfact;
},

stormy_story=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(150));
	say("\2$caster\2 tells the story, causing lightning and hail on \2$target\2 for $dmgfact damage");
	$characters{$target}->{hp}-=$dmgfact;
},
romance_story=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(200));
	say("\2$caster\2 tells a tale of passionate romance causing \2$target\2 to burst into flames for $dmgfact damage");
	$characters{$target}->(hp)-=$dmgfact;
},


death_song=>sub {my ($caster, $target)=@_;
        my $dmgfact = int(rand(250));
        say("\2$caster\2 tells a tale of pain and sorrow that hurts \2$target\2's soul for $dmgfact damage");
        $characters{$target}->(hp)-=$dmgfact;
},


#summon stuff
slime=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(5));
	say("\2$caster\2 Summons a Slime wich proceeds to flail with magical essince and throws itself against \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},

lame=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(5));
	say("\2$caster\2 flails with magical essince and throws themselves against \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
#mage

flare=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 Raises their hands and shoots fire at \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
shard=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(40));
	say("\2$caster\2 calls forth their energies and forms a shard of ice that is then hurled at \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
bolt=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(25));
	say("\2$caster\2's raises their hands and charges a bolt of electricty and discharges it at \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
fire=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 Raises their hands and raises fire underneath \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
ice=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(70));
	say("\2$caster\2 calls forth their energies and forms a ball of cold that is then hurled at \2$target\2 $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
lightning=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(75));
	say("\2$caster\2's raises their hands and a bolt of electricty strikes \2$target\2 for $dmgfact");
	$characters{$target}->{hp}-=$dmgfact;
},
fire_vortex=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2 Raises their hands fire wraps itself around \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
shock=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(120));
	say("\2$caster\2 calls forth their energies and discharges electricity into \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
flaming_rain=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(220));
	say("\2$caster\2 Raises their hands as a bunch of flames drop fire onto \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},

icy_rain=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(235));
	say("\2$caster\2 Raises their hands as a bunch of icicles drop onto \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},

electrical_rain=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(250));
	say("\2$caster\2 Raises their hands as a bunch of bolts of lightning drop onto \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},

#conceals
sniff=>sub {my ($caster, $target)=@_;
	if(keys %concealed){
		say("\2$caster\2 smells concealed parties!  They are no longer hidden.");
		for(keys %concealed){
			$present{lc($_)}=1;
			delete $concealed{$_};
		}
	}
	return 0;
},
vanish=>sub {my ($caster, $target)=@_;
	delete $present{lc($caster)};
	$concealed{lc($caster)}=1;
	return 0;
},
sneak=>sub {my ($caster, $target)=@_;
	delete $present{lc($caster)};
	$concealed{lc($caster)}=1;
	if($caster ne 'monster'){
		$characters{$caster}->{isresting}=1;
		$characters{$caster}->{delay}=time()+60;
	}
	return 0;
},
#scan
scan=>sub {my ($caster, $target)=@_;
	status($target);
	return 0;
},
s_scan=>sub {my ($caster, $target)=@_;
	say('\2$caster\2 summons up a Drow Priestess to scan \2$target\2');
	status($target);
	return 0;
},
#paralyse
solumn_song=>sub {my ($caster, $target)=@_;
	my $time=int(rand(60)+1);
	if($characters{$target}->{delay} < (time()+9)){
		$characters{$target}->{delay}=time()+$time;
		say("\2$target\2 is paralyzed for \2$time\2 seconds!");
	}else{
		$characters{$target}->{delay}+=$time;
		my $totaldelay=$characters{$target}->{delay}-time();
		if($totaldelay>70){
			$characters{$target}->{delay}=time();
			say("the repition of the song brings \2target\2 out of his paralysis!");
		}else{
			say("\2$target\2 is paralyzed for \2$time\2 more seconds!");
		}
	}
	return 0;
},
hold=>sub {my ($caster, $target)=@_;
	my $time=int(rand(60)+1);
	if($characters{$target}->{delay} < (time()+9)){
		$characters{$target}->{delay}=time()+$time;
		say("\2$target\2 is paralyzed for \2$time\2 seconds!");
	}else{
		$characters{$target}->{delay}+=$time;
		my $totaldelay=$characters{$target}->{delay}-time();
		if($totaldelay>70){
			$characters{$target}->{delay}=time();
			say("\2target\2 slips out of his paralysis!");
		}else{
			say("\2$target\2 is paralyzed for \2$time\2 more seconds!");
		}
	}
	return 0;
},
freeze=>sub {my ($caster, $target)=@_;
	my $time=int(rand(60)+1);
	if($characters{$target}->{delay} < (time()+9)){
		$characters{$target}->{delay}=time()+$time;
		say("\2$target\2 is frozen for \2$time\2 seconds!");
	}else{
		$characters{$target}->{delay}+=$time;
		my $totaldelay=$characters{$target}->{delay}-time();
		if($totaldelay>70){
			$characters{$target}->{delay}=time();
			say("\2target\2 slips out of his icey tomb!");
		}else{
			say("\2$target\2 is frozen for \2$time\2 more seconds!");
		}
	}
	return 0;
},
#healing
calculated_strike=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(100));
	say("\2$caster\2 carefully makes a pinpoint strike to \2$target\2 for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
forced_healing=>sub {my ($caster, $target)=@_;
	if(rand()>0.75){
		say("\2$target\2's body rejects the healing and is forced to their knees");
		cause_damage($target,50);
		return 0;
	}else{
		my $dmgfact = int(rand(100));
		say("\2$caster\2's hands glow and forces \2$target\2 heal $dmgfact Damage");
		$characters{$target}->{hp}+=$dmgfact;
		return 1;
	}
},
heal=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 hands glow as they heal \2$target\2 wounds of $dmgfact Damage");
	$characters{$target}->{hp}+=$dmgfact;
},
reverse_heal=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(60));
	say("\2$caster\2 touches \2$target\2 Causing a major Wound to rip open out of nowhere for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
cure=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 touches one of \2$target\2 wounds to heal $dmgfact Damage");
	$characters{$target}->{hp}+=$dmgfact;
},
reverse_cure=>sub {my ($caster, $target)=@_;
	my $dmgfact = int(rand(30));
	say("\2$caster\2 touches \2$target\2 Causing a Wound to rip open out of nowhere for $dmgfact Damage");
	$characters{$target}->{hp}-=$dmgfact;
},
life=>sub {my ($caster, $target)=@_;
	if(exists $graveyard{$target}){
		resurrect($target);
	}else{
		say("There is no body of \2$target\2 to raise.");
	}
	return 0;
},
raise=>sub {my ($caster, $target)=@_;
	if(exists $graveyard{$target}){
		if((time()-$graveyard{$target}->{delay})<300){
			resurrect($target);
		}else{
			say("Alas!  \2$target\2 has been dead for too long!");
		}
	}else{
		say("There is no body of \2$target\2 to raise.");
	}
	return 0;
},
#rbite=>sub {my ($caster, $target)=@_;
#	if(rand()>0.75){
#		say("\2$target\2 begins to transform into some kind of hideous spider/man cross!");
#		new_character($target,'spider_man',$characters{$target}->{staticid});
#		return 0;
#	}else{
#		cause_damage($target,200);
#		return 1;
#	}
#},
);

sub rand_el{
	return $_[int(rand(scalar(@_)))];
};

my %weird_deaths=(
#canned=>sub{ my ($name,$killer)=@_;
#	my $new_monster=$canned_monsters[int(rand(scalar(@canned_monsters)))];
#	say("You've opened a can of \2$new_monster\2!");
#	new_character('monster', $new_monster, 'impossible!ID@!@!@');
#	return 0;
#},

);

sub new_character{my ($name,$class,$static)=@_;
	clean_grave($static);
	$characters{$name}={
		class=>$class,
		hp=>$classes{$class}->{hp},
		maxhp=>$classes{$class}->{hp},
		mp=>$classes{$class}->{mp},
		maxmp=>$classes{$class}->{mp},
		xp=>0,
		level=>1,
		delay=>time(),
		isresting=>1,
		staticid=>$static,
		frontline=>0,
	};
	if($classes{$class}->{user}){
		say("\2$name\2 becomes a Level 1 \2$class\2!");
	}else{
		say("A \2$class\2 (ID: \2$name\2) appears!");
	}
	learned($name,$class);
	$lcnames{lc($name)}=$name;
	if($class eq 'summoner'){
		$characters{$name}->{summons}={};
	}
}

sub lcname{ my ($name)=@_;
	if(exists $lcnames{lc($name)}){
		return $lcnames{lc($name)};
	}else{
		return $name;
	}
}

sub save_corpse{my $name=shift;
	local *file=shift;
	my $char=$graveyard{$name};
	my $safename=$name;
	$safename=~s/'/\\'/g;
	$safename="'$safename'";
	print SAVEFILE "\$graveyard\{$safename\}=\{\n";
	foreach $key (keys %{$char}){
		if($key ne 'summons'){
			print SAVEFILE "\t$key=>'$char->{$key}',\n";
		}else{
			print SAVEFILE "\t$key=>\{\n";
			for(keys %{$char->{summons}}){
				print SAVEFILE "\t\t$_=>'$char->{summons}->{$_}',\n";
			}
			print SAVEFILE "\t\},\n";
		}
	}
	print SAVEFILE "\};\n";
	print SAVEFILE "\$defeated\{\$graveyard\{$safename\}->\{staticid\}\}=$safename;\n";
}

sub save_character{my $name=shift;
	local *file=shift;
	my $char=$characters{$name};
	my $safename=$name;
	$safename=~s/'/\\'/g;
	$safename="'$safename'";
	print SAVEFILE "\$characters\{$safename\}=\{\n";
	foreach $key (keys %{$char}){
		if($key ne 'summons'){
			print SAVEFILE "\t$key=>'$char->{$key}',\n";
		}else{
			print SAVEFILE "\t$key=>\{\n";
			for(keys %{$char->{summons}}){
				print SAVEFILE "\t\t$_=>'$char->{summons}->{$_}',\n";
			}
			print SAVEFILE "\t\},\n";
		}
	}
	print SAVEFILE "\};\n";
}

sub save{
	open SAVEFILE, ">State.DDA";
	foreach $name (keys %characters){
		save_character($name);
	}
	foreach $name (keys %graveyard){
		save_corpse($name);
	}
	close SAVEFILE;
	$lastsave=time();
	logprint("!!!\nSAVED STATE\n!!!\n");
}

sub load{
	open LOADFILE, "<State.DDA" or return;
	eval(join('',<LOADFILE>));
	close LOADFILE;
	foreach $name (keys %characters){
		$lcnames{lc($name)}=$name;
		if($characters{$name}->{class} eq 'twink'){
			$last_twink=time();
		}
		if(! exists $characters{$name}->{frontline}){
			$characters{$name}->{frontline}=0;
		}
	}
	if(exists $characters{monster}){
		$present{monster}=1;
	}
}

load();

sub learned{ my ($name,$class)=@_;
	foreach $spell (keys %{$classes{$class}->{spells}}){
		if($classes{$class}->{spells}->{$spell} == $characters{$name}->{level}){
			say("\2$name\2 learned \2$spell\2!");
		}
	}
}

sub xp_needed{ my ($name)=@_;
	my $basexp=$classes{$characters{$name}->{class}}->{xp};
	my $level=$characters{$name}->{level};
	my $step=0,$j=0;
	my $factor=0;
	for(my $i=0; $i<$level; $i++){
		if($j++%4==0){$step++}
		$factor+=$step;
	}
	return $basexp*$factor;
}

sub xp_value{ my ($name)=@_;
	return int(xp_needed($name)/2);
}

sub does_hit{ my ($attacker, $defender)=@_;
	my $alevel=$characters{$attacker}->{level};
	my $dlevel=$characters{$defender}->{level};
	if(exists $classes{$characters{$attacker}->{class}}->{hitsas}){
		$alevel=$classes{$characters{$attacker}->{class}}->{hitsas};
	}
	if(exists $classes{$characters{$defender}->{class}}->{hitsas}){
		$dlevel=$classes{$characters{$defender}->{class}}->{hitsas};
	}
	if($characters{$attacker}->{class} =~ /dragon/){
		return 1;
	}
	if($characters{$attacker}->{class} eq 'twink'){
		return 1;
	}
	if($characters{$defender}->{class} eq 'bard'){
		return 1;
	}
	my $prob=$alevel/$dlevel*0.75;
	if($prob>0.95){
		$prob=0.95;
	}
	if($prob<0.25){
		$prob=0.25;
	}
	return (rand()<=$prob);
}

sub damage_dealt{ my ($name)=@_;
	my $level=$characters{$name}->{level};
	if((($characters{$name}->{class} eq 'twink') ||
	 $characters{$name}->{class} =~ /dragon/) && int(rand(6))==1){
		say("CRITICAL HIT!");
		return 10*$classes{$characters{$name}->{class}}->{damage};
	}elsif(($characters{$name}->{class} =~ /fighter|monk/) &&
	 (rand(30)<$level) ){
		say("CRITICAL HIT!");
		return 10*$classes{$characters{$name}->{class}}->{damage};
	}elsif(($characters{$name}->{class} =~ /hunter/) &&
	 (rand(60)<$level) ){
		say("CRITICAL HIT!");
		return 10*$classes{$characters{$name}->{class}}->{damage};
	}elsif(int(rand(50))==1){
		say("CRITICAL HIT!");
		return 10*$classes{$characters{$name}->{class}}->{damage};
	}else{
		return $classes{$characters{$name}->{class}}->{damage};
	}
}

sub cause_damage{ my ($name,$amount)=@_;
	if($amount == 0){
		say("\2$name\2 is not affected");
	}elsif($amount>0){
		my $actual=int(rand()*$amount+1);
		say("\2$name\2 is hit for \2$actual\2 points of damage!");
		$characters{$name}->{hp}-=$actual;
	}else{
		$amount=-$amount;
		my $actual=int(rand()*$amount+1);
		say("\2$name\2 is healed of \2$actual\2 points of damage.");
		$characters{$name}->{hp}+=$actual;
	}
	if($name eq 'monster' && $characters{monster}->{delay}<time()){
		$characters{monster}->{delay}=time()-10;
	}
	correct_points($name);
	if($characters{$name}->{hp}<=0){
		say("\2$name\2 is struck dead!");
	}
}

sub attack{ my ($attacker, $defender)=@_;
	if($characters{$attacker}->{isresting}){
		sayto($attacker, "You can't do that, you're resting!");
		return;
	}
	if($characters{$defender}->{isresting}){
		say('The Attack is Blocked by the Mystical Barrier');
		return;
	}
	if($characters{$attacker}->{delay}<time()){
		if(does_hit($attacker,$defender)){
			cause_damage($defender, damage_dealt($attacker));
			if($characters{$defender}->{hp}<=0){
				defeats($attacker,$defender);
			}
		}else{
			say("\2$defender\2 nimbly evades a strike from \2$attacker\2");
		}
		if(exists $characters{$attacker}){
			$characters{$attacker}->{delay}=time()+5;
		}
	}else{
		penalty($attacker);
	}
}

my %level_effects=(
twink=>sub {my ($name)=@_;
	if($characters{$name}->{level}>=20){
		say("The light that burns twice as bright burns but half as long.");
		defeats($name,$name);
		say("Twink!");
	}
	$last_twink=time();
},
harlot=>sub {my ($name)=@_;
	if($characters{$name}->{level}>=20){
		say("The years of careless living and drug abuse take their toll!");
		say("\2$name\2 degenerates into a \2skank\2!");
		$characters{$name}->{xp}=0;
		$characters{$name}->{class}='skank';
		$characters{$name}->{level}=1;
		learned($name,$characters{$name}->{class});
	}
},
skank=>sub {my ($name)=@_;
	if($characters{$name}->{level}>=20){
		say("The years of careless living and drug abuse take their toll!");
		say("\2$name\2 degenerates into a \2hag\2!");
		$characters{$name}->{xp}=0;
		$characters{$name}->{class}='hag';
		$characters{$name}->{level}=1;
		learned($name,$characters{$name}->{class});
	}
},
hag=>sub {my ($name)=@_;
	if($characters{$name}->{level}>=10){
		say("The years of careless living and drug abuse take their toll!");
		say("\2$name\2 degenerates into a \2wretch\2");
		$characters{$name}->{hp}=1;
		$characters{$name}->{mp}=0;
		$characters{$name}->{maxhp}=1;
		$characters{$name}->{maxmp}=0;
		$characters{$name}->{xp}=0;
		$characters{$name}->{class}='wretch';
		$characters{$name}->{level}=1;
		learned($name,$characters{$name}->{class});
	}
},
spider_man=>sub {my ($name)=@_;
	my %effects=(
		2=>"\2$name\2 eyes bulge and segment!",
		3=>"\2$name\2 grows spinnerets!",
		4=>"\2$name\2 grows disgusing spider-hair all over his body!",
		5=>"\2$name\2 head now looks just like a spider's!",
		6=>"\2$name\2 starts to grow 2 new pairs of limbs from his torso!",
		7=>"\2$name\2 now has two distinct body segments!",
		8=>"\2$name\2 can now walk around on all eights!",
		9=>"\2$name\2 eyes his friends hungrily!",
	);
	if($characters{$name}->{level}>=10 && !exists($characters{monster})){
		say("\2$name\2 completes his transformation into a \2radioactive_spider\2.");
		say("\2$name\2 loses his mind!");
		new_character('monster','radioactive_spider','impossible!ID@!@!@');
		delete $characters{$name};
		delete $present{$name};
		delete $concealed{$name};
		say("\2$name\2 is now \2monster\2!");
	}else{
		if(exists $effects{$characters{$name}->{level}}){
			say($effects{$characters{$name}->{level}});
		}
	}
},
);

sub level_down{ my ($name)=@_;
	my $class=$characters{$name}->{class};
	my $origxp=xp_needed($name);
	$characters{$name}->{level}-=2;
	$characters{$name}->{maxhp}-=int(rand($classes{$class}->{hp})+1);
	if($classes{$class}->{mp}!=0){
		$characters{$name}->{maxmp}-=int(rand($classes{$class}->{mp})+1);
	}
	if($characters{$name}->{level}<1){
		$characters{$name}->{xp}=0;
	}else{
		$characters{$name}->{xp}=xp_needed($name);
	}
	$characters{$name}->{level}+=1;
	if($characters{$name}->{level}<1 ||
	 $characters{$name}->{maxhp}<1 ||
	 $characters{$name}->{maxmp}<0){
		say("\2$name\2's body couldn't take the strain!  It crumbles to dust.");
		delete $characters{$name};
		delete $present{$name};
		delete $concealed{$name};
		return;
	}
}

sub level_up{ my ($name)=@_;
	my $class=$characters{$name}->{class};
	$characters{$name}->{level}+=1;
	$characters{$name}->{maxhp}+=int(rand($classes{$class}->{hp})+1);
	if($classes{$class}->{mp}!=0){
		$characters{$name}->{maxmp}+=int(rand($classes{$class}->{mp})+1);
	}
	say("\2$name\2 LEVELS UP!");
	say("\2$name\2 is now a Level \2$characters{$name}->{level} $class\2!");
	learned($name,$class);
	if($characters{$name}->{level}==100){
		say("This is getting ridiculous.  Level \2100\2?!");
	}
	if(exists $level_effects{$class}){
		&{$level_effects{$class}}($name);
	}
}

sub correct_points{ my ($name)=@_;
	if($name ne $mimicking){
		if($characters{$name}->{hp}>$characters{$name}->{maxhp}){
			$characters{$name}->{hp}=$characters{$name}->{maxhp};
		}
		if($characters{$name}->{mp}>$characters{$name}->{maxmp}){
			$characters{$name}->{mp}=$characters{$name}->{maxmp};
		}
		while(exists($characters{$name}) &&
		 $characters{$name}->{xp} >= xp_needed($name)){
			level_up($name);
		}
	}
}

sub defeats{ my ($victor,$victim)=@_;
	my @victors=();
	if(! exists $characters{$victim}){
		return;
	}
	if(! exists $characters{$victor}){
		return;
	}
	my $victim_class=$characters{$victim}->{class};
	if(exists $weird_deaths{$victim_class}){
		my $normal_victory= &{$weird_deaths{$victim_class}}($victim,$victor);
		return if not $normal_victory;
	}
	if($victim eq 'monster'){
		@victors=get_party();
	}
	push @victors,$victor;
	my $value=xp_value($victim);
	$graveyard{$victim}=$characters{$victim};
	if(($victim ne 'monster') && ($characters{$victim}->{class} ne 'twink')){
		$graveyard{$victim}->{delay}=time();
	}else{
		$graveyard{$victim}->{delay}=time()-500;
	}
	$defeated{$characters{$victim}->{staticid}}=$victim;
	delete $characters{$victim};
	delete $present{$victim};
	for(@victors){
		if($_ ne $victim && exists($characters{$_})){
			$characters{$_}->{xp}+=int($value/scalar(@victors));
		}
	}
	say("\2$victor\2 defeats \2$victim\2!");
	for(@victors){
		if($_ ne $victim && exists($characters{$_})){
			correct_points($_);
		}
	}
}

sub resurrect{ my ($name)=@_;
	if(! exists $graveyard{$name}){
		return;
	}
	delete $defeated{$characters{$name}->{staticid}};
	$characters{$name}=$graveyard{$name};
	$characters{$name}->{hp}=1;
	$characters{$name}->{mp}=0;
	$characters{$name}->{isresting}=1;
	delete $graveyard{$name};
	say("\2$name\2 is restored to life! (he is weakened from his ordeal)");
	level_down($name);
}

sub clean_grave{ my ($static)=@_;
	delete $graveyard{$defeated{$static}};
	delete $defeated{$static};
}

sub is_dead{ my ($static)=@_;
	return exists $defeated{$static};
}

sub death_time{ my ($static)=@_;
	return $graveyard{$defeated{$static}}->{delay};
}

sub can_cast{ my ($caster,$spell)=@_;
	return exists($spells{$spell}) &&
	 ($characters{$caster}->{mp} >= $spells{$spell}->{cost}) &&
	 exists($classes{$characters{$caster}->{class}}->{spells}->{$spell}) &&
	 ($classes{$characters{$caster}->{class}}->{spells}->{$spell} <=
	 $characters{$caster}->{level});
}

sub can_summon{ my ($caster,$class)=@_;
	if(! exists($characters{$caster})){return 0;}
	if($characters{$caster}->{class} ne 'summoner'){return 0;}
	if(exists $characters{$caster}->{summons}->{$class}){
		if(summon_cost($class) > $characters{$caster}->{mp}){
			return 0;
		}else{
			return 1;
		}
	}else{
		return 0;
	}
}

sub summon_cost{ my ($class)=@_;
	return $spells{$summons{$class}}->{cost};
}

sub summon{ my ($caster,$class,$target)=@_;
	if(! exists $characters{$caster}){
		return;
	}
	if($characters{$caster}->{class} ne summoner){
		sayto($caster, "Only a \2summoner\2 can summon creatures.");
		return;
	}
	if($characters{$caster}->{isresting}){
		sayto($caster, "You can't do that, you're resting!");
		return;
	}
	if($characters{$caster}->{delay}<time()){
		if(can_summon($caster,$class)){
			my $spell=$summons{$class};
			my $damage=$spells{$spell}->{damage};
			$characters{$caster}->{mp}-=$spells{$spell}->{cost};
			if(rand()<(0.70+$characters{$caster}->{level}/100)){
				if(exists $characters{$caster}){
					$characters{$caster}->{delay}=time()+9;
				}
				say("\2$caster\2 summons \2$class\2 to cast \2$spell\2!");
				if(rand() > 0.98){
					say("...but loses control of the \2$class\2!");
					if($present{monster}){
						$target=rand_el(get_targets(),'monster');
					}else{
						$target=rand_el(get_targets());
					}
				}
				if(exists $special_spells{$spell}){
					&{$special_spells{$spell}}($caster,$target);
				}else{
					cause_damage($target,$damage);
				}
				if($characters{$target}->{hp}<=0){
					defeats($caster,$target);
				}
				if(exists $characters{$caster}){
					$characters{$caster}->{xp}+=int($cost/2);
					correct_points($caster);
				}
			}else{
				say("\2$caster\2 fails to summon \2$class\2");
			}
		}else{
			sayto($caster, "You can't summon that!");
		}
	}else{
		penalty($caster);
	}
}

sub cast{ my ($caster, $spell, $target)=@_;
	if($characters{$caster}->{isresting}){
		sayto($caster, "You can't do that, you're resting!");
		return;
	}
	if($characters{$target}->{isresting}){
		sayto($caster, "You can't do that, Their Resting!");
		return;
	}
	if($characters{$caster}->{delay}<time()){
		if(can_cast($caster,$spell)){
			my $target_ok=exists($characters{$target});
			my $target_hurt=(!exists($characters{$target})) ||
			 $characters{$target}->{hp}<$characters{$target}->{maxhp};
			my $cost=$spells{$spell}->{cost};
			my $damage=$spells{$spell}->{damage};
			my $defeat_check=1;
			$characters{$caster}->{mp}-=$cost;
			if(rand()>0.97){
				say("The spell fizzles!");
			}else{
				if(exists $characters{$caster}){
					$characters{$caster}->{delay}=time()+7;
				}
				say("\2$caster\2 casts \2$spell\2!");
				if(exists $special_spells{$spell}){
					$defeat_check= &{$special_spells{$spell}}($caster,$target);
				}else{
					cause_damage($target,$damage);
				}
				if($defeat_check && $target_ok && $characters{$target}->{hp}<=0){
					defeats($caster,$target);
				}
				my $raised= (!$target_ok) && exists($characters{$target});
				my $wounded= $target_ok && $damage > 0;
				my $healed= $target_hurt && $damage < 0;
				my $useful= $raised || $wounded || $healed;
				if(exists $characters{$caster}){
					if($useful){
						my $xpgain=int($cost/2);
						if($xpgain>50){
							$xpgain=50;
						}
						$characters{$caster}->{xp}+=$xpgain;
						correct_points($caster);
					}
				}
			}
		}else{
			sayto($caster, "You can't cast that!");
		}
	}else{
		penalty($caster);
	}
}

sub status{ my ($name)=@_;
	if(!exists $characters{$name}){return;}
	say("\2$name\2 is a level \2$characters{$name}->{level}\2 ".
	 "\2$characters{$name}->{class}\2 with \2$characters{$name}->{hp}/$characters{$name}->{maxhp}\2 hit points,".
	 " \2$characters{$name}->{mp}/$characters{$name}->{maxmp}\2 magic points, and ".
	 "\2$characters{$name}->{xp}\2 experience points (\2". xp_needed($name) .
	 "\2 needed for next level).");
}

sub penalty{ my ($name)=@_;
	sayto($name,"Whoa!  Slow down!  That'll cost you another 2 seconds.");
	$characters{$name}->{delay}=$characters{$name}->{delay}+2;
}

sub defeated_penalty{ my ($name,$static)=@_;
	if($protect_chat){
		sayto($name,"Don't camp the spawn!  That'll cost you another 5 seconds.");
		$graveyard{$defeated{$static}}->{delay}+=5;
	}
}

sub flee{ my ($name)=@_;
	if($characters{$name}->{isresting}){
		sayto($name,"You're already resting safely, fleeing won't do anything.");
	}elsif($characters{$name}->{delay}<time()){
		if(int(rand(3))==1){
			say("\2$name\2 tried to flee, but couldn't escape!");
		}else{
			say("\2$name\2 flew in terror!");
			sayto($name,"You ran far away, grew tired, and sat down to rest.");
			$characters{$name}->{delay}=time()+60;
			$characters{$name}->{isresting}=1;
		}
	}else{
		penalty($name);
	}
}

sub rest{ my ($name)=@_;
	if($characters{$name}->{isresting}){
		sayto($name, "You can't do that, you're already resting!");
		return;
	}
	if(exists $characters{monster}){
		sayto($name, "You can't do that, there's a monster! (try \2flee\2)");
		return;
	}
	if($characters{$name}->{delay}<time()){
		if($protect_chat){
			sayto($name,"Use the '\2wake\2' command to stop resting (less than 60 seconds doesn't help at all, five minutes will restore you fully)");
			say("\2$name\2 Sat Down to rest");
		}else{
			sayto($name,"Use the '\2wake\2' command to stop resting (60 seconds will restore you to full strength)");
			say("\2$name\2 Sat Down to rest");
		}
		$characters{$name}->{delay}=time()+60;
		$characters{$name}->{isresting}=1;
	}else{
		penalty($name);
	}
}

sub wake{ my ($name)=@_;
	if(!$characters{$name}->{isresting}){
		sayto($name,"You can't do that, you're already awake!");
		return;
	}
	if(exists $characters{monster}){
		sayto($name,"The party's gone off wandering, and is fighting a monster.");
		sayto($name,"You'll never catch up before the battle's over.");
	}else{
		if($characters{$name}->{delay}<time()){
			my $factor=(time()-$characters{$name}+60)/300;
			if($protect_chat){
				$characters{$name}->{hp}+=int($characters{$name}->{maxhp}*$factor);
				$characters{$name}->{mp}+=int($characters{$name}->{maxmp}*$factor);
			}else{
				$characters{$name}->{hp}=$characters{$name}->{maxhp};
				$characters{$name}->{mp}=$characters{$name}->{maxmp};
			}
			correct_points($name);
			say("\2$name\2 arises, feeling refreshed");
		}else{
			say("\2$name\2 rises, grumpy and unrested.");
		}
		$characters{$name}->{isresting}=0;
		$characters{$name}->{delay}=time()+5;
	}
}

my %areas=(
hometown_plains=>{
slime=>1000,
goblin=>1000,
wolf=>1000
},
drow_caves=>{
drow_archer=>150,
drow_priestess=>100,
drow_fighter=>200
},
gryphon_nest=>{
elder_gryphon=>10,
mother_gryphon=>50,
gryphon=>100,
young_gryphon=>75
},
dragon_mountain=>{
grand_dragon=>10,
council_dragon=>20,
red_dragon=>30,
blue_dragon=>100,
green_dragon=>100,
drake=>150
},
orc_camp=>{
orc_general=>5,
orc_commander=>10,
orc_soldier=>20,
orc_guard=>50
},
);

sub pick_random{ my ($area,$preferred,$factor)=@_;
	my $total=0;
	if(! exists($areas{$area})){
		$area='hometown_plains';
	}
	for(keys %{$areas{$area}}){
		$total+=$areas{$area}->{$_}*($_ eq $preferred ? $factor : 1);
	}
	my $rand=int(rand($total));
	$total=0;
	for(keys %{$areas{$area}}){
		$total+=$areas{$area}->{$_}*($_ eq $preferred ? $factor : 1);
		if($total >= $rand){
			return $_;
		}
	}
	return 'slime';
}

sub wander{ my ($name,$area,$preferred,$factor)=@_;
	if(! exists $characters{$name}){
		return;
	}
	if($characters{$name}->{isresting}){
		sayto($name, "You can't wander, you're resting!");
		return;
	}
	if(! exists $characters{monster}){
		foreach(get_party()){
			$characters{$_}->{delay}=time()+5;
		}
		new_character('monster',pick_random($area,$preferred,$factor),
		 'impossible!ID@!@!@');
		$present{lc('monster')}=1;
	}
}

sub tell_summons{ my ($name)=@_;
	if($characters{$name}->{class} eq 'summoner'){
		sayto($name, "The creatures you can summon are: ".
		join(' ',(map {"\2$_\2 (\2$spells{$summons{$_}}->{cost}\2 mp)"}
		 keys(%{$characters{$name}->{summons}}))));
	}
}

sub tell_spells{ my ($name)=@_;
	sayto($name, "The spells you know are: ".
	join(' ',(map {"\2$_\2 (\2$spells{$_}->{cost}\2 mp)"}
	 spells_known($name))));
}

sub spells_known{ my ($name)=@_;
	my @ret=();
	for(keys %{$classes{$characters{$name}->{class}}->{spells}}){
		if( $classes{$characters{$name}->{class}}->{spells}->{$_} <=
		 $characters{$name}->{level}){
			push @ret, $_;
		}
	}
	return @ret;
}

sub spells_available{ my ($name)=@_;
	my @ret=();
	for(keys %{$classes{$characters{$name}->{class}}->{spells}}){
		if( ($classes{$characters{$name}->{class}}->{spells}->{$_} <=
		 $characters{$name}->{level}) &&
		 ($characters{$name}->{mp} >= $spells{$_}->{cost})){
			push @ret, $_;
		}
	}
	return @ret;
}

sub useful_spells{ my ($name)=@_;
	my @ret=();
	for(spells_available($name)){
		if($spells{$_}->{damage}<0){
			if($characters{$name}->{hp} < $characters{$name}->{maxhp}){
				push @ret, $_;
			}
		}else{
			push @ret, $_;
		}
	}
	return @ret;
}

sub monster_action{
	if(exists($characters{monster})
	 && (time()>($characters{monster}->{delay}+int(rand(3))))){
		$characters{monster}->{isresting}=0;
		my @targets=get_targets();
		if(!get_party()){
			say("Everyone has escaped from the $characters{monster}->{class}!");
			delete $characters{monster};
			delete $present{monster};
			return;
		}
		if(@targets){
			my $target= $targets[rand(scalar(@targets))];
			my @sp=useful_spells('monster');
			my $choice=int(rand(scalar(@sp) + 2));
			$present{monster}=1;
			delete $concealed{monster};
			if($choice>=2){
				my $spell=$sp[$choice-2];
				say("The $characters{monster}->{class} (ID: \2monster\2) uses a spell!");
				if($spells{$spell}->{damage}<0){
					cast('monster',$sp[$choice-2],'monster');
				}else{
					cast('monster',$sp[$choice-2],$target);
				}
			}else{
				say("The $characters{monster}->{class} (ID: \2monster\2) attacks \2$target\2!");
				attack('monster',$target);
			}
		}else{
			if(rand(time()-$characters{monster}->{delay})>40.0){
				say("The $characters{monster}->{class} gets bored, and wanders off.");
				delete $characters{monster};
				delete $present{monster};
			}
		}
	}
}

sub get_targets{
	my @ret=();
	for(get_actives()){
		push @ret, $_;
		if($characters{$_}->{frontline}){
			push @ret, $_;
		}
	}
	return @ret;
}

sub get_actives{
	my @ret=();
	for(keys %characters){
		if( $_ ne 'monster' &&
		 $present{lc($_)} &&
		 ! $characters{$_}->{isresting} ){
			push @ret, $_;
		}
	}
	return @ret;
}

sub get_actives_and_monster{
	if(exists $characters{monster}){
		return ('monster',get_actives());
	}else{
		return get_actives();
	}
}

sub get_party{
	my @ret=();
	for(keys %characters){
		if( $_ ne 'monster' &&
		 ($present{lc($_)} || $concealed{lc($_)}) &&
		 ! $characters{$_}->{isresting} ){
			push @ret, $_;
		}
	}
	return @ret;
}

sub intro{
	say('Welcome to Dark Dragons ADVACED Version 0.1');
	say('Thanks to SA-X For Assisting in Move Making');
	say("Command me with '\2>\2 command's'.");
	say("Try '\2> help\2'.");
}

sub games{
	say('The Games Lists are Divided:');
	say('> FGames for Hi-Fi RPGs (Hightech Fiction)');
	say('> Mgames for Medieval RPGs');
	say('> Cgames for Current Date RPGs');
	say('> Bgames for Bot Based Games');
}

sub mgames{
	say('Medieval RPGs: #RealmOfEstoria');
}

sub fgames{
	say('There are currently no Hi-Fi games');
}

sub cgames{
	say('There are Currently no Current time games');
}

sub bgames{
	say('There are: #Acro - #Trivia - (me, i have no room so i sit here)');
}

sub on_connect{
	my ($self,$msg)=@_;
	print "Joining...\n";
	$self->join($channel);
	$self->part('#matrix-chat');
	intro();
}

sub on_msg{
	my ($self,$msg)=@_;
	my $text=${@{$msg->{'args'}}}[0];
	$msg->{from}=~/([^!]+)![^@]+\@(.+)/;
	my $from=$1;
	my $static=$2;
	logprint "$from:$static :-";
	logprint join(":",@{$msg->{'args'}});
	logprint "\n";
	if(time()>($lastsave+150)){
		save();
	}
	monster_action();
	if(exists($characters{$from})){
		$present{lc($from)}=1;
		delete $concealed{lc($from)};
	}
	if($text =~ /BattleEngine/i){
		if($naive_audience){
			intro();
		}
	}
	if($text =~ /^\s*>\s+(.+)$/i){
		$_=$1;
		if(exists($characters{$from}) &&
		 ($characters{$from}->{staticid} ne $static)){
			say("Hey \2$from\2!  Back to your own nick!");
			sayto($from,"If this is actually your account, use '\2\/msg DDA login PASSWORD\2' to log in (or create a password, if you hadn't before).");
			sayto($from,"Remember that in such a situation, at least one other person can read your password.  And, of course, everybody you're chatting with knows your IP address.  Don't use an important password.  Better to use an insecure password like 'password' or your character's name backward, and have someone steal your character, than to use an important password and have someone break into your computer.");
			if(exists $present {lc($from)}){
				delete $present{lc($from)};
			}
			return;
		}
		if(lcname($from) ne $from){
			sayto($from,"Nick recognition is case-sensitive, you must change your nick back to ".lcname($from).".");
			return;
		}
		if(/^join\s+(\S+)/i){
			my $staticmatch=0;
			my $class=$1;
			if(exists $class_aliases{$class}){
				$class=$class_aliases{$class};
			}
			for $name (keys %characters){
				if($characters{$name}->{staticid} eq $static){
					$staticmatch=1;
				}
			}
			if(exists $characters{$from}){
				sayto($from,"You've already joined.");
			}elsif($staticmatch){
				say("Oi! No cloning, \2$from\2!");
			}else{
				my $slime_delay=$protect_chat?150:30;
				my $reg_delay=$protect_chat?300:60;
				if((lc($class) eq 'slime') &&
				 is_dead($static) &&
				 (death_time($static)+$slime_delay)>time()){
					defeated_penalty($from,$static);
					sayto($from,"It will now be ".
					 ((death_time($static)+$slime_delay)-time()).
					 " seconds until you can join as a slime again.");
				}elsif((lc($class) ne 'slime') && is_dead($static) && (death_time($static)+$reg_delay)>time()){
					defeated_penalty($from,$static);
					sayto($from,"It will now be \2".
					 ((death_time($static)+$reg_delay)-time()).
					 "\2 seconds until you can join again.");
				}else{
					if(lc($class) eq 'twink'){
						if((time()-$last_twink)>24*60*60){
							$last_twink=time();
							new_character($from,'twink',$static);
						}else{
							$last_twink=time();
							say("No more \2twink\2s today, twink! (or tomorrow, now).");
						}
					}elsif(exists $classes{lc($class)} && $classes{lc($class)}->{user}){
						$present{lc($from)}=1;
						new_character($from,lc($class),$static);
					}else{
						sayto($from,"there is no such class as '\2$class\2'");
					}
				}
			}
		}elsif(/^intro/i){
			intro();

		}elsif(/^cgames/i){
			cgames();
		}elsif(/^mgames/i){
			mgames();
		}elsif(/^bgames/i){
			bgames();
		}elsif(/^fgames/i){
			fgames();
		}elsif(/^games/i){
			games();
		}elsif(/^who/i){
			say("Current players: \2".join(' ',(keys %characters))."\2");
		}elsif(/^pres/i){
			say("Current present players: \2".join('',
			 map{!$present{lc($_)}?'':"$_ "}(keys %characters))."\2");
		}elsif(/^active/i){
			say("Current awake players: \2".join(' ', get_actives())."\2");
		}elsif(/^save/i){
			save();
		}elsif(/^help(?:\s+(.+))?$/i){
			$_=$1;
			if(/^(\S+)/ && exists($spells{lc($1)})){
				sayto($from,$spells{lc($1)}->{description});
			}elsif(/^class/i){
				sayto($from,"the classes are: \2".join(' ',keys(%class_aliases))."\2");
			}elsif(/^wander/i){
				sayto($from,"Use '\2wander AREA\2' to find a monster to fight!");
			}elsif(/^area/i){
				sayto($from,"Wander any of these areas: \2".join(' ',keys(%areas)).
				 "\2");
			}elsif(/^front/i){
				sayto($from,"Move to the front of the line, protect your allies.");
			}elsif(/^back/i){
				sayto($from,"Move behind your allies, let them take the heat.");
			}elsif(/^study/i){
				sayto($from,"Study a creature to learn to summon it.");
			}elsif(/^summon/i){
				sayto($from,"Summon a creature you've successfully \2study\2'd.",
				 "Use '\2> summons\2' to learn which you can summon.");
			}elsif(/^hunt/i){
				sayto($from,"Hunt a particular a creature to learn to summon it.");
			}else{
				sayto($from,"Get a character class by saying '\2join [CLASS]\2'.",
				 "I also understand '\2stat\2', '\2spells\2','\2hit [TARGET]\2','\2cast [SPELL] on [TARGET]\2', '\2rest\2', '\2wander [AREA]\2', '\2front\2', '\2back\2', and '\2wake\2'",
				 "Also '\2study [SUBJECT]\2' '\2summon [SUBJECT] at [TARGET]\2' '\2summons\2' for summoners only,",
				 "All commands must be started with '\2>\2'",
				 "(Try '\2> intro\2' '\2> help spells\2' and '\2> help classes\2')");
			}
		}elsif(exists($characters{$from})){
			if(/^hit\s+(\S+)/i){
				if(exists($characters{lcname($1)})){
					if(!$present{lc($1)}){
						say("\2$1\2 isn't here.");
					}else{
						attack($from,lcname($1));
					}
				}else{
					say("There is no \2$1\2.");
				}
			}elsif(/^cast\s+(\S+)\s+(?:on\s+)?(\S+)/i){
				my $spell=$1;
				my $target=$2;
				if(lc($spell) =~ /raise|life/){
					cast($from,lc($spell),lcname($target));
				}elsif(!exists($characters{lcname($target)})){
					say("There is no \2$target\2.");
				}elsif(!exists($spells{lc($spell)})){
					say("There's no such spell as \2$spell\2.");
				}else{
					if(!$present{lc($target)}){
						say("\2$target\2 isn't here.");
					}else{
						cast($from,lc($spell),lcname($target));
					}
				}
			}elsif(/^summon\s+(\S+)\s+(?:at\s+)?(\S+)/i){
				my $creature=$1;
				my $target=$2;
				if(exists($summons{lc($creature)}) && ($summons{lc($creature)} =~ /raise|life/)){
					summon($from,lc($creature),lcname($target));
				}elsif(!exists($characters{lcname($target)})){
					say("There is no \2$target\2.");
				}else{
					if(!$present{lc($target)}){
						say("\2$target\2 isn't here.");
					}else{
						summon($from,lc($creature),lcname($target));
					}
				}
			}elsif(/^spells/i){
				tell_spells($from);
			}elsif(/^summons/i){
				tell_summons($from);
			}elsif(/^study\s+(\S+)/i){
				if(exists($characters{lcname($1)})){
					if(!$present{lc($1)}){
						say("\2$1\2 isn't here.");
					}else{
						summoner_study($from,lcname($1));
					}
				}else{
					say("There is no \2$1\2.");
				}
			}elsif(/^front/i){
				if(!$characters{$from}->{frontline}){
					say("\2$from\2 bravely moves to the front line.");
					$characters{$from}->{frontline}=1;
				}else{
					sayto($from, "You're already in the front line.");
				}
			}elsif(/^back/i){
				if($characters{$from}->{frontline}){
					say("\2$from\2 wisely moves to the back line.");
					$characters{$from}->{frontline}=0;
				}else{
					sayto($from, "You're already in the back line.");
				}
			}elsif(/^(flee|run)/i){
				flee($from);
			}elsif(/^rest/i){
				rest($from);
			}elsif(/^wake/i){
				wake($from);
			}elsif(/^wander(?:\s+(\w+))?/i){
				if($1 && ! exists($areas{lc($1)})){
					say("\2$1\2 is not a valid area (use 'help areas').");
				}else{
					wander($from,lc($1));
				}
			}elsif(/^stat/i){
				status($from);
			}else{
				if(/^(\S+)\s+(?:on\s+)?(\S+)/i && can_cast($from,$1)){
					my $spell=$1;
					my $target=$2;
					if(lc($spell) =~ /raise|life/){
						cast($from,lc($spell),lcname($target));
					}elsif(!exists($characters{lcname($target)})){
						say("There is no \2$target\2.");
					}else{
						if(!$present{lc($target)}){
							say("\2$target\2 isn't here.");
						}else{
							cast($from,lc($spell),lcname($target));
						}
					}
				}else{
					sayto($from,"I'm sorry, I don't understand.");
				}
			}
		}else{
			sayto($from,"You have to join first.");
		}
	}
}

sub on_private{
	my ($self,$msg)=@_;
	my $text=${@{$msg->{'args'}}}[0];
	$msg->{from}=~/([^!]+)![^@]+\@(.+)/;
	my $from=$1;
	my $static=$2;
	logprint "on_private\n";
	logprint "$from  $static \n";
	logprint "$text\n";
	if($text=~/^log\S*\s+(\w+)/i){
		if(! exists $characters{$from}){
			sayto($from, "Join first.");
			return;
		}
		if(exists $characters{$from}->{password}){
			if($characters{$from}->{password} eq $1){
				$characters{$from}->{staticid}=$static;
				sayto($from,"You are now logged in.");
			}else{
				sayto($from,"Incorrect password.");
			}
		}else{
			$characters{$from}->{password}=$1;
			$characters{$from}->{staticid}=$static;
			sayto($from,"Your password is now registered.");
		}
	}
}

sub on_quit{
	my ($self,$msg)=@_;
	$msg->{from}=~/([^!]+)!(.+)/;
	my $from=$1;
	my $static=$2;
	delete $present{lc($from)};
	delete $concealed{lc($from)};
}

sub on_join{
	my ($self,$msg)=@_;
	$msg->{from}=~/([^!]+)!(.+)/;
	my $from=$1;
	my $static=$2;
	$present{lc($from)}=1;
	delete $concealed{lc($from)};
}

$conn->add_handler('376', \&on_connect);
$conn->add_handler('public', \&on_msg);
$conn->add_handler('msg', \&on_private);
$conn->add_handler('quit', \&on_quit);
$conn->add_handler('part', \&on_quit);
$conn->add_handler('join', \&on_join);

$irc->start;
