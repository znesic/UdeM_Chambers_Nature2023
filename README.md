# Voigt2023_CH4_uptake

***
## Description
This repository contains the codes produced for the article "Arctic soil methane sink stimulated by plant respiration and dry conditions" by Carolina Voigt, Anna-Maria Virkkala, Gabriel Hould Gosselin, Kathryn Bennett, T. Andrew Black, Charles Chevrier-Dion, Georg Guggenberger, Wasi Hashmi, Dan Kou, Charlotte Marquis, Philip Marsh, Maija Marushchak, Zoran Nesic, Hannu Nykänen, Taija Saarela, Leopold Sauheitl, Branden Walker, Niels Weiss, Evan J. Wilcox, Oliver Sonnentag.

## Affiliated scientific institutions
1. Department of Environmental and Biological Sciences, University of Eastern Finland, P.O. Box 1627, 70211 Kuopio, Finland
2. Département de géographie & Centre d’études nordiques, Université de Montréal, 1375 Avenue Thérèse-Lavoie-Roux, Montréal, QC H2V 0B3, Canada
3. Woodwell Climate Research Center, 149 Woods Hole Road, Falmouth, MA 02540-1644, USA
4. Department of Geography and Environmental Studies & Cold Regions Research Centre, Wilfrid Laurier University, 75 University Avenue West, Waterloo, ON N2L 3C5, Canada
5. Faculty of Land and Food Systems, University of British Columbia, 248-2357 Main Mall, Vancouver, BC V6T 1Z4, Canada
6. Institute of Soil Science, Leibniz University Hanover, Herrenhäuser Str. 2, 30419 Hanover, Germany
7. Northwest Territories Geological Survey, P.O. Box 1320, Yellowknife, NT X1A 2L9, Canada

## Corresponding authors
In case you have any question about the code and/or analyses presented in this repository, please contact Carolina Voigt (carolina.voigt@uef.fi) and Zoran Nesic (zoran.nesic@ubc.ca).

## Installation
This software is written in MATLAB. Running the code (.m and .mlapp files) and loading the data files (.mat files) requires the pre-installation of [MATLAB](/https://www.mathworks.com/products/matlab.html). In addition to the core Matlab, the software needs these additional toolboxes:
1. Signal Processing Toolbox
2. Optimization Toolbox
3. Curve Fitting Toolbox

IMPORTANT: The repository only contains one day of raw data (Aug 2, 2019) that can be used for testing of the flux calculation code. 

The program has been tested with Matlab 2020a in Windows 10 environment.

## Code Usage
To replicate the data processing steps and the results, the operator has to first download the whole repository. Then, withing the Matlab environment, the user needs to navigate to the folder where the repository was downloaded to. 

Assuming that the repository has been downloaded to C:/Voigt2023 folder, the user can use this command to change the current Matlab folder and to setup the environment:

```
cd C:/Voigt2023
setup_UdeM_calc.m
```
### Flux calculations
The raw data from the gas analyzer is stored in: C:/Voigt2023/data/met-data/data/190802 folder. The raw met data from Campbell Scientific dataloggers is stored in C:/Voigt2023/data/met-data/csi_net folder.

To process Aug 2, 2019 raw data and obtain the fluxes, use this command:
```
dataStruct = run_UdeM_ACS_calc_one_day(datenum(2019,8,2),false,true);
```
Processing of one day of data can take a long time. The results of the data processing for this date have been provided in the folder:  C:/Voigt2023/data/met-data/hhour (file: 20190803_recalcs_UdeM.mat). User can interrupt the data processing at any time by pressing CTRL+C.

To check the data quality, the quality of the slope fitting and for the comparison between different slope fitting methods, one can use the following graphical user interface:
```
GUI_visualize_one_fit
``` 
(select Aug 2, 2019, click on "Load data", select the chamber and the hour of the day, then click "Run")

Another way to look at the data is to use UdeM_show_one_run function:
```
load .\data\met-data\hhour\20190803_recalcs_UdeM.mat
UdeM_show_one_run(dataStruct,2,10,'exp_B')
```

### QC processing:
This next function can only be run with the real dataset (with the data/all_chambers.mat file), which can be requested by contacting Carolina Voigt (carolina.voigt@uef.fi).

```
UdeM_QC_2019
```
Note: In addition to the above, additional data filtering has been done using an Excel spreadsheet. This additional data filtering and processing has been documented in the manuscript.
