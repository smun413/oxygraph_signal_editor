function signal_editor_gui
    % Create the GUI figure with normalized units
    fig = figure('Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8], 'Name', 'Signal Editor GUI', ...
        'Resize', 'on');  % Allow resizing

    % Axes to display original and processed signals
    ax1 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.05, 0.55, 0.75, 0.35]);
    title(ax1, 'Original Signal');
    
    ax2 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.05, 0.1, 0.75, 0.35]);
    title(ax2, 'Processed Signal');

    % Create a button to load the CSV file
    uicontrol('Style', 'pushbutton', 'String', 'Browse CSV', ...
        'Units', 'normalized', 'Position', [0.85, 0.7, 0.1, 0.05], 'Callback', @loadCSV);

    % Text area to display the folder name of the browsed file
    folderText = uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.05, 0.9, 0.5, 0.05], ...
        'String', 'Folder: None', 'HorizontalAlignment', 'left', 'FontSize', 8);

    % Create a button to mark regions
    uicontrol('Style', 'pushbutton', 'String', 'Mark Regions', ...
        'Units', 'normalized', 'Position', [0.85, 0.6, 0.1, 0.05], 'Callback', @markRegions);

    % Create a button to process the signal
    uicontrol('Style', 'pushbutton', 'String', 'Process Signal', ...
        'Units', 'normalized', 'Position', [0.85, 0.5, 0.1, 0.05], 'Callback', @processSignal);

    % Create a button to clear the marked regions
    uicontrol('Style', 'pushbutton', 'String', 'Clear Marks', ...
        'Units', 'normalized', 'Position', [0.85, 0.4, 0.1, 0.05], 'Callback', @clearMarks);

    % Create a button to add markers with labels on the processed signal
    uicontrol('Style', 'pushbutton', 'String', 'Add Marker', ...
        'Units', 'normalized', 'Position', [0.85, 0.3, 0.1, 0.05], 'Callback', @addMarker);

    % Create a button to save markers
    uicontrol('Style', 'pushbutton', 'String', 'Save Markers', ...
        'Units', 'normalized', 'Position', [0.85, 0.2, 0.1, 0.05], 'Callback', @saveMarkers);

   
% Variables to store data and graphical objects (for clearing marks)
data = [];
new_signal= [];
flux_signal = [];
new_flux_signal = [];  % To store processed  flux globally
x_values_for_reperfusion_points = [];
region_handles = [];  % To store handles of the marked regions
marker_handles = [];  % To store marker handles on the processed signal
labels = {};          % To store user-entered labels for markers
marker_coords = [];   % To store x-coordinates of the markers
chamber_prefix  ='';
current_folder_path = '';
signal_time=0;


    function resetAll()
        cla(ax1, 'reset')
        cla(ax2,'reset')
        x_values_for_reperfusion_points = [];  % Reset x_values_for_reperfusion_points to allow any number of regions
        data = [];
        new_signal= [];
        flux_signal = [];
        new_flux_signal = [];  % To store processed  flux globally
        x_values_for_reperfusion_points = [];
        labels = {};          % To store user-entered labels for markers
        marker_coords = [];   % To store x-coordinates of the markers
        chamber_prefix  ='';
    end

