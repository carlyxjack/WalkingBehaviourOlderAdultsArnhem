/**
* Name: walkingv6
* Author: Joy van Vliet
* Description: 
* Tags: Roads, Green Spaces, Attractiveness, Walking
*/
model walkmodel

/* Insert your model definition here */
global {
//shapefile features respectively
	file roads_shapefile <- file("../includes/psa07RoadWithPark_4.shp");
	file buildings_shapefile <- file("../includes/a08BuildingswithSES.shp");
	file Park_shapefile <- file("../includes/psa04GreenPark.shp");
//	file supermarket_shapefile <- file("../includes/pr_supermarketspoints.shp");
	file busstops_shapefile <- file("../includes/pr_sonnsbeek_busstops.shp");
	file sample_csv <- csv_file("../includes/SampleData.csv", ",");
	file people_shapefile<-file("../includes/Peopledata_csv Events_2.shp");

	//convert the file into a matrix	
	matrix<int> data <- matrix<int>(sample_csv);
	int nb_leaf <- 15;
	map<int, list<int>> map_data_walkinvalues;
	map<int, list<int>> map_data_walkintimes;
	
	// create list of roads
	map<string, int> map_roads_visited;
	

	// creating a shape of the environment
	geometry shape <- envelope(roads_shapefile);
	//Graph of the road network
	graph road_network;
	// weights roads
	map<roads, float> weights_map;
	float step <- 60 #sec; //can change cycle time
	string type;
	//	geometry p;
	int nb_persons -> length(older_adult where(each.donothing=false));
	float weightfactorRoad<-1.0;
	float big_park_threshold <- 0.5;
//	float sizefactor<-0.2;
	int parksizethreshold<-50000;
	int weightqualityforest<-10;
	int weightqualitypond<-10;
//	int Greenminutes;


	init {
		write "model started";
		loop leaf from: 0 to: nb_leaf {
			list<int> walkingValues <- [];
			list<int> walkingtimes <- [];
			loop i from: 0 to: data.rows - 1 {
				if (data[2, i] = leaf) {
					add data[0, i] to: walkingValues;
					add data[1, i] to: walkingtimes;
					
				}

			}

			put walkingValues key: leaf in: map_data_walkinvalues;
			put walkingtimes key: leaf in: map_data_walkintimes;
			
		}

		create buildings from: buildings_shapefile with: [SES: string(read("SES"))] {
		}

		create roads from: clean_network(roads_shapefile.contents,0,true,true) with: [WeightRoad::float(read("TotalWeigh")), GreenalongRoad::int(read("GreenAlong"))];
		create busstops from: busstops_shapefile;
//		create supermarkets from: supermarket_shapefile;
		//road_network <- as_edge_graph(roads);
		create Park from: Park_shapefile with: [NamePark::string(read("PARKNAAM_L")),Forest::string(read("DoesHaveFo")),Pond::string(read("doeshavepo")), oppervlakte::float(read("Shape_Area"))];

		//		create busstops from: busstops_shapefile;
		
		weights_map <- roads as_map (each::(1.0 * (100 - weightfactorRoad*each.WeightRoad)));
		road_network <- (as_edge_graph(roads)) with_weights weights_map;
		

	create older_adult from: people_shapefile with:[
		scorehealth::string(read("scorehealt")), dog::string(read("dog")), gender::string(read("gender")), age::float(read("age")), walkbalance::int(read(("Walkingmin")))
	];
	
		
	}

	reflex stop_simulation when: (nb_persons = 0) {
		
		
	//		save [map_roads_visited ] to: "../includes/roadsvisited_simulation"+".csv" type: "csv" rewrite: true;

		save roads to:  "../includes/roads_with_frequency_simulation.shp" type: "shp" with: [name::"NameOfRoad",WeightRoad::"WeightRoad",counter::"Frequency_visit"];
		save Park to:  "../includes/parks_freq.shp" type: "shp" with: [name::"nameofpark",WeightPark::"weightpark",parkcounter::"Frequency_visit"];
		ask older_adult{
		save  [name,speed,resetwalkbalance,home_range, distanceToPark,proximity, totaldistance, totalweekbalance,weekGreenminutes] to: "../includes/older_adult.csv" type: "csv" rewrite:false ;		
		}
		do pause;
		}
	

	}





		
		

