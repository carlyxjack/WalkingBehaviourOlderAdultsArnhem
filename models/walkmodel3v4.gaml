/**
* Name: walkingv6
* Author: Joy van Vliet
* Description: 
* Tags: Roads, Urban Green Spaces, Attractiveness, Walking Behavior of older adults
*/
model walkmodel

/* Insert your model definition here */
global {
//shapefile features respectively
	file roads_shapefile <- file("../includes/psa07RoadswithinPark_1.shp");
	file buildings_shapefile <- file("../includes/a08BuildingswithSES.shp");
	file Park_shapefile <- file("../includes/psa04GreenPark1_1.shp");
	file busstops_shapefile <- file("../includes/pr_sonnsbeek_busstops.shp");
	file sample_csv <- csv_file("../includes/SampleData.csv", ",");
	file people_shapefile<-file("../includes/WalkingwithParkList.shp");

// activate when the older adult agents don't have walking minutes yet 
	//convert the file into a matrix	
//	matrix<int> data <- matrix<int>(sample_csv);
//	int nb_leaf <- 15;
//	map<int, list<int>> map_data_walkinvalues;
	


	// creating a shape of the environment
	geometry shape <- envelope(roads_shapefile);
	//Graph of the road network
	graph road_network;
	// weights roads
	map<roads, float> weights_map;
	float step <- 60 #sec; //can change cycle time
	string type;
	
	//older_adult variables
	int nb_persons -> length(older_adult where(each.donothing=false));

	// park variables
	float AttractParkProbality <- 0.5;
	int parksizethreshold<-50000;
	int parkcounter;
	
	//road variables
	float resfactor<-0.3;

	
	// walk variables
	int walkbalance; // walk balance of one day
	float distanceToPark; // distance to closest park
	int resetwalkbalance; //walkbalance for one day, just to keep track what the initial walk balance was
	float totaldistance; // total distance walked in the week
	float weekGreenminutes; // total minutes exposed to Green during one week
	float ratiowalking<-0.4; // factor derived from one Dutch study in order to calculate the minutes walking dedicated to recreational walking from the total walking minutes
	int weekbalance; // walk balance for one week
	int totalweekbalance; // the same as weekbalance, just to keep track what the initial week balance was
	float home_range; // available distance to walk to a road/park
	int proximity; // amount of parks within home range
	point start; 
	list<Park> Parks; //important durign the first run, when the parks within home range are yet unknown

	


	init {


		write "model started";
// needed when the older adult agents don't have walking minutes yet (probably during first run)
//			loop leaf from: 0 to: nb_leaf {
//			list<int> walkingValues <- [];
//			loop i from: 0 to: data.rows - 1 {
//				if (data[2, i] = leaf) {
//					add data[0, i] to: walkingValues;
//					
//				}
//
//			}
//
//			put walkingValues key: leaf in: map_data_walkinvalues;
//			
//
//			
//			
//		}
		create buildings from: buildings_shapefile;   
		create roads from: clean_network(roads_shapefile.contents,0,true,true) with: [TypeRoad::string(read("FCLASS")),WeightGreenAlongRoad::float(read("SUM_Attrac")), GreenalongRoad::int(read("GreenAlong"))];
//		save roads to: "../includes/batchtrialv2/output/roads.shp" type: "shp" with:[name::"Name"];	// just to have a shp in which the csv can be afterwards attached to
		
		create busstops from: busstops_shapefile;
		create Park from: Park_shapefile with: [NamePark::string(read("PARKNAAM_L")),Name::string(read("Name")),Forest::bool(read("DoesHaveFo")),Pond::bool(read("doeshavepo")), AREA::float(read("Shape_Area"))];
				loop element over: Park{
			if element.NamePark!="Begraafpark Moscowa"{
			if element.AREA>parksizethreshold{
				element.variablecounter<-element.variablecounter+1;}
//			if element.oppervlakte<parksizethreshold{
//					element.variablecounter<-element.variablecounter+1;}
			if element.Forest=true{
			element.variablecounter<-element.variablecounter+1;				
			}
			if element.Pond=true{
					element.variablecounter<-element.variablecounter+1;}
			}
			}
			
//		save Park to: "../includes/batchtrialv2/output/parks.shp" type: "shp" with:[NamePark::"Name"]; // just to have a shp in which the csv can be afterwards attached to
		
		//		create busstops from: busstops_shapefile;
		
		weights_map <- roads as_map (each::(100 + (each.WeightRoad+each.WeightGreenAlongRoad)));
		road_network <- (as_edge_graph(roads)) with_weights weights_map;
		
	

	
	create older_adult from: people_shapefile with: [CID::int(read("ID")),gender::string(read("gender")),dog::string(read("dog")),scorehealth::string(read("health")),age::int(read("age")),walkbalance::int(read("wlkblnc")),parklist::list(read("_replaced"))] {
	// giving men and women their corresponding speed, however when other data is available, speeds can be distinguished based on age, gender and physical health for example.
	// speeds are based on population based study in the Netherlands (Stringhini et al., 2018)
	if gender="man"{
		speed<-1.43;
	}
	if gender="woman"{
		speed<-1.56;
	}
	start<-location;
	
// When the initial distance to Park is unknown for the older_adult agents (in case of the first run), then the code below needs to be run, in order to find to which leaf node the older adult belongs and thus how many walking minutes will be attributed to the older_adult agents 
// 
//	using topology(road_network) {
//	distanceToPark <- Park min_of (start distance_to each);
//
//
//			
//			}

//	if walkbalance = 0 {
//	
//	
//
//		if distanceToPark > 750 and age > 70 {
//			walkbalance <- one_of(map_data_walkinvalues[10]);
////			walktimes <- one_of(map_data_walkintimes[10]);
//			
//		}
//
//		if distanceToPark > 750 and age < 70 {
//			walkbalance <- one_of(map_data_walkinvalues[11]);
////			walktimes <- one_of(map_data_walkintimes[11]);
//			
//		}
//
//		if distanceToPark < 750 and scorehealth = "excellent" and age < 75 {
//			walkbalance <- one_of(map_data_walkinvalues[8]);
////			walktimes <- one_of(map_data_walkintimes[8]);
//			
//		}
//
//		if distanceToPark < 750 and scorehealth = "excellent" and age > 75 {
//			walkbalance <- one_of(map_data_walkinvalues[7]);
////			walktimes <- one_of(map_data_walkintimes[7]);
//			
//		}
//
//		if distanceToPark < 750 and scorehealth = "fair" and age > 75 {
//			walkbalance <- one_of(map_data_walkinvalues[4]);
////			walktimes <- one_of(map_data_walkintimes[4]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "good" and age > 75 {
//			walkbalance <- one_of(map_data_walkinvalues[4]);
////			walktimes <- one_of(map_data_walkintimes[4]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "good/bad" and age > 75 {
//			walkbalance <- one_of(map_data_walkinvalues[4]);
////			walktimes <- one_of(map_data_walkintimes[4]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "poor" and age > 75 {
//			walkbalance <- one_of(map_data_walkinvalues[4]);
////			walktimes <- one_of(map_data_walkintimes[4]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "fair" and age < 75 {
//			walkbalance <- one_of(map_data_walkinvalues[5]);
////			walktimes <- one_of(map_data_walkintimes[5]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "good" and age < 75 {
//			walkbalance <- one_of(map_data_walkinvalues[5]);
////			walktimes <- one_of(map_data_walkintimes[5]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "good/bad" and age < 75 {
//			walkbalance <- one_of(map_data_walkinvalues[5]);
////			walktimes <- one_of(map_data_walkintimes[5]);
//
//		}
//
//		if distanceToPark < 750 and scorehealth = "poor" and age < 75 {
//			walkbalance <- one_of(map_data_walkinvalues[5]);
////			walktimes <- one_of(map_data_walkintimes[5]);
//
//		}
//
//
//		
//		
//
//			
//		
//			
//		write name+walkbalance;
//	
//		walkbalance<-ratiowalking*walkbalance;
//		if dog = "yes" {
//		walkbalance <- walkbalance + 20;	
//		}
//		
//		}
	// below 5 minutes, the older_adult agents won't walk
		if walkbalance<5{
			donothing<-true;
		}
	// above 5 minutes, the older_adult agents will walk
		if walkbalance>5{
		resetwalkbalance<-walkbalance;
		weekbalance<-walkbalance*7;
		totalweekbalance<-weekbalance;
		home_range <- walkbalance * 60 * speed * 0.5;
		proximity<-length(parklist); // this is the case of the Batch experiment, when only one run is needed, this line need to be switched off ,while the code below " using topology till proximity<- length(Parks);" need to be swichted on.
// It is assumed that with the Batch experiment, the information on the parklist can be derived from the older_adult shp, in order to minimize computational time instead of calculating the distance of park within home range distance every run.
// the code below is needed for the first run in order to find the parks which are located within the home range of the older adult agents

//		using topology(road_network){
//		
//				Parks <- Park at_distance (home_range);
//				proximity <- length(Parks);
//		
//			
//	}
	
			}
			
			}


			
			}
			
// in the code below the older_adult agents are saved with the information of the walkbalance and parklist in a shp. This new shapefile need to be used for the Batch experiment in order to have fixed walking minutes during every run (walkbalance) and
// and in order to save computational time (the parks within home range are saved in a parklist attribute) this parklist attribute will be read from the new older_adult shapefile, instead of every run instantiliazed

//		reflex save_simulation when: (nb_persons =0) {
//						save older_adult to:"../includes/randompointswithParksList.shp" type:"shp" with:[gender::"gender",age::"age",speed::"speed",scorehealth::"scorehealth",resetwalkbalance::"walkbalance",Parks::"parklist"];

//		}	
	
		
	

	}


	
		