% Callback to browse and load CSV file
    function loadCSV(~, ~)
        [file, path] = uigetfile({'*.csv'}, 'Select oxygraph file');
        if file ~= 0
            resetAll
            signal_filename = strcat(fullfile(path), '\', 'signal.csv');
            current_folder_path = fullfile(path);
            A = xlsread(signal_filename);

            set(folderText, 'String', current_folder_path);  % Update folder name in text area

            % Create a dialog with two options
            choice = questdlg('Select an option:', ...
                'Option Selection', ...
                'Oxygen', 'Membrane Potential', 'Oxygen');  % Default selection is 'Option 1'

            % Handle the user response
            switch choice
                case 'Oxygen'
                    signal = A(:, 5);           %  signal
                    flux_signal  =  A(:, 6);    %  flux signal
                    data = signal;              % Store signal as data to be processed
                    chamber_prefix = 'chamber_A_';
                    signal_time = 2*length(signal);
                case 'Membrane Potential'
                    signal = A(:, 7);           %  signal
                    flux_signal  =  A(:, 8);    %  flux signal
                    data = signal;
                    chamber_prefix = 'chamber_B_';
                    signal_time = 2*length(signal);
                otherwise
                    disp('No option selected.');  % In case the user cancels
            end


            % Clear the axes before plotting (to avoid any overlay issues)
            cla(ax1);

            hold(ax1, 'on');
            yyaxis(ax1, 'left');
            plot(ax1, signal, 'b', 'LineWidth', 1.5);  % Plot the signal
            yyaxis(ax1, 'right');
            plot(ax1, flux_signal, 'r', 'LineWidth', 1.5);  % Plot flux signal
            hold(ax1, 'off');
            title(ax1, 'Original Signal');
        end
    end


% Callback to mark regions to remove from the plot
function markRegions(~, ~)
    if isempty(data)
        errordlg('Load the CSV file first!', 'File Error');
        return;
    end

    % Prompt user to select regions
    disp('Click to mark start and end of each region to remove');
    hold(ax1, 'on');

    while true
        % Get two x points using ginput
        [x, ~] = ginput(2);
        if length(x) < 2
            disp('Invalid selection. Please select two points.');
            continue;
        end

        % Convert the x-values to integers (no fractions)
        x = fix(x);  % 'fix' rounds towards zero, but you can use 'round' if preferred

        % Sort x-values to ensure proper ordering
        x = sort(x);
        x_values_for_reperfusion_points = [x_values_for_reperfusion_points; x'];

        % Mark the region on the plot by shading it
        yLimits = ylim(ax1);
        region_handle = fill([x(1) x(2) x(2) x(1)], [yLimits(1) yLimits(1) yLimits(2) yLimits(2)], ...
            'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'Parent', ax1);
        region_handles = [region_handles, region_handle];  % Store handle for clearing later

        % Ask the user if they want to continue marking regions
        choice = questdlg('Mark another region?', 'Continue', 'Yes', 'No', 'Yes');
        if strcmp(choice, 'No')
            break;
        end
    end
end



% Function to process both signals by removing marked regions
    function processSignal(~, ~)
        cla(ax2, 'reset');  % Clears all plots from the specified axes 'ax'

        if isempty(x_values_for_reperfusion_points)
            errordlg('No regions marked!', 'Error');
            return;
        end

        % Sort the marked regions by their starting x values
        x_values_for_reperfusion_points = sortrows(x_values_for_reperfusion_points);

        % Initialize new signals
        new_signal = [];
        new_flux_signal = [];
        current_start = 1;

        % Ensure signal and flux signal are column vectors for consistent concatenation
        data = data(:);         % Make sure signal is a column vector
        flux_signal = flux_signal(:);  % Make sure flux signal is a column vector

        % Process each marked region and remove the corresponding part of the signals
        for i = 1:size(x_values_for_reperfusion_points, 1)
            x1 = max(1, round(x_values_for_reperfusion_points(i, 1)));  % Ensure index is >= 1
            x2 = min(length(data), round(x_values_for_reperfusion_points(i, 2)));  % Ensure index does not exceed signal length

            % Append the unmarked part of both signals to the new signals
            if current_start < x1
                new_signal = [new_signal; data(current_start:x1-1)];
                new_flux_signal = [new_flux_signal; flux_signal(current_start:x1-1)];
            end
            current_start = x2 + 1;  % Move past the marked region
        end

        % Append any remaining unmarked data
        if current_start <= length(data)
            new_signal = [new_signal; data(current_start:end)];
            new_flux_signal = [new_flux_signal; flux_signal(current_start:end)];
        end

        % Plot the new signals on the second axes
        hold(ax2, 'on');
        yyaxis(ax2, 'left');
        plot(ax2, new_signal, 'b', 'LineWidth', 1.5);  % Plot the processed signal
        yyaxis(ax2, 'right');
        plot(ax2, new_flux_signal, 'r', 'LineWidth', 1.5);  % Plot the processed flux signal
        hold(ax2, 'off');
        title(ax2, 'Processed Signals (Marked Regions Removed)');
    end



% Function to add markers with labels on the processed signal
    function addMarker(~, ~)
        if isempty(new_signal)
            errordlg('Process the signal first!', 'Error');
            return;
        end

        % Get x-coordinate from the user via ginput
        [x, ~] = ginput(1);  % Only select one point
        x = round(x);  % Round to nearest integer for index

        % Get the label for this marker from the user
        prompt = {'Enter label for this marker:'};
        dlg_title = 'Marker Label';
        num_lines = 1;
        def = {''};
        answer = inputdlg(prompt, dlg_title, num_lines, def);

        if isempty(answer)
            disp('Marker label cancelled.');
            return;
        end
        label = answer{1};

        % Store the x coordinate and label
        marker_coords = [marker_coords; x];  % Store the x-coordinate
        labels = [labels, {label}];          % Store the user-entered label

        % Plot the marker on the processed signal in axes 2
        hold(ax2, 'on');
        yyaxis(ax2, 'left');
        marker_handle = plot(ax2, x, new_signal(x), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
        text(x, new_signal(x), label, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'g');
        marker_handles = [marker_handles, marker_handle];  % Store marker handle
        hold(ax2, 'off');
    end

% Function to clear all marked regions and markers
    function clearMarks(~, ~)

        cla(ax1, 'reset')
        cla(ax2,'reset')
        marker_coords=[];
        labels = {};

        if ~isempty(region_handles)
            delete(region_handles);  % Remove all region handles from the plot
            region_handles = [];     % Clear the handle storage
            x_values_for_reperfusion_points = [];           % Reset the stored x-values
        end

        if ~isempty(marker_handles)
            delete(marker_handles);  % Remove all marker handles from the plot
            marker_handles = [];     % Clear the marker handle storage
            marker_coords = [];      % Reset the marker coordinates
            labels = {};             % Reset the marker labels
        end
    end

% Function to save the marked points and labels to a text file
% Function to save the marked points and labels to a text file
function saveMarkers(~, ~)
    if isempty(marker_coords) || isempty(labels) || isempty(x_values_for_reperfusion_points)
        errordlg('No markers or reperfusion points to save!', 'Error');
        return;
    end

    % Format the titration points
    titration_points = sprintf('%d,', marker_coords);
    titration_points = titration_points(1:end-1); % Remove trailing comma

    % Format the labels
    point_text = '';
    for i = 1:length(labels)
        point_text = [point_text, '''', labels{i}, ''''];  % Append each label
        if i ~= length(labels)
            point_text = [point_text, ','];
        end
    end

    % Format the reperfusion points as pairs, using %f to avoid scientific notation
    reperfusion_pairs = sprintf('%.0f,%.0f;', x_values_for_reperfusion_points');
    reperfusion_pairs = reperfusion_pairs(1:end-1); % Remove trailing semicolon

    % Open or create the file for reading and writing
    file_name = strcat(current_folder_path, '/', 'points.txt');

    if exist(file_name, 'file')
        file_contents = fileread(file_name); % Read existing file contents
    else
        file_contents = ''; % Create empty contents if file does not exist
    end

    % Prepare the variable names for writing/replacing
    titration_points_variable_name = strcat(chamber_prefix, 'tritration_points_x_coordinates = [%s];\n');
    point_text_variable_name = strcat(chamber_prefix, 'tritration_points_text = {%s};\n');
    reperfusion_points_variable_name = strcat(chamber_prefix, 'reperfusion_points = [%s];\n');
    time_variable_name =  'time = %d ;\n';
    time_value_line = sprintf(time_variable_name, signal_time); % Create the new variable line

    % Create the new content
%     new_content = '';
%     new_content = [new_content, sprintf(titration_points_variable_name, titration_points)];
%     new_content = [new_content, sprintf(point_text_variable_name, point_text)];
%     new_content = [new_content, sprintf(reperfusion_points_variable_name, reperfusion_pairs)];
%     


    % Update the file contents (replace or append)
    file_contents = replace_or_add(file_contents, chamber_prefix, ...
        titration_points_variable_name, point_text_variable_name, reperfusion_points_variable_name, ...
        titration_points, point_text, reperfusion_pairs);

     % Append new variable if not found
     file_contents = [file_contents, time_value_line];

    % Write back to the file
    fileID = fopen(file_name, 'w');
    if fileID == -1
        errordlg('Could not open file for writing.', 'Error');
        return;
    end
    fprintf(fileID, '%s', file_contents); % Write updated content back to file
    fclose(fileID);

    msgbox('Markers saved successfully to points.txt', 'Success');
end


% Helper function to replace or append new variable contents
    function file_contents = replace_or_add(file_contents, chamber_prefix, titration_var, text_var, reperfusion_var, titration_points, point_text, reperfusion_pairs)
        % Replace or add titration points
        file_contents = replace_or_append_var(file_contents, titration_var, chamber_prefix, titration_points);

        % Replace or add point text
        file_contents = replace_or_append_var(file_contents, text_var, chamber_prefix, point_text);

        % Replace or add reperfusion points
        file_contents = replace_or_append_var(file_contents, reperfusion_var, chamber_prefix, reperfusion_pairs);

        
    end

% Function to replace or append the variable in the text
    function file_contents = replace_or_append_var(file_contents, var_template, chamber_prefix, var_value)
        % Extract variable name from the template
        var_name = extractBefore(var_template, ' =');
        full_var_name = strcat(chamber_prefix, var_name);
        var_pattern = strcat(full_var_name, ' = .*?;\n');  % Regex pattern for the variable

        new_var_line = sprintf(var_template, var_value); % Create the new variable line

        if contains(file_contents, full_var_name)
            % Replace existing variable
            file_contents = regexprep(file_contents, var_pattern, new_var_line);
        else
            % Append new variable if not found
            file_contents = [file_contents, new_var_line];
        end
    end


end
