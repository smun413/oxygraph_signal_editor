function  plot_oxygraph_signals(signals, smoothing_window_sizes,reperfusion_points,tritration_points,is_mp, time)

% extracting signals
chamber_X_o2 = signals{1};
chamber_X_o2_flux = signals{2};
chamber_X_amp =  signals{3};
chamber_X_amp_slope = signals{4};

% Initialize indices to keep
keep_indices = true(size(chamber_X_o2));

reperfusion_points(reperfusion_points<1) = 1;

% Loop through each pair of reperfusion points and mark indices to remove
for i = 1:size(reperfusion_points, 1)
    keep_indices(reperfusion_points(i,1):reperfusion_points(i,2)) = false;
end

% Create new signals without the points between reperfusion points
new_chamber_X_o2 = chamber_X_o2(keep_indices);
new_chamber_X_o2_flux = chamber_X_o2_flux(keep_indices);
new_chamber_X_amp = chamber_X_amp(keep_indices);
new_chamber_X_amp_slope  = chamber_X_amp_slope(keep_indices);

%apply a smoothing filter
new_chamber_X_o2_smoothened = movmean (new_chamber_X_o2,smoothing_window_sizes(1));
new_chamber_X_o2_flux_smoothened = movmean (new_chamber_X_o2_flux,smoothing_window_sizes(2));
new_chamber_X_o2_flux_smoothened = filloutliers(new_chamber_X_o2_flux_smoothened,"center","quartiles");
new_chamber_X_amp_smoothened = movmean (new_chamber_X_amp,smoothing_window_sizes(3));
new_chamber_X_amp_slope_smoothened = movmean (new_chamber_X_amp_slope,smoothing_window_sizes(4));
% new_chamber_X_amp_slope_smoothened =filloutliers(new_chamber_X_amp_slope_smoothened,"clip") ;

signal_length = length(new_chamber_X_o2_smoothened);
xt = 0:(time/signal_length):time-1;

% adjusting the tritration points
tritration_points_new = floor(tritration_points{1,1}*(time/signal_length));
tritration_points{1,1} = tritration_points_new;

%% oxygen plots
%if no membrane potential
if is_mp == 0
    
    figure,
    yyaxis left;
    h1=plot(xt,new_chamber_X_o2_smoothened,'LineWidth', 2,'Color', 'blue', 'DisplayName','O_2 concentration');  ylabel({'O_2 concentration';'(µmol l^{-1})'});
    ylim([0 200]);
    % plot_points(new_chamber_X_o2_smoothened,tritration_points)
    
    yyaxis right;
    h2=plot(xt,new_chamber_X_o2_flux_smoothened,'LineWidth', 2,'Color', 'red', 'DisplayName','O_2 flux'); ylabel({'O_2 flux'; '(pmol s^{-1} mg^{-1})'});
    ylim([0 70]);
%     xlim([3050 10100]);
    xlabel('Time(s)');
    plot_points(new_chamber_X_o2_flux_smoothened,tritration_points,time,20);
    
    % Adjust y-axis colors
    yyaxis left;
    set(gca, 'YColor', 'blue');

    yyaxis right;
    set(gca, 'YColor', 'red');
    
    legend([h1, h2], {'O_2 concentration', 'O_2 flux'});
    set(gca, 'FontWeight', 'bold'); 
    set(gca, 'FontSize', 20); 
    
    %% amp plots
    
    calibration_factor = 2.15;
    new_chamber_X_amp_slope_smoothened = calibration_factor * new_chamber_X_amp_slope_smoothened;
    figure,
    yyaxis left;
    h3=plot(xt,new_chamber_X_amp_smoothened,'LineWidth', 2,'Color',[0.0, 0.502, 0.502] ); ylabel({'ATP' ; '(µmol l^{-1})'});
%     ylim([0 7000]);
    
    yyaxis right;
    h4=plot(xt,new_chamber_X_amp_slope_smoothened,'LineWidth', 2,'Color',[1.0, 0.271, 0.0] ); ylabel({'ATP flux' ; '(pmol s^{-1} mg^{-1})'}),ylim([-500 500]), xlabel('Time(s)');
    ylim([-5000 5000]);
%     xlim([3500 10100]);
    plot_points(new_chamber_X_amp_smoothened,tritration_points,time,20)
    xlabel('Time(s)');
    
      % Adjust y-axis colors
    yyaxis left;
    set(gca, 'YColor', [0.0, 0.502, 0.502]);

    yyaxis right;
    set(gca, 'YColor', [1.0, 0.271, 0.0]);
    
    legend([h3, h4], {'ATP', 'ATP flux'});
    set(gca, 'FontWeight', 'bold');
    set(gca, 'FontSize', 20); 
    
else %if membrane potential    
    figure,
    h5=plot(xt,new_chamber_X_amp_smoothened,'LineWidth', 2,"color", [0.4940 0.1840 0.5560]); ylabel('Safranine-O fluorescence (AU)');
    ylim([1000 2000]);
%     xlim([3250 10100]);
    xlabel('Time(s)');
    plot_points(new_chamber_X_amp_smoothened,tritration_points,time,1500)
    
    legend(h5, 'Safranine-O fluorescence');
    set(gca, 'FontWeight', 'bold');
    set(gca, 'FontSize', 20); 
    
end


end
