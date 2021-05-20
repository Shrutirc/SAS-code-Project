/** "Final Project DSCI 5340- Predictive Analytics and Business Forecasting"**/

Title "Traffic Volume Prediction On Metro Interstate I-94";

Title "
Team Members: Shruti Chandna (Student ID: 11384407)
              Shweta Batra (Student ID:   11359697)";



%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '/home/u42026377/i94Data/Metro_Interstate_Traffic_Volume.csv';

/** Import Original data file **/
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;


/**Display the contents of data set **/
PROC CONTENTS DATA=WORK.IMPORT; RUN;


%web_open_table(WORK.IMPORT);

/**Extracting date from dateTime variable and creating a new variable for date **/
data WORK.IMPORT;
set WORK.IMPORT;
date1 = datepart(date_time);
format date1 date9.;
run;

/**Converting all hourly observations to daily observations by Calculating 
average of all numeric variables**/  
proc MEANS data=WORK.IMPORT MEAN noprint;
class date1;
var traffic_volume clouds_all rain_1h snow_1h temp ;
Output Out=DailyAvgTraffic(drop = _type_ _freq_) mean= /autoname autolabel;
run;

/** deleting first observation**/
data DailyAvgTraffic;
set DailyAvgTraffic;
IF _N_ = 1 THEN DELETE;
run;

proc TIMEID data=DailyAvgTraffic outintervaldetails=outint print=values;
id date1 interval=day;
ods output Decomposition = decomp;
run;

/** Show count of missing values between 2 available values**/
proc print data=decomp;
	where Span > 1;
run;

/** Line plot visualization of original data **/
Title "Time Series Plot ";
proc sgplot  data=DailyAvgTraffic;
series x=date1 y=traffic_volume_Mean;
run;

/** Deleting first 662 observation due to large number of missing values between 2 dates**/
data DailyAvgTraffic;
set DailyAvgTraffic;
IF _N_ < 662 THEN DELETE;
run;

proc timeseries data=DailyAvgTraffic out=DailyAvgTrafficWithMissingValues;
id date1 interval=day;
var traffic_volume_Mean clouds_all_Mean rain_1h_Mean snow_1h_Mean temp_Mean;
run;

/** Imputing the missing values with mean**/
proc stdize data=DailyAvgTrafficWithMissingValues out=DailyAvgTrafficVolComplete reponly method=mean;
var traffic_volume_Mean clouds_all_Mean rain_1h_Mean snow_1h_Mean temp_Mean;
run;

proc timeseries data=DailyAvgTrafficVolComplete plot=series;
   id date1 interval=day;
   var traffic_volume_Mean;
run;

/*-- Seasonal Model/Trend Model for Traffic Volume Data --*/
proc arima data=DailyAvgTrafficVolComplete;            /** To check if there is short term (weekly) trend/seasonality **/
   identify var=traffic_volume_Mean nlag=28;
run;

proc arima data=DailyAvgTrafficVolComplete;            /** To check if there is long term seasonality before lag 364**/
   identify var=traffic_volume_Mean nlag=363;
run;

proc arima data=DailyAvgTrafficVolComplete;
   identify var=traffic_volume_Mean nlag=364;          /**to detect Long term seasonality **/
run;

proc arima data=DailyAvgTrafficVolComplete plots=forecast(forecasts); 
   identify var=traffic_volume_Mean(364);              /** Long term seasonality Removal**/
   run;
   
   identify var=traffic_volume_Mean(1,364);            /** First order differencing**/
   run;
   
   identify var=traffic_volume_Mean(1,364) stationarity=(adf);/** Augmented Dickey Fuller Test to check series stationarity**/
   run;
   
   estimate p=1;                                       /**AR 1 Model**/
   run;
   estimate q=1;                                       /**MA 1 Model**/
   run;
   estimate p=1 q=1;                                   /**ARMA 1,1 Model**/
   run; 
   estimate p=1 q=2;                                   /**ARMA 1,2 Model**/
   run; 
   estimate p=2 q=2;                                   /**ARMA 2,2 Model**/
   run; 
   estimate p=4 q=3;                                   /**ARMA 4,3 Model**/
   run; 
   estimate p=4 q=4;                                   /**ARMA 4,4 Model**/
   run; 
   estimate p=2 q=1;                                   /**ARMA 2,1 Model**/
   run;   
   
   forecast lead=28 interval=day id=date1 out=forecastResults; /**Forecast for next 4 weeks(28 days)**/
run;