species roads {
	int WeightRoad;
	int GreenalongRoad;
	int counter;
	

	aspect geom {
		draw shape color: rgb("black");
	}

}

species shpfile {

	aspect k {
		draw shape + 50 color: #orange;
	}

}

species older_adult skills: [moving] {
	
	// attributes of the older_adult agents
	string gender;
	float age;
	string scorehealth;
	float avg_speed;
	string dog;
	bool donothing<-false;
	point start<-self.location;
	


	//startlocation
//	point start;

	//Target point of the agent
	point my_target <-nil; //point target

	// how many minutes walking per day
	int walkbalance;
	
	//real balance based on survey from the participant self
	
	int realbalance;
	//reset walkbalance;
	float resetwalkbalance;
	
	// week balance
	int weekbalance;
	
	//total week balance
	int totalweekbalance;
	
	// how many trips
//	int walktimes;
	
	//goes back home
	bool moves_back_home <- false;

	// total distance in meters the agent can cover
	float home_range;
	
	// distance to target
	float targetdistance;
	


	//total distance
	float totaldistance<-0.0;
	
	//number of times walking
	
	int number<-0;
	
	
	// factors related to parks
	
	//distance to closet Park
	float distanceToPark;
	
	// proximity of parks
	int proximity;
	
	//factors related to exposure to Green along roads  
//	float Greenminutes;
	int GreenalongRoad;
	float Greenminutes;
	float weekGreenminutes<-0.0;
	float distanceGreenRoads<-0.0;
	
	//geometry of parks
	geometry BigPark;
	geometry OtherPark;
	
	//list of parks within home range
	list<Park> Parks;
	


	// boolean of visiting a park
	bool GreenDestination <- false;
	
//	//add one
//	int addone;
	
	//geometry of path
	geometry my_path;
	list<geometry> shp_path;
	path my_path_target;
	bool readyshp<-false;
	


	
	

	

//	//factors related to road
	
	// boolean of visiting a road
	bool RoadDestination <- false;
	
	float ratiowalking<-0.4;
	


	

	

	init {
		if gender="male"{
			avg_speed<-1.46;}
		else if gender="female"{
			avg_speed<-1.53;
		}
		
		using topology(road_network) {
//			distanceToPark <- distance_to(self.start, (Park) closest_to self.start);
			distanceToPark <- Park min_of (start distance_to each);

			write name +"has an distance to green is" +distanceToPark;


			
			}
		
		
		
		
		//Regression Tree
		if walkbalance = nil{
		if distanceToPark > 750 and age > 70 {
			walkbalance <- one_of(map_data_walkinvalues[10]);
//			walktimes <- one_of(map_data_walkintimes[10]);
			
		}

		if distanceToPark > 750 and age < 70 {
			walkbalance <- one_of(map_data_walkinvalues[11]);
//			walktimes <- one_of(map_data_walkintimes[11]);
			
		}

		if distanceToPark < 750 and scorehealth = "excellent" and age < 75 {
			walkbalance <- one_of(map_data_walkinvalues[8]);
//			walktimes <- one_of(map_data_walkintimes[8]);
			
		}

		if distanceToPark < 750 and scorehealth = "excellent" and age > 75 {
			walkbalance <- one_of(map_data_walkinvalues[7]);
//			walktimes <- one_of(map_data_walkintimes[7]);
			
		}

		if distanceToPark < 750 and scorehealth = "fair" and age > 75 {
			walkbalance <- one_of(map_data_walkinvalues[4]);
//			walktimes <- one_of(map_data_walkintimes[4]);

		}

		if distanceToPark < 750 and scorehealth = "good" and age > 75 {
			walkbalance <- one_of(map_data_walkinvalues[4]);
//			walktimes <- one_of(map_data_walkintimes[4]);

		}

		if distanceToPark < 750 and scorehealth = "good/bad" and age > 75 {
			walkbalance <- one_of(map_data_walkinvalues[4]);
//			walktimes <- one_of(map_data_walkintimes[4]);

		}

		if distanceToPark < 750 and scorehealth = "poor" and age > 75 {
			walkbalance <- one_of(map_data_walkinvalues[4]);
//			walktimes <- one_of(map_data_walkintimes[4]);

		}

		if distanceToPark < 750 and scorehealth = "fair" and age < 75 {
			walkbalance <- one_of(map_data_walkinvalues[5]);
//			walktimes <- one_of(map_data_walkintimes[5]);

		}

		if distanceToPark < 750 and scorehealth = "good" and age < 75 {
			walkbalance <- one_of(map_data_walkinvalues[5]);
//			walktimes <- one_of(map_data_walkintimes[5]);

		}

		if distanceToPark < 750 and scorehealth = "good/bad" and age < 75 {
			walkbalance <- one_of(map_data_walkinvalues[5]);
//			walktimes <- one_of(map_data_walkintimes[5]);

		}

		if distanceToPark < 750 and scorehealth = "poor" and age < 75 {
			walkbalance <- one_of(map_data_walkinvalues[5]);
//			walktimes <- one_of(map_data_walkintimes[5]);

		}

	}
		walkbalance<-ratiowalking*walkbalance;
		if dog = "yes" {
		walkbalance <- walkbalance + 20;	
		}
		resetwalkbalance<-walkbalance;
		weekbalance<-walkbalance*7;
		totalweekbalance<-weekbalance;
		home_range <- walkbalance * 60 * avg_speed * 0.5;
		
		
		using topology(road_network){
		
					Parks <- Park at_distance (home_range);
		

		
		

			}}
	
			

			
	reflex goestoOtherTarget when:  ( location=start and moves_back_home=false and donothing=false){
		


		
		
		proximity <- length(Parks);
	
		if proximity = 0 {
			my_target <- (one_of(roads at_distance (home_range)));
			
			RoadDestination <- true;
			
		}

		//  if number of parks is more than 1, select the biggest park, with a probability of 0.7
		else if proximity = 1 {
			my_target <- (Parks with_max_of (each.WeightPark)).location;
			GreenDestination <- true;
		}

		// if number of parks is zero, go to a road
		else if proximity!=0 and proximity!=1 {
			if flip(big_park_threshold) {
				my_target <- (Parks with_max_of (each.WeightPark)).location;
				GreenDestination <- true;
			} 
			else {
				my_target <- (one_of(Parks)).location;
				GreenDestination <- true;
			}

		}
		
		if my_target!=nil and start!=nil and road_network!=nil{
		my_path_target <- path_between(road_network,start, my_target);

		if my_path_target!=nil {
		list<roads> r <- roads overlapping my_path_target.shape;
			
		loop rd over: r{
			if rd.GreenalongRoad=1 {
				
			 geometry Greenroad<-rd;
			 distanceGreenRoads<-distanceGreenRoads+Greenroad.perimeter;
			 write distanceGreenRoads;}
			 rd.counter<-rd.counter+1;
			 put rd.counter  key: rd.name in: map_roads_visited;
			 
			 
//			 Roads.counter<-Roads.counter+1;
			 
			

}
		
		Greenminutes<-(distanceGreenRoads)/(avg_speed*step); //eventueel 2*
		
		targetdistance<- my_path_target.distance;
		float TripLength<-(targetdistance/(avg_speed*60));
		float interweekbalance<-weekbalance-(2* TripLength);
		if interweekbalance<=0{
			weekbalance<-0;
			donothing<-true;
		}
		if interweekbalance>0{
			weekbalance<-weekbalance-(2* TripLength);
		}

		}
		
	
	}}
			
			
		
		
		

	
	
	
	reflex moveToTarget when: (my_target!=nil and GreenDestination and weekbalance>0 and donothing=false) or (my_target!=nil and RoadDestination and weekbalance>0 and donothing=false) {

			

		



		if location = my_target and GreenDestination {
			list<Park> green<- Park overlapping my_target;
			loop g over: green{
				g.parkcounter<-g.parkcounter+1;
			}
			weekGreenminutes<-weekGreenminutes+Greenminutes;
			Greenminutes<-0.0;
			distanceGreenRoads<-0.0;
			readyshp<-true;}
			
		if location = my_target and RoadDestination {
			readyshp<-true;
}

		 	
		if readyshp=true and my_path_target!=nil{

		 	
		 	
		 	totaldistance<-totaldistance+targetdistance;
		 	my_path <- (my_path union my_path_target.shape);
		 	
//		 	create shpfile from: my_path;
//		 		
//		 	save shpfile to:  "../includes/path_of_"+name+".shp" type: "shp" with: [name::"name"];
		 	moves_back_home <- true;
			my_target <- start;
//			write name + ": goes back home";
		 	
		 	readyshp<-false;

		 		}


		 		
		if location = start and moves_back_home {
			if GreenDestination{
		 		GreenDestination<-false;
		 	}
		 	if RoadDestination{
		 		RoadDestination<-false;
		 		}
		 	
//			walktimes<-walktimes-1;	
			moves_back_home<-false;

//			save [name, speed,resetwalkbalance, home_range, distanceToPark,proximity, totaldistance, totalweekbalance,weekGreenminutes] to: "../includes/results_simulation.csv" type: "csv" rewrite: false;
	
			


			
			
			}



		//this does the trick
		//        path my_path <-  self goto target: targetLocation on: road_network recompute_path: false return_path: true;// move_weights: weights_map;
		path the_path <- self goto [target::my_target, on::road_network, recompute_path::false, return_path::true, move_weights::weights_map]; //weigthsmap needed or not
		
	}
	


	aspect base {
		draw geometry: circle(50) color: rgb("red");
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

//species supermarkets {
//
//	aspect geom {
//		draw geometry: circle(5) color: rgb("orange");
//	}
//
//}

species busstops {

	aspect geom {
		draw geometry: circle(5) color: rgb("black");
	}

}

species Park {
	float oppervlakte;
	int parkcounter;
	float weightsize;
	string NamePark;
	float WeightPark;
	int weightquality<-0;
	

	string Forest;
	string Pond;
	
	init {
		loop elements over: Park{
//			if elements.shape.area>parksizethreshold{
//				weightsize<-20.0;
//			if elements.shape.area<parksizethreshold{
//				weightsize<-20.0*sizefactor;
			if elements.Forest="true"{
				weightquality<-weightquality+weightqualityforest;
				
			}
			if elements.Pond="true"{
				weightquality<-weightquality+weightqualitypond;
			}
			
			}
				
			
			
			
		
		WeightPark<-weightsize+weightquality;
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
//			species supermarkets aspect: geom;
			species busstops aspect: geom;
		}

	}

}



experiment 'Basic batch' type: batch repeat: 2 keep_seed: true until: nb_persons=0   {




	parameter 'weightfactor of roads:' var: weightfactorRoad min:1.0 max:2.0 step: 0.5;	
	parameter 'BigParkProbability' var: big_park_threshold among:[0.5,0.7,0.9];
//	parameter 'weightsize' var: sizefactor among: [0.2,0.4,0.6];
//	parameter 'ParkSizeThreshold' var: parksizethreshold among:[50000,100000];
	parameter 'FeaturesForest' var: weightqualityforest among: [10,20,30];
//	parameter 'FeaturePond' var: weightqualitypond among: [10,20,30];
	
	
 

 reflex save_shpfiles {
 ask simulations{
 
 save roads to:  "../includes/batch/RoadsFreq_"+"_WR_"+weightfactorRoad+"_threshold_"+big_park_threshold+"_WQF_"+weightqualityforest+"_WQP_"+weightqualitypond+".shp" type: "shp" with: [name::"NameOfRoad",WeightRoad::"WeightRoad",counter::"Frequency_visit"];
 save Park to: "../includes/batch/Park_Freq"+"_WR_"+weightfactorRoad+"_threshold_"+big_park_threshold+"_WQF_"+weightqualityforest+"_WQP_"+weightqualitypond+".shp" type: "shp" with: [NamePark::"nameofpark",WeightPark::"weightpark",parkcounter::"Frequency_visit"];
 ask older_adult{
 save [name, avg_speed,resetwalkbalance, home_range, distanceToPark,proximity, totaldistance, totalweekbalance,weekGreenminutes]  to: "../includes/batch/older_adult_"+"_WR_"+weightfactorRoad+"_threshold_"+big_park_threshold+"_WQF_"+weightqualityforest+"_WQP_"+weightqualitypond+".csv" type: "csv" rewrite:false ;		
 }
 }}}	
	
	

