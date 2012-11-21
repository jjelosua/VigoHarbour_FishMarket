VigoHarbour_FishMarket - scrape
==========================================

Description
-----------

*VigoHarbour_FishMarket* is a free software ruby application used to scrape the information from the [Vigo Harbour Fish Market][1]

In order to extract the information the following steps are needed executed in the following order.

1.- execute scrapeFishMarketDates - (downloads the html pages with information searching through the dates
from 2007 until 2012. It seems that there is no data available before 03/30/2007.
input: none
output: html pages on the ../html folder
logs: information regarding warnings or unexpected results are stored in ../logs/

2.- execute processFishMarketInfo - (extracts the information from the html into 4 CSV style text files depending
on the category of the information)
input: html pages extracted from the previous step inside the ../html folder.
output: CSV documents on the ../csv folder
  -lfData.csv : Information on the amount of landed fish for the available dates
  -lsData.csv : Information on the amount of landed seafood for the available dates
  -fmData.csv : Information of the fluctuation in price of the fish auction for the available dates.
  -sData.csv : Information on the total number of ships that have unloaded cargo on the harbour for the available dates.  
logs: information regarding warnings or unexpected results are stored in ../logs/

Requirements
------------

You need the have a running version of ruby in your computer (only tested on ruby 1.9.3p194 but it should work in older versions, if it doesn't please report a bug) 

Reporting bugs
--------------

Please use the issue [reporting tool in github][2]

License
-------

*PuertoVigoFishMarket* is released under the terms of the [Apache License version 2.0][3].

Please read the ``LICENSE`` file for details.

Authors
-------

Please see ``AUTHORS`` file for more information about the authors.



[1]: http://www.apvigo.com/control.php?sph=a_iap=1351%%p_rpp=1
[2]: https://github.com/jjelosua/VigoHarbour_FishMarket/issues
[3]: http://www.apache.org/licenses/

