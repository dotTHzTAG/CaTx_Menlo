classdef AcquisitionDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AcquisitionDialogUIFigure       matlab.ui.Figure
        Image                           matlab.ui.control.Image
        SystemReadyLampLabel            matlab.ui.control.Label
        SystemReadyLamp                 matlab.ui.control.Lamp
        MeasurementDetailsPanel         matlab.ui.container.Panel
        ResetIntervalTimeButton         matlab.ui.control.Button
        MetaDescriptionEditField        matlab.ui.control.EditField
        MetaDescriptionEditFieldLabel   matlab.ui.control.Label
        ResetMetadataTableButton        matlab.ui.control.Button
        MetadataCountSpinner            matlab.ui.control.Spinner
        MetadataCountSpinnerLabel       matlab.ui.control.Label
        UITable                         matlab.ui.control.Table
        ResetAverageNumberButton        matlab.ui.control.Button
        csvLOADButton                   matlab.ui.control.Button
        TemporalMeasurementFileLabel    matlab.ui.control.Label
        STOPButton                      matlab.ui.control.Button
        ACQUIREButton                   matlab.ui.control.Button
        DescriptionEditField            matlab.ui.control.EditField
        DescriptionEditFieldLabel       matlab.ui.control.Label
        ModeDropDown                    matlab.ui.control.DropDown
        ModeDropDownLabel               matlab.ui.control.Label
        SampleEditField                 matlab.ui.control.EditField
        SampleEditFieldLabel            matlab.ui.control.Label
        ReferenceAcquisitionPanel       matlab.ui.container.Panel
        RemoveReferenceButton           matlab.ui.control.Button
        ReferenceButton                 matlab.ui.control.Button
        ReferenceLamp                   matlab.ui.control.Lamp
        ReferenceLampLabel              matlab.ui.control.Label
        RemoveBaselineButton            matlab.ui.control.Button
        BaselineButton                  matlab.ui.control.Button
        BaselineLamp                    matlab.ui.control.Lamp
        BaselineLampLabel               matlab.ui.control.Label
        SubtractCheckBox                matlab.ui.control.CheckBox
        MeasurementSettingsPanel        matlab.ui.container.Panel
        IntervalEditField               matlab.ui.control.NumericEditField
        Intervalateverygivensecondset0fornointervalEditFieldLabel  matlab.ui.control.Label
        TimesecEditField                matlab.ui.control.NumericEditField
        TimesecEditFieldLabel           matlab.ui.control.Label
        AverageNumberEditField          matlab.ui.control.NumericEditField
        IntervalsecLabel                matlab.ui.control.Label
        MeasurementCountEditField       matlab.ui.control.NumericEditField
        MeasurementCountEditFieldLabel  matlab.ui.control.Label
        MultiscanSwitch                 matlab.ui.control.Switch
        MultiscanSwitchLabel            matlab.ui.control.Label
        StatusEditField                 matlab.ui.control.EditField
        StatusButton                    matlab.ui.control.Button
    end

    
    properties (Access = private)
        MainApp % Main app
        numAcq % total number of acquisitions
        matBaseline % Baseline matrix [time stamps; amplitudes]
        matReference % Reference matrix [time stamps; amplitudes]
        processStop % Is Stop-button pressed?
        TcellNew % Newly acquired data cell
        instrumentProfile
        userProfile
        thzVer
        group
        mdVal
        mdDescription
        %#exclude Profiles.json
        %#exclude Configuration.json
        %#exclude measurements.csv
        %#exclude progress.txt
    end
    
    methods (Access = private)
        
        function updateMain(app)
            % Call main app's public function
            updateTableRemote(app.MainApp,app.TcellNew);
        end
      
        function addMeasurement(app,fileLoad)
                numAcq = app.numAcq;
                fig = app.AcquisitionDialogUIFigure;
                refOption = false;
                curCol = getSizeofTable(app.MainApp);
                mdNum = app.MetadataCountSpinner.Value;
                mdDescription = app.mdDescription;
                metadataTable = app.UITable.Data;
                mdVal = cell(6,1);

                if mdNum>0
                    for idx = 1:mdNum
                        mdVal(idx) = metadataTable{idx,5};
                    end
                end
                       
                if fileLoad
                    measMat = readWaveformFile(app);
                else
                    measMat = readWaveform(app,refOption);
                end                

                if isempty(measMat)    
                    %errordlg("No measurement data");
                    return;
                end
                
                try
                    timeAxis = table2array(measMat(1,2:end));
                    eAmp = table2array(measMat(2:end,2:end));
                    timeStamps = table2array(measMat(2:end,1));
                    clear("measMat");
                catch
                    errordlg("Failed to read the measurement data");
                    return;
                end

                measNum = size(eAmp,1);
                TcellNew = cell(22,measNum);
                numAcq = numAcq + measNum;
                digitNum = ceil(log10(measNum+1));
                digitNumFormat = strcat('%0',num2str(digitNum),'d');

                for idx = 1:measNum
                    if isempty(app.SampleEditField.Value)
                        sampleName = sprintf(digitNumFormat,curCol+idx);
                    else
                        sampleName = strcat(app.SampleEditField.Value,'_',sprintf(digitNumFormat,idx));
                    end

                    if isempty(app.DescriptionEditField.Value)
                        description = [];
                    else
                        description = app.DescriptionEditField.Value;
                    end

                    mode = app.ModeDropDown.Value;
                    timeStamp = timeStamps(idx);
                    datetimeValue = datetime(timeStamp, 'ConvertFrom', 'posixtime');
                    datetimeValue.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                    datetimeValue = char(datetimeValue);
                    matBaseline = app.matBaseline;
                    matRefernece = app.matReference;

                    % Baseline subtraction check
                    if app.SubtractCheckBox.Value
                        if isempty(matBaseline)
                            uialert(fig,'No valid baseline','Acquisition aborted');
                            return;
                        end
                        if ~isempty(matRefernece)
                            try
                                matRefernece(2,:) = matRefernece(2,:) - matBaseline(2,:);
                            catch
                                uialert(fig,'Inconsist data length','Baseline subtraction aborted');
                                return;
                            end
                        end

                        if ~isempty(eAmp)
                            try
                                eAmp(idx,:) = eAmp(idx,:) - matBaseline(2,:);
                            catch
                                uialert(fig,'Inconsist data length','Baseline subtraction aborted');
                                return;
                            end
                        end
                    end

                    dsDescription = "Sample"; % dataset description
                    ds1 = [timeAxis;eAmp(idx,:)];

                    if ~isempty(matRefernece)
                        ds2 = [matRefernece(1,:);matRefernece(2,:)];
                        dsDescription = strcat(dsDescription,',',"Reference");
                    else
                        ds2 = [];
                    end

                    if ~app.SubtractCheckBox.Value && ~isempty(matBaseline)
                        dsDescription = strcat(dsDescription,',',"Baseline");
                        ds3 = [matBaseline(1,:);matBaseline(2,:)];
                    else
                        ds3 = [];
                    end

                    TcellNew{1,idx} = curCol+idx;
                    TcellNew{2,idx} = sampleName;
                    TcellNew{3,idx} = description;
                    TcellNew{4,idx} = '';
                    TcellNew{5,idx} = '';
                    TcellNew{6,idx} = datetimeValue; % measurement start time
                    TcellNew{7,idx} = mode; % THz-TDS/THz-Imaging/Transmission/Reflection
                    TcellNew{8,idx} = []; % coordinates

                    TcellNew{9,idx} = mdDescription; % Metadata description
                    TcellNew{10,idx} = mdVal{1};
                    TcellNew{11,idx} = mdVal{2};
                    TcellNew{12,idx} = mdVal{3}; 
                    TcellNew{13,idx} = mdVal{4}; 
                    TcellNew{14,idx} = mdVal{5}; 
                    TcellNew{15,idx} = mdVal{6};
                    TcellNew{16,idx} = [];
                    TcellNew{17,idx} = [];

                    TcellNew{18,idx} = dsDescription; % Dataset description
                    TcellNew{19,idx} = ds1;
                    TcellNew{20,idx} = ds2;
                    TcellNew{21,idx} = ds3; 
                    TcellNew{22,idx} = []; 
                end
                app.TcellNew = TcellNew;
                app.numAcq = numAcq;
                app.ACQUIREButton.Enable = "on";
        end
        
        function measMat = readWaveform(app,refOption)
            measAverage = app.AverageNumberEditField.Value;
            measTime = app.TimesecEditField.Value;
            measCount = app.MeasurementCountEditField.Value;
            measMode = app.MultiscanSwitch.Value;
            intervalTime = app.IntervalEditField.Value;
            pythonScript = 'getPulse.py';
            progressFile = 'progress.txt';
            delete(progressFile);
            pause(0.5);
            measurementFile = 'measurements.csv';
            runPython = true;
            measMat =[];
            
            if refOption
                command = sprintf('python %s --average %i --count %i &', pythonScript, measAverage, 1);
                mode = "Reference/Baseline measurement";
            else
                if isequal(measMode,'count')
                    command = sprintf('python %s --average %i --count %i --interval %i &', pythonScript, measAverage, measCount, intervalTime);
                else
                    command = sprintf('python %s --average %i --time %i --interval %i &', pythonScript, measAverage, measTime, intervalTime);
                end
                mode = "Sample measurement";
            end

            msg = strcat(mode," started");
            app.StatusEditField.Value = msg;
            drawnow

            system(command);
            pause(2.5);
            
            while runPython
                pause(0.5);
                try
                    msg = fileread(progressFile);
                catch
                    msg = "Python run error!";
                    runPython = false;
                end
                if app.processStop
                    msg = "Measurement aborted!";
                    runPython = false;
                end
                if contains(msg,'done')
                    msg = "Measurement done!";
                    runPython = false;
                    measMat = readtable(measurementFile);
                end
                app.StatusEditField.Value = msg;
                drawnow
            end
        end
        
        function measMat = readWaveformFile(app)
            [file, filepath] = uigetfile('*.csv',"Select Waveform CSV File");

            if isequal(file,0)
                return;
            end

            fullpath = strcat(filepath,file);

            try
               measMat = readtable(fullpath);
            catch
                errordlg("Failed to read measurements.csv.")
               return;
            end
            
        end
        
        function loadMetaTable(app)
            group.t1 = categorical({'-','Sample','Reference'});
            group.t2 = categorical({'-','Thickness','Diameter','Weight','Temperature','Volume','Concentration','Refractive Index','Molar Mass'});
            group.Thickness = categorical({'m','cm','mm','μm','nm'});
            group.Diameter = categorical({'cm','mm','μm'});
            group.Weight = categorical({'g','mg','μg','ng'});
            group.Temperature = categorical({'K','°C','°F'});
            group.Volume = categorical({'ml','μl','nl'});
            group.Concentration = categorical({'%'});
            group.MolarMass = categorical({'g/mol'});
            app.group = group;

            col1 = {'md1';'md2';'md3';'md4';'md5';'md6'};
            col2 = {group.t1(1);group.t1(1);group.t1(1);group.t1(1);group.t1(1);group.t1(1)};
            col3 = {group.t2(1);group.t2(1);group.t2(1);group.t2(1);group.t2(1);group.t2(1)};
            col4 = {'-';'-';'-';'-';'-';'-'};
            col5 = {0;0;0;0;0;0};

            MetaTableData = table(col1,col2,col3,col4,col5);
            app.UITable.Data = MetaTableData;
            MetadataCountSpinnerValueChanged(app);
        end
        
        function updateMDDescription(app)
            metaTableData = app.UITable.Data;
            mdNum = app.MetadataCountSpinner.Value;
            mdDescription = '';
            if mdNum == 0
                app.mdDescription = '';
                app.MetaDescriptionEditField.Value = '';
                return;
            end
            noUnits = {'Refractive Index','-'};
            app.mdVal = {};

            for idx = 1:mdNum 
               rowContent = '';
               if ~isequal(string(metaTableData{idx,2}),'-')
                   rowContent = strcat(rowContent,string(metaTableData{idx,2}),'_');
               end
               if ismember(string(metaTableData{idx,3}),noUnits)
                   rowContent = strcat(rowContent,string(metaTableData{idx,3}));
               else
                   rowContent = strcat(rowContent,string(metaTableData{idx,3}),'(',string(metaTableData{idx,4}),')');
               end
               if idx < mdNum
                   rowContent = strcat(rowContent,", ");
               end
               mdDescription = strcat(mdDescription,rowContent);
            end
            app.MetaDescriptionEditField.Value = mdDescription;
            app.mdDescription = mdDescription;
        end
        
        
        function readStatus(app)
            pythonScript = 'getStatus.py';
            statusFile = 'status.txt';
            command = sprintf('python %s', pythonScript);
            system(command);
            pause(0.5);            
            try
                msg = fileread(statusFile);
            catch
                msg = [];
            end

            if isempty(msg) || contains(msg,{'Error','Uninitialized'})
                app.SystemReadyLamp.Color = [0.85,0.33,0.10];
                app.SystemReadyLampLabel.Text = "Not Ready";
                msg = "ScanControl is not connetect.";
            else
                app.SystemReadyLamp.Color = "Green";
                app.SystemReadyLampLabel.Text = "Ready";
            end
            app.StatusEditField.Value = msg;
            delete(statusFile);
            drawnow
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp)
            % Store main app object
            app.MainApp = mainapp;
            app.numAcq = 0;
            
            try 
                profileFile = 'Profiles.json';
                profileData = jsondecode(fileread(profileFile));
                app.instrumentProfile = profileData.defaultInstrument;
                app.userProfile = profileData.defaultUser;
            catch ME            
                app.instrumentProfile = '';
                app.userProfile = '';
            end

            try
                configFile = 'Configuration.json';
                configData = jsondecode(fileread(configFile));
                app.thzVer = configData.thzVer;
            catch ME            
                app.thzVer = '';
            end
            loadMetaTable(app);
            readStatus(app);
        end

        % Close request function: AcquisitionDialogUIFigure
        function AcquisitionDialogUIFigureCloseRequest(app, event)
            % Enable Acquire button in main app, if the app is still open
            if isvalid(app.MainApp)
                app.MainApp.AcquirefromTeraSmartButton.Enable = "on";
                app.MainApp.DeployDataButton.Enable = "on";
                app.MainApp.ClearMemoryButton.Enable = "on";
            end

            % Delete the dialog box
            delete(app)            
        end

        % Button pushed function: ACQUIREButton
        function ACQUIREButtonPushed(app, event)
            app.SystemReadyLamp.Color = [0.85,0.33,0.10];
            app.SystemReadyLampLabel.Text = "Scaning...";
            app.processStop = false;
            fileLoad = false;
            app.ACQUIREButton.Enable = "off";
            drawnow

            addMeasurement(app,fileLoad);
            app.SystemReadyLamp.Color = "Green";
            app.SystemReadyLampLabel.Text = "Ready";
            drawnow         

            % Update Main App table
            updateTableRemote(app.MainApp,app.TcellNew);
        end

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            app.MeasurementCountEditField.Value = 1;
            app.TimesecEditField.Value = 0;
            app.ACQUIREButton.Enable = "on";
            app.processStop = true;
        end

        % Button pushed function: BaselineButton
        function BaselineButtonPushed(app, event)
            refOption = true;
            try
                measMat = readWaveform(app,refOption);
                timeAxis = table2array(measMat(1,2:end));
                eAmp = table2array(measMat(2,2:end));
                app.matBaseline = [timeAxis;eAmp];
            catch
                app.BaselineLamp.Color = [0.85,0.33,0.10];
                return
            end

            app.BaselineLamp.Color = "Green";

        end

        % Button pushed function: ReferenceButton
        function ReferenceButtonPushed(app, event)
            refOption = true;
            try
                measMat = readWaveform(app,refOption);
                timeAxis = table2array(measMat(1,2:end));
                eAmp = table2array(measMat(2,2:end));
                app.matReference = [timeAxis;eAmp];
            catch
                app.ReferenceLamp.Color = [0.85,0.33,0.10];
                return
            end

            app.ReferenceLamp.Color = "Green";
        end

        % Button pushed function: RemoveBaselineButton
        function RemoveBaselineButtonPushed(app, event)
            app.matBaseline = [];
            app.BaselineLamp.Color = [0.85,0.33,0.10];
        end

        % Button pushed function: RemoveReferenceButton
        function RemoveReferenceButtonPushed(app, event)
            app.matReference = [];
            app.ReferenceLamp.Color = [0.85,0.33,0.10];
        end

        % Value changed function: MultiscanSwitch
        function MultiscanSwitchValueChanged(app, event)
            value = app.MultiscanSwitch.Value;
            app.IntervalEditField.Value = 0;

            if isequal(value,'count')
                app.TimesecEditField.Editable = "off";
                app.MeasurementCountEditField.Editable = "on";
                app.MeasurementCountEditField.BackgroundColor = [0.302 0.7451 0.9333];
                app.TimesecEditField.BackgroundColor = [1,1,1];
            else % time mode
                app.TimesecEditField.Editable = "on";
                app.TimesecEditField.BackgroundColor = [0.302 0.7451 0.9333];
                app.MeasurementCountEditField.BackgroundColor = [1,1,1];
                app.MeasurementCountEditField.Editable = "off";

            end

            app.TimesecEditField.Value = 0;
            app.MeasurementCountEditField.Value = 1;
        end

        % Button pushed function: csvLOADButton
        function csvLOADButtonPushed(app, event)
            fileLoad = true;
            app.StatusEditField.Value = "Loading waveform from csv file";
            addMeasurement(app,fileLoad);
            drawnow;

            % Update Main App table
            app.StatusEditField.Value = "Updating the main table";
            updateTableRemote(app.MainApp,app.TcellNew);
            drawnow;
            app.StatusEditField.Value = "The main table is updated!";
        end

        % Button pushed function: ResetAverageNumberButton
        function ResetAverageNumberButtonPushed(app, event)
            app.AverageNumberEditField.Value = 1;
        end

        % Value changed function: MetadataCountSpinner
        function MetadataCountSpinnerValueChanged(app, event)
            value = app.MetadataCountSpinner.Value;
            sWtBg = uistyle("BackgroundColor","white"); % white background style
            sDGrBg = uistyle("BackgroundColor",[0.8,0.8,0.8]); % dark grey background style
            addStyle(app.UITable,sWtBg,"row",[(1:6)]);
            addStyle(app.UITable,sDGrBg,"row",[(value+1:7)]);
            if value == 6
                return;
            end
            metaTableData = app.UITable.Data;
            group = app.group;
            for idx = value+1:6
                metaTableData(idx,2:5) = table({group.t1(1)},{group.t2(1)},{'-'},{0});
            end
            app.UITable.Data = metaTableData;
            updateMDDescription(app);
        end

        % Button pushed function: ResetMetadataTableButton
        function ResetMetadataTableButtonPushed(app, event)
            app.MetadataCountSpinner.Value = 0;
            loadMetaTable(app)
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            indices = event.Indices;
            newData = event.NewData;
            group = app.group;
            metaTableData = app.UITable.Data;
            if indices(2) == 3
                switch newData
                    case 'Thickness' 
                        metaTableData(indices(1),4) = table({group.Thickness(3)});
                    case 'Weight'
                        metaTableData(indices(1),4) = table({group.Weight(2)});
                    case 'Temperature'
                        metaTableData(indices(1),4) = table({group.Temperature(1)});
                    case 'Volume'
                        metaTableData(indices(1),4) = table({group.Volume(1)});
                    case 'Concentration'
                        metaTableData(indices(1),4) = table({group.Concentration(1)});
                    case 'Molar Mass'
                        metaTableData(indices(1),4) = table({group.MolarMass(1)});
                    case 'Diameter'
                        metaTableData(indices(1),4) = table({group.Diameter(2)});
                    otherwise
                        metaTableData(indices(1),4) = {'-'};
                end
            end
            app.UITable.Data = metaTableData;
            updateMDDescription(app); 
        end

        % Selection changed function: UITable
        function UITableSelectionChanged(app, event)
            selection = app.UITable.Selection;
            if selection(1) > app.MetadataCountSpinner.Value || selection(2) == 1
                app.UITable.ColumnEditable = false;
            else
                app.UITable.ColumnEditable = true;
            end
        end

        % Button pushed function: ResetIntervalTimeButton
        function ResetIntervalTimeButtonPushed(app, event)
            app.IntervalEditField.Value = 0;
        end

        % Button pushed function: StatusButton
        function StatusButtonPushed(app, event)
            try
                readStatus(app)
            catch
                return;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create AcquisitionDialogUIFigure and hide until all components are created
            app.AcquisitionDialogUIFigure = uifigure('Visible', 'off');
            app.AcquisitionDialogUIFigure.Position = [100 100 497 761];
            app.AcquisitionDialogUIFigure.Name = 'TeraSmart Control';
            app.AcquisitionDialogUIFigure.Icon = fullfile(pathToMLAPP, 'Images', 'icon.png');
            app.AcquisitionDialogUIFigure.CloseRequestFcn = createCallbackFcn(app, @AcquisitionDialogUIFigureCloseRequest, true);

            % Create StatusButton
            app.StatusButton = uibutton(app.AcquisitionDialogUIFigure, 'push');
            app.StatusButton.ButtonPushedFcn = createCallbackFcn(app, @StatusButtonPushed, true);
            app.StatusButton.FontWeight = 'bold';
            app.StatusButton.Position = [17 724 59 27];
            app.StatusButton.Text = 'Status';

            % Create StatusEditField
            app.StatusEditField = uieditfield(app.AcquisitionDialogUIFigure, 'text');
            app.StatusEditField.Editable = 'off';
            app.StatusEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.StatusEditField.Position = [86 725 389 26];

            % Create MeasurementSettingsPanel
            app.MeasurementSettingsPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.MeasurementSettingsPanel.Title = 'Measurement Settings';
            app.MeasurementSettingsPanel.FontWeight = 'bold';
            app.MeasurementSettingsPanel.Position = [16 596 467 119];

            % Create MultiscanSwitchLabel
            app.MultiscanSwitchLabel = uilabel(app.MeasurementSettingsPanel);
            app.MultiscanSwitchLabel.HorizontalAlignment = 'center';
            app.MultiscanSwitchLabel.FontWeight = 'bold';
            app.MultiscanSwitchLabel.Position = [15 68 64 22];
            app.MultiscanSwitchLabel.Text = 'Multi-scan';

            % Create MultiscanSwitch
            app.MultiscanSwitch = uiswitch(app.MeasurementSettingsPanel, 'slider');
            app.MultiscanSwitch.Items = {'count', 'time'};
            app.MultiscanSwitch.ValueChangedFcn = createCallbackFcn(app, @MultiscanSwitchValueChanged, true);
            app.MultiscanSwitch.FontWeight = 'bold';
            app.MultiscanSwitch.Position = [126 68 43 19];
            app.MultiscanSwitch.Value = 'count';

            % Create MeasurementCountEditFieldLabel
            app.MeasurementCountEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.MeasurementCountEditFieldLabel.HorizontalAlignment = 'right';
            app.MeasurementCountEditFieldLabel.FontWeight = 'bold';
            app.MeasurementCountEditFieldLabel.Position = [248 67 120 22];
            app.MeasurementCountEditFieldLabel.Text = 'Measurement Count';

            % Create MeasurementCountEditField
            app.MeasurementCountEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.MeasurementCountEditField.Limits = [0 100000];
            app.MeasurementCountEditField.ValueDisplayFormat = '%.0f';
            app.MeasurementCountEditField.FontWeight = 'bold';
            app.MeasurementCountEditField.BackgroundColor = [0.302 0.7451 0.9333];
            app.MeasurementCountEditField.Position = [374 67 67 22];
            app.MeasurementCountEditField.Value = 1;

            % Create IntervalsecLabel
            app.IntervalsecLabel = uilabel(app.MeasurementSettingsPanel);
            app.IntervalsecLabel.HorizontalAlignment = 'right';
            app.IntervalsecLabel.FontWeight = 'bold';
            app.IntervalsecLabel.Position = [12 39 101 22];
            app.IntervalsecLabel.Text = 'Average Number';

            % Create AverageNumberEditField
            app.AverageNumberEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.AverageNumberEditField.Limits = [0 10000];
            app.AverageNumberEditField.ValueDisplayFormat = '%.0f';
            app.AverageNumberEditField.FontWeight = 'bold';
            app.AverageNumberEditField.BackgroundColor = [0.9294 0.6941 0.1255];
            app.AverageNumberEditField.Position = [120 39 66 22];
            app.AverageNumberEditField.Value = 1;

            % Create TimesecEditFieldLabel
            app.TimesecEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.TimesecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimesecEditFieldLabel.FontWeight = 'bold';
            app.TimesecEditFieldLabel.Position = [249 39 64 22];
            app.TimesecEditFieldLabel.Text = 'Time (sec)';

            % Create TimesecEditField
            app.TimesecEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.TimesecEditField.Limits = [0 100000];
            app.TimesecEditField.ValueDisplayFormat = '%.0f';
            app.TimesecEditField.Editable = 'off';
            app.TimesecEditField.FontWeight = 'bold';
            app.TimesecEditField.Position = [374 39 67 22];

            % Create Intervalateverygivensecondset0fornointervalEditFieldLabel
            app.Intervalateverygivensecondset0fornointervalEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.Intervalateverygivensecondset0fornointervalEditFieldLabel.HorizontalAlignment = 'right';
            app.Intervalateverygivensecondset0fornointervalEditFieldLabel.FontWeight = 'bold';
            app.Intervalateverygivensecondset0fornointervalEditFieldLabel.Position = [60 10 306 22];
            app.Intervalateverygivensecondset0fornointervalEditFieldLabel.Text = 'Interval (at every given second, set 0 for no interval)';

            % Create IntervalEditField
            app.IntervalEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.IntervalEditField.Limits = [0 Inf];
            app.IntervalEditField.ValueDisplayFormat = '%.0f';
            app.IntervalEditField.FontWeight = 'bold';
            app.IntervalEditField.Position = [374 10 68 22];

            % Create ReferenceAcquisitionPanel
            app.ReferenceAcquisitionPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.ReferenceAcquisitionPanel.Title = 'Reference Acquisition';
            app.ReferenceAcquisitionPanel.FontWeight = 'bold';
            app.ReferenceAcquisitionPanel.FontSize = 13;
            app.ReferenceAcquisitionPanel.Position = [16 492 467 95];

            % Create SubtractCheckBox
            app.SubtractCheckBox = uicheckbox(app.ReferenceAcquisitionPanel);
            app.SubtractCheckBox.Text = 'Subtract';
            app.SubtractCheckBox.FontWeight = 'bold';
            app.SubtractCheckBox.Position = [383 44 71 22];

            % Create BaselineLampLabel
            app.BaselineLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.BaselineLampLabel.HorizontalAlignment = 'right';
            app.BaselineLampLabel.Position = [10 44 51 22];
            app.BaselineLampLabel.Text = 'Baseline';

            % Create BaselineLamp
            app.BaselineLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.BaselineLamp.Position = [70 44 20 20];
            app.BaselineLamp.Color = [0.851 0.3294 0.102];

            % Create BaselineButton
            app.BaselineButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.BaselineButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineButtonPushed, true);
            app.BaselineButton.FontWeight = 'bold';
            app.BaselineButton.Position = [117 41 114 27];
            app.BaselineButton.Text = 'Baseline';

            % Create RemoveBaselineButton
            app.RemoveBaselineButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemoveBaselineButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveBaselineButtonPushed, true);
            app.RemoveBaselineButton.FontWeight = 'bold';
            app.RemoveBaselineButton.Position = [249 41 120 27];
            app.RemoveBaselineButton.Text = 'Remove Baseline';

            % Create ReferenceLampLabel
            app.ReferenceLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.ReferenceLampLabel.HorizontalAlignment = 'right';
            app.ReferenceLampLabel.Position = [7 10 60 22];
            app.ReferenceLampLabel.Text = 'Reference';

            % Create ReferenceLamp
            app.ReferenceLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.ReferenceLamp.Position = [70 10 20 20];
            app.ReferenceLamp.Color = [0.851 0.3255 0.098];

            % Create ReferenceButton
            app.ReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.ReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @ReferenceButtonPushed, true);
            app.ReferenceButton.FontWeight = 'bold';
            app.ReferenceButton.Position = [117 7 114 27];
            app.ReferenceButton.Text = 'Reference';

            % Create RemoveReferenceButton
            app.RemoveReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemoveReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveReferenceButtonPushed, true);
            app.RemoveReferenceButton.FontWeight = 'bold';
            app.RemoveReferenceButton.Position = [249 7 120 27];
            app.RemoveReferenceButton.Text = 'Remove Reference';

            % Create MeasurementDetailsPanel
            app.MeasurementDetailsPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.MeasurementDetailsPanel.Title = 'Measurement Details';
            app.MeasurementDetailsPanel.FontWeight = 'bold';
            app.MeasurementDetailsPanel.FontSize = 13;
            app.MeasurementDetailsPanel.Position = [16 44 466 440];

            % Create SampleEditFieldLabel
            app.SampleEditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.SampleEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleEditFieldLabel.FontWeight = 'bold';
            app.SampleEditFieldLabel.Position = [8 383 48 22];
            app.SampleEditFieldLabel.Text = 'Sample';

            % Create SampleEditField
            app.SampleEditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.SampleEditField.FontWeight = 'bold';
            app.SampleEditField.Position = [86 383 184 22];

            % Create ModeDropDownLabel
            app.ModeDropDownLabel = uilabel(app.MeasurementDetailsPanel);
            app.ModeDropDownLabel.HorizontalAlignment = 'right';
            app.ModeDropDownLabel.FontWeight = 'bold';
            app.ModeDropDownLabel.Position = [278 383 36 22];
            app.ModeDropDownLabel.Text = 'Mode';

            % Create ModeDropDown
            app.ModeDropDown = uidropdown(app.MeasurementDetailsPanel);
            app.ModeDropDown.Items = {'Transmission', 'Reflection'};
            app.ModeDropDown.FontWeight = 'bold';
            app.ModeDropDown.Position = [321 383 124 22];
            app.ModeDropDown.Value = 'Transmission';

            % Create DescriptionEditFieldLabel
            app.DescriptionEditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.DescriptionEditFieldLabel.HorizontalAlignment = 'right';
            app.DescriptionEditFieldLabel.FontWeight = 'bold';
            app.DescriptionEditFieldLabel.Position = [8 351 71 22];
            app.DescriptionEditFieldLabel.Text = 'Description';

            % Create DescriptionEditField
            app.DescriptionEditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.DescriptionEditField.FontWeight = 'bold';
            app.DescriptionEditField.Position = [86 351 359 22];

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [14 11 217 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [249 11 198 33];
            app.STOPButton.Text = 'STOP';

            % Create TemporalMeasurementFileLabel
            app.TemporalMeasurementFileLabel = uilabel(app.MeasurementDetailsPanel);
            app.TemporalMeasurementFileLabel.FontWeight = 'bold';
            app.TemporalMeasurementFileLabel.FontColor = [0.149 0.149 0.149];
            app.TemporalMeasurementFileLabel.Position = [20 52 277 22];
            app.TemporalMeasurementFileLabel.Text = 'Interim Measurement Data (measurements.csv)';

            % Create csvLOADButton
            app.csvLOADButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.csvLOADButton.ButtonPushedFcn = createCallbackFcn(app, @csvLOADButtonPushed, true);
            app.csvLOADButton.BackgroundColor = [1 1 1];
            app.csvLOADButton.FontWeight = 'bold';
            app.csvLOADButton.FontColor = [0 0.4471 0.7412];
            app.csvLOADButton.Position = [312 52 131 23];
            app.csvLOADButton.Text = 'LOAD';

            % Create ResetAverageNumberButton
            app.ResetAverageNumberButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.ResetAverageNumberButton.ButtonPushedFcn = createCallbackFcn(app, @ResetAverageNumberButtonPushed, true);
            app.ResetAverageNumberButton.BackgroundColor = [1 1 1];
            app.ResetAverageNumberButton.FontWeight = 'bold';
            app.ResetAverageNumberButton.FontColor = [0.851 0.3255 0.098];
            app.ResetAverageNumberButton.Position = [14 79 141 23];
            app.ResetAverageNumberButton.Text = 'Reset Average Number';

            % Create UITable
            app.UITable = uitable(app.MeasurementDetailsPanel);
            app.UITable.ColumnName = {'Metadata'; 'Sample/Reference'; 'Category'; 'Unit'; 'Value'};
            app.UITable.ColumnWidth = {65, 120, 110, 50, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnEditable = [false true true true true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Position = [14 141 437 170];

            % Create MetadataCountSpinnerLabel
            app.MetadataCountSpinnerLabel = uilabel(app.MeasurementDetailsPanel);
            app.MetadataCountSpinnerLabel.HorizontalAlignment = 'right';
            app.MetadataCountSpinnerLabel.FontWeight = 'bold';
            app.MetadataCountSpinnerLabel.Position = [8 320 98 22];
            app.MetadataCountSpinnerLabel.Text = 'Metadata Count ';

            % Create MetadataCountSpinner
            app.MetadataCountSpinner = uispinner(app.MeasurementDetailsPanel);
            app.MetadataCountSpinner.Limits = [0 6];
            app.MetadataCountSpinner.ValueChangedFcn = createCallbackFcn(app, @MetadataCountSpinnerValueChanged, true);
            app.MetadataCountSpinner.FontWeight = 'bold';
            app.MetadataCountSpinner.Position = [116 320 80 22];

            % Create ResetMetadataTableButton
            app.ResetMetadataTableButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.ResetMetadataTableButton.ButtonPushedFcn = createCallbackFcn(app, @ResetMetadataTableButtonPushed, true);
            app.ResetMetadataTableButton.BackgroundColor = [1 1 1];
            app.ResetMetadataTableButton.FontWeight = 'bold';
            app.ResetMetadataTableButton.Position = [269 320 172 23];
            app.ResetMetadataTableButton.Text = 'Reset Metadata Table';

            % Create MetaDescriptionEditFieldLabel
            app.MetaDescriptionEditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.MetaDescriptionEditFieldLabel.HorizontalAlignment = 'right';
            app.MetaDescriptionEditFieldLabel.FontWeight = 'bold';
            app.MetaDescriptionEditFieldLabel.Position = [13 112 102 22];
            app.MetaDescriptionEditFieldLabel.Text = 'Meta Description';

            % Create MetaDescriptionEditField
            app.MetaDescriptionEditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.MetaDescriptionEditField.FontWeight = 'bold';
            app.MetaDescriptionEditField.Position = [122 112 326 22];

            % Create ResetIntervalTimeButton
            app.ResetIntervalTimeButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.ResetIntervalTimeButton.ButtonPushedFcn = createCallbackFcn(app, @ResetIntervalTimeButtonPushed, true);
            app.ResetIntervalTimeButton.BackgroundColor = [1 1 1];
            app.ResetIntervalTimeButton.FontWeight = 'bold';
            app.ResetIntervalTimeButton.FontColor = [0.851 0.3255 0.098];
            app.ResetIntervalTimeButton.Position = [161 79 141 23];
            app.ResetIntervalTimeButton.Text = 'Reset Interval Time';

            % Create SystemReadyLamp
            app.SystemReadyLamp = uilamp(app.AcquisitionDialogUIFigure);
            app.SystemReadyLamp.Position = [29 13 20 20];

            % Create SystemReadyLampLabel
            app.SystemReadyLampLabel = uilabel(app.AcquisitionDialogUIFigure);
            app.SystemReadyLampLabel.Position = [58 11 83 22];
            app.SystemReadyLampLabel.Text = 'System Ready';

            % Create Image
            app.Image = uiimage(app.AcquisitionDialogUIFigure);
            app.Image.Position = [307 3 167 38];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'Images', 'MENLO-Logo.png');

            % Show the figure after all components are created
            app.AcquisitionDialogUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AcquisitionDialog_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.AcquisitionDialogUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.AcquisitionDialogUIFigure)
        end
    end
end