clc
clear all
close all


folder = 'C:\Users\smun413\OneDrive - The University of Auckland\Shared-folder\Data\Oxygraph\csv files\2024-10-08 P1-01_human_13_10_2mg_atp_mp';

% Load the data from the .m file
points_filename = strcat(folder,'\','points.m');
run(points_filename);


signal_filename = strcat( folder,'\','signal.csv');
A = xlsread (signal_filename);

%% Chamber A

% chamber A signals
o2_A = A(:,5);
o2_flux_A = A(:,6);
atp_A = A(:,9);
atp_flux_A = A(:,10);

signals = {o2_A,o2_flux_A,atp_A,atp_flux_A};
smoothing_window_sizes  = [60,60,20,20];
reperfusion_points =  chamber_A_reperfusion_points;
tritration_points = {chamber_A_tritration_points_x_coordinates,chamber_A_tritration_points_text};

plot_oxygraph_signals(signals, smoothing_window_sizes,reperfusion_points,tritration_points,0,time)



%% Chamber B

%chamber B signals
o2_B = A(:,7);
o2_flux_B = A(:,8);
saf_B = A(:,11);
saf_flux_B = A(:,12);

signals = {o2_B,o2_flux_B,saf_B,saf_flux_B};
smoothing_window_sizes  = [30,30,10,10];
reperfusion_points =  chamber_B_reperfusion_points;
tritration_points = {chamber_B_tritration_points_x_coordinates,chamber_B_tritration_points_text};

plot_oxygraph_signals(signals, smoothing_window_sizes,reperfusion_points,tritration_points,1,time)


