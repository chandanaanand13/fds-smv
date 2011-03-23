#!/bin/bash -f

export SVNROOT=`pwd`/../..
export FDS=$SVNROOT/FDS_Compilation/intel_linux_64/fds_intel_linux_64
export RUNFDS=$SVNROOT/Utilities/Scripts/runfds.sh
export BASEDIR=`pwd`
export INDIR=Current_Results

# uncomment following line to stop all cases
#export STOPFDS=1

/bin/sh -c "cp $BASEDIR/FDS_Input_Files/*.fds $BASEDIR/$INDIR"

$RUNFDS $INDIR USCG_HAI_250_kW_Closed_Grinnell
$RUNFDS $INDIR USCG_HAI_500_kW_Closed_Grinnell
$RUNFDS $INDIR USCG_HAI_1000_kW_Closed_Grinnell
$RUNFDS $INDIR USCG_HAI_250_kW_Natural_Grinnell
$RUNFDS $INDIR USCG_HAI_500_kW_Natural_Grinnell
$RUNFDS $INDIR USCG_HAI_1000_kW_Natural_Grinnell
$RUNFDS $INDIR USCG_HAI_250_kW_Forced_Grinnell
$RUNFDS $INDIR USCG_HAI_500_kW_Forced_Grinnell
$RUNFDS $INDIR USCG_HAI_1000_kW_Forced_Grinnell