species roads {
	int WeightGreenAlongRoad;
	string TypeRoad; // as name suggests
	float WeightRoad;
	int GreenalongRoad; // Roads along green features don't have a value of 1. Only roads along Parks have a value of 1.
	int counter; // attribute for keeping track how often the road segment is visited  by older_adult agents
	
	
// below busy roads such as primary roads are given a lowering factor, the default value is 11
	init{switch TypeRoad{
		match "primary"
		{WeightRoad<-11*resfactor;}
		match "primary_link"
		{WeightRoad<-11*resfactor;}
		match "secondary"
		{WeightRoad<-11*resfactor;}
		match "tertiary"
		{WeightRoad<-11*resfactor;}
		match "cycleway"
		{WeightRoad<-11*resfactor;}
		default{
			WeightRoad<-11.0;
		}
	}
	
	
	}

	aspect geom {
		draw shape color: rgb("black");
	}

}



species older_adult skills: [moving] {
	
	// attributes of the older_adult agents
	string gender; 
	int age;
	int CID; 
	string scorehealth;
	string dog;
	bool donothing<-false;
	point start<-self.location;
	int walkbalance;
	int weekbalance;
	int totalweekbalance;
	float home_range;
	int resetwalkbalance;
	bool moves_back_home <- false;
	point my_target <-nil; //point target
	float targetdistance;
	float totaldistance<-0.0;
	
	
	
	// factors of older_adult agents  related to parks
	int proximity;
	float distanceToPark;
	int GreenalongRoad;
	float Greenminutes<-0.0;
	float weekGreenminutes<-0.0;
	float distanceGreenRoads<-0.0;
	bool GreenDestination <- false;
	
	
	//list of parks within home range
	 
	list<Park> Parks; // important during the first run when the parks within home range are yet unknown
	list<Park>Green;
	list parklist; // important from the second run on, when the parklist can be read from the older_adult shp
	

	//geometry of path
	geometry my_path;
	list<geometry> shp_path;
	path my_path_target;
	bool readyshp<-false;
	


//	//factors related to road
	
	// boolean of visiting a road
	bool RoadDestination <- false;
	
	


			
	reflex goestoOtherTarget when:  ( location=start and moves_back_home=false and donothing=false){
// IN case of the first run, the code below needs to switchedd on till line 437 ,whil the current  code line till 511 need to be switched off)	

//      // if number of park is zero, go to a road
//		if proximity = 0 {
//			my_target <- (one_of(roads at_distance (home_range)));
//			
//			RoadDestination <- true;
//			
//		}
//
//		//  if number of parks is 1, select that park
//		else if proximity = 1 {
//			my_target <- (Parks with_max_of (each.variablecounter)).location;
//			GreenDestination <- true;
//		}
//
//		//  if number of parks is more than 1, select the biggest park, with a probability of 0.7

//		else if proximity!=0 and proximity!=1 {
//			if flip(AttractParkProbality) {
//				my_target <- (Parks with_max_of (each.variablecounter)).location;
//				GreenDestination <- true;
//			} 
//			else {
//				my_target <- (one_of(Parks)).location;
//				GreenDestination <- true;
//			}
//
//		}

		// if number of parks is zero, go to a road	
		if proximity = 0 {
			my_target <- (one_of(roads at_distance (home_range)));
			
			RoadDestination <- true;
			
		}

		//  if number of parks is 1, select that park
		else if proximity = 1 {
			
			loop i over: parklist{

				loop j over: Park{
					if i=j.Name{
//						write j.Name;
						my_target <- j.location;
						GreenDestination <- true;
						
						
						
					
				}
		}
		}
		}

		//  if number of parks is more than 1, select the park which has the most conditions met
		else if proximity!=0 and proximity!=1 {
			if flip(AttractParkProbality) {
				int tempcounter<-0;
				loop i over: parklist{
	
						loop j over: Park{
							if i=j.Name{
//								write j.Name;
								if j.variablecounter>tempcounter{
									tempcounter<-j.variablecounter;
									my_target <- j.location;
									GreenDestination <- true;
		
						
						
					}
				}
				
		
		}
		}

			} 
			
			else {
				string name<-one_of(parklist);

					loop i over: Park{
						if name=i.Name{
							geometry chosenPark<-i;
						my_target <- i.location;
						GreenDestination <- true;
						
							
						}
					
					
				}

			}

		}
		
		if my_target!=nil and start!=nil and road_network!=nil{
		//drawing path between start location and target location
		my_path_target <- path_between(road_network,start, my_target);

		if my_path_target!=nil {
		// roads which overlap with the path of the older_adults will get +1 added to the counter attribute
		list<roads> r <- roads overlapping my_path_target.shape;
			
		loop rd over: r{
			if rd.GreenalongRoad=1 {
				
			 geometry Greenroad<-rd;
			 distanceGreenRoads<-distanceGreenRoads+Greenroad.perimeter;
			 }
			// +1 added to the counter variable of the roads
			 rd.counter<-rd.counter+1;
			 
			 			 
			

}

		// calculation minutes of exposure to Green
		Greenminutes<-(distanceGreenRoads)/(speed*step); 
		// calculating the distance of the path which is going to be walked		
		targetdistance<- my_path_target.distance;
		float TripLength<-(targetdistance/(speed*60));
		// calculating whether trip wil take more/less minutes than available walking minutes of the older_adult agent. In case the trip will take more minutes than available minutes, the older_adult agent will do nothing
		float interweekbalance<-weekbalance-(2* TripLength);
		if interweekbalance<=0{
			Greenminutes<-0.0;
			weekbalance<-0;
			donothing<-true;
		}
		if interweekbalance>0{
			weekbalance<-weekbalance-(2* TripLength);
		}

		}
		
	
	}}
			
			
		
		
		

	
	
	
	reflex moveToTarget when: (my_target!=nil and GreenDestination and weekbalance>0 and donothing=false) or (my_target!=nil and RoadDestination and weekbalance>0 and donothing=false) {
		if GreenDestination=true{
			// assess which park overlaps with the target
			 Green<- Park overlapping my_target;}


		if location = my_target and GreenDestination {
			// Park which overlaps with target will get +1 added to the parkcounter attribute
			loop g over: Green{
				
				g.parkcounter<-g.parkcounter+1;
			}
			// Add Greenminutes of the trip to the weekGreenminutes
			weekGreenminutes<-weekGreenminutes+Greenminutes;
			// Updating Greenminutes and Distance exposed to Green to 0
			Greenminutes<-0.0;
			distanceGreenRoads<-0.0;
			readyshp<-true;}
			
		if location = my_target and RoadDestination {
			readyshp<-true;
}

		 	
		if readyshp=true and my_path_target!=nil{

		 	
		 	//Add distance of the trip to the totaldistance
		 	totaldistance<-totaldistance+targetdistance;
		 	my_path <- (my_path union my_path_target.shape);
		 	

		 	moves_back_home <- true;
			my_target <- start;
//			write name + ": goes back home";
		 	
		 	readyshp<-false;

		 		}


		 		
		if location = start and moves_back_home {
			// Updating GreenDestination/RoadDestination to false
			if GreenDestination{
		 		GreenDestination<-false;
		 	}
		 	if RoadDestination{
		 		RoadDestination<-false;
		 		}

			moves_back_home<-false;


			
			
			}



		// code needed to go to the target
		path the_path <- self goto [target::my_target, on::road_network, recompute_path::false, return_path::true, move_weights::weights_map]; //weigthsmap needed or not
		
	}
	

	


	aspect base {
		draw geometry: circle(10) color: rgb("red");
		draw string(int(self)) color:#white font:font(20);
		draw link(self, my_target) color:#red;
		draw link(self, start) color:#blue;
	}

}

species buildings {
	string SES;
	rgb color <- #gray;

	aspect geom {
		draw shape color: color;
	}

}



species busstops {

	aspect geom {
		draw geometry: circle(5) color: rgb("black");
	}

}

species Park {
	float AREA; // area of the park
	int parkcounter; // how many visits by the older_adult agents
	int variablecounter; // states how many conditions have been met
	string NamePark;
	string Name;
	bool Forest;
	bool Pond;
	
	init {	
	

	
	}
	
	
	
	
	aspect geom {
		draw shape color: rgb("green");
	}

}


experiment walkexperiment type: gui {
	output {
		display arnhem_display type: java2D {
			species buildings aspect: geom;
			species roads aspect: geom;
			species Park aspect: geom;
			species older_adult aspect: base;
			//			species busstops aspect: geom;
			species busstops aspect: geom;
		}

	}

}



experiment 'Basic batch' type: batch repeat: 10 keep_seed: true until: nb_persons=0  {


		
	parameter 'AttractParkProbality' var: AttractParkProbality min:0.5 max:1.0 step:0.1;
	parameter 'ParkSizeThreshold' var: parksizethreshold min:50000 max:100000 step:10000;
	parameter 'restistance BusyRoads' var: resfactor min:0.3 max:0.8 step:0.1;



	reflex save_csv{

		
	
	ask simulations{
					ask Park{
		save[NamePark,parkcounter,variablecounter,AREA,AttractParkProbality,parksizethreshold, resfactor] to: "../includes/batchtrialv3/RoadFactor/parks/park.csv" type: "csv" rewrite:false ;	
		
		
		}
//		savepark<-true;

		
			ask roads{
		save[name,TypeRoad, WeightRoad, counter,AttractParkProbality,parksizethreshold, resfactor] to: "../includes/batchtrialv3/RoadFactor/roads/roads.csv" type: "csv" rewrite:false ;	
		 }
//		 saveroad<-true;
		
	
	
		ask older_adult{
		save [name, speed,resetwalkbalance, home_range, totaldistance,distanceToPark,proximity, totalweekbalance,AttractParkProbality,parksizethreshold, resfactor]  to: "../includes/batchtrialv3/RoadFactor/older_adult/older_adult.csv" type: "csv" rewrite:false ;		
		}
	}
		

	}
	}
	

	
 

 
 
 
	
	

