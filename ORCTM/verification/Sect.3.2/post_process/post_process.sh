#!/bin/sh
rm *.nc
cdo -f nc selindexbox,3,1002,3,3 -setgrid,r1004x5 ../fort.72 sal.nc
cdo -f nc selindexbox,3,1003,3,3 -setgrid,r1005x5 ../fort.73 uuu.nc
cdo -f nc selindexbox,3,1002,3,3 -setgrid,r1004x5 ../fort.146 www.nc
cdo -f nc copy ../GRID_INFO.ext GRID_INFO.nc

cdo -f nc copy ../diagnosis/diagnosis.72_007 sal_01.nc
cdo -f nc copy ../diagnosis/diagnosis.72_014 sal_02.nc
cdo -f nc copy ../diagnosis/diagnosis.72_021 sal_03.nc
cdo -f nc copy ../diagnosis/diagnosis.72_028 sal_04.nc

cdo -f nc copy ../diagnosis/diagnosis.73_007 uko_01.nc
cdo -f nc copy ../diagnosis/diagnosis.73_014 uko_02.nc
cdo -f nc copy ../diagnosis/diagnosis.73_021 uko_03.nc
cdo -f nc copy ../diagnosis/diagnosis.73_028 uko_04.nc

cdo -f nc copy ../diagnosis/diagnosis.146_007 woo_01.nc
cdo -f nc copy ../diagnosis/diagnosis.146_014 woo_02.nc
cdo -f nc copy ../diagnosis/diagnosis.146_021 woo_03.nc
cdo -f nc copy ../diagnosis/diagnosis.146_028 woo_04.nc
