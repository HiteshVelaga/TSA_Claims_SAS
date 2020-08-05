%let outpath=/folders/myfolders/Output;
ods pdf file="&outpath/ClaimsReport.pdf" style=meadow pdftoc=1;

/*Accessing Data*/
ods proclabel "Accessing Data";
%let path=/folders/myfolders/ecrb94_ue/ECRB94/data;
libname tsa "&path";

options validvarname=v7;

proc import datafile="&path/TSAClaims2002_2017.csv"
			dbms=csv
			out=tsa.Claims
			replace;
			guessingrows=max;
run;

/*Exploring Data*/
ods proclabel "Exploring Data";
/*viewing top 50 rows in the tabel*/
proc print data=tsa.claims (obs=50);
run;
/*high level view of tabel*/
proc contents data=tsa.claims varnum;
run;

/*looking at columns*/
proc freq data=tsa.claims;
	tables claim_site disposition claim_type date_received incident_date / nocum nopercent;
	format date_received incident_date year4.
run;

/*Preparing Data*/
ods proclabel "Preparing Data";

/*Removing duplicates*/
proc sort data=tsa.claims out=tsa.claims_noDups noduprecs dupout=tsa.duplicates;
	by _all_;
run;

/*Cleaning Data*/
data tsa.claims_cleaned;
	set tsa.claims_nodups;
	if Claim_Site in ('-',' ') then Claim_Site="unknown";
	if Disposition in ('-',' ') then Disposition="unknown";
		else if Disposition="losed :Contractor Claim" then Disposition="Closed:Contractor Claim";
		else if Disposition="Closed :Canceled" then Disposition="Closed:Canceled";
	if Claim_Type in ('-',' ') then Claim_Type="unknown";
		else if Claim_Type="Passanger Property Loss/Personal Injur" then Claim_Type="Passanger Property Loss";
		else if Claim_Type="Passanger Property Loss/Personal Injury" then Claim_Type="Passanger Property Loss";
		else if Claim_Type="Property Damage/Personal Injury" then Claim_Type="Property Damage";
	State=upcase(State);
	StateName=propcase(StateName);
	if(Incident_Date>Date_Received or 
		Date_Received=. or 
		Incident_Date=. or 
		year(Incident_Date)<2002 or 
		year(Incident_Date)>2017 or 
		year(Date_Received)<2002 or 
		year(Date_Received)>2017) then Date_Issues="Needs Review";
	format Incident_Date Date_Received date9. Close_Ammount dollar20.2;
	label Airport_Code="Airport Code"
		Airport_Name="Airport Name"
		Claim_Number="Claim Number"
		Claim_Site="Claim Site"
		Claim_Type="Claim Type"
		Close_Amount="Close Amount"
		Date_Issues="Date Issues"
		Date_Received="Date Received"
		Incident_Date="Incident Date"
		Item_Category="Item Category";
	drop County City;
run;
	
proc freq data=tsa.claims_cleaned order=freq;
	tables claim_site disposition claim_type Date_Issues / nocum nopercent;
run;

/*Questions in this project*/
ods proclabel "Answering the questions"
/*How many date issues are there in total*/
proc freq data=tsa.claims_cleaned;
	tables Date_Issues / nocum nopercent;
run;
/*Ans:4241*/

/*How many claims per year of Incident date are there in the data*/
ods graphics on;
proc freq data=tsa.claims_cleaned;
	tables Incident_Date / nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;

/*What are the frequency values for claim type,claim site and disposition for a selected state.*/
%let state=California;

proc freq data=tsa.claims_cleaned order=freq;
	tables Claim_type Claim_Site Disposition / nocum nopercent;
	where StateName="&state" and Date_Issues is null;
run;

/*What is mean minimum maximum and sum of close amount for a selected state*/
proc means data=tsa.claims_cleaned mean min max sum maxdec=2;
	var Close_Amount;
	where StateName="&state" and Date_Issues is null;
run;

ods pdf close;
