classdef AcquisitionDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AcquisitionDialogUIFigure      matlab.ui.Figure
        MeasurementSettingsPanel       matlab.ui.container.Panel
        ModeSwitch                     matlab.ui.control.Switch
        ModeSwitchLabel                matlab.ui.control.Label
        TimeLeftsecEditField           matlab.ui.control.NumericEditField
        TimeLeftsecEditFieldLabel      matlab.ui.control.Label
        CurrentCountEditField          matlab.ui.control.NumericEditField
        CurrentCountEditFieldLabel     matlab.ui.control.Label
        AcqusitionCountEditField       matlab.ui.control.NumericEditField
        AcqusitionCountEditFieldLabel  matlab.ui.control.Label
        TimesecEditField               matlab.ui.control.NumericEditField
        TimesecEditFieldLabel          matlab.ui.control.Label
        AverageNumberEditField         matlab.ui.control.NumericEditField
        IntervalsecLabel               matlab.ui.control.Label
        SystemReadyLamp                matlab.ui.control.Lamp
        SystemReadyLampLabel           matlab.ui.control.Label
        THzLamp                        matlab.ui.control.Lamp
        THzLampLabel                   matlab.ui.control.Label
        MeasurementDetailsPanel        matlab.ui.container.Panel
        NumericValueEditField_2        matlab.ui.control.NumericEditField
        NumericValueEditFieldLabel     matlab.ui.control.Label
        Metadata2EditField             matlab.ui.control.EditField
        Metadata2EditFieldLabel        matlab.ui.control.Label
        NumericValueEditField_1        matlab.ui.control.NumericEditField
        NumericValueEditField_2Label   matlab.ui.control.Label
        Metadata1EditField             matlab.ui.control.EditField
        Metadata1EditFieldLabel        matlab.ui.control.Label
        ModeDropDown                   matlab.ui.control.DropDown
        ModeDropDownLabel              matlab.ui.control.Label
        DescriptionEditField           matlab.ui.control.EditField
        DescriptionEditFieldLabel      matlab.ui.control.Label
        SampleEditField                matlab.ui.control.EditField
        SampleEditFieldLabel           matlab.ui.control.Label
        STOPButton                     matlab.ui.control.Button
        ACQUIREButton                  matlab.ui.control.Button
        ReferenceAcquisitionPanel      matlab.ui.container.Panel
        ReferenceLamp                  matlab.ui.control.Lamp
        ReferenceLampLabel             matlab.ui.control.Label
        BaselineLamp                   matlab.ui.control.Lamp
        BaselineLampLabel              matlab.ui.control.Label
        SubtractBaselineCheckBox       matlab.ui.control.CheckBox
        RemoveReferenceButton          matlab.ui.control.Button
        ReferenceButton                matlab.ui.control.Button
        RemoveBaselineButton           matlab.ui.control.Button
        BaselineButton                 matlab.ui.control.Button
        EditField                      matlab.ui.control.EditField
        Image                          matlab.ui.control.Image
        ReadStatusButton               matlab.ui.control.Button
    end

    
    properties (Access = private)
        MainApp % Main app
        numAcq % total number of acquisitions
        TcellAcq % Acquistion table cell
        matBaseline % Baseline matrix [time stamps; amplitudes]
        matReference % Reference matrix [time stamps; amplitudes]
        processStop % Is Stop-button pressed?
    end
    
    methods (Access = private)
        
        function updateMain(app)
            % Call main app's public function
            updateTableRemote(app.MainApp,app.TcellAcq);
        end
      
        function updateTcellAcq(app,TcellNew)
            TcellAcq = app.TcellAcq;
            TcellAcq = [TcellAcq, TcellNew];
            app.TcellAcq = TcellAcq;
        end

        function addMeasurement(app) % single scan#
                numAcq = app.numAcq;
                fig = app.AcquisitionDialogUIFigure;

                curCol = size(app.TcellAcq,2);
                measMat = readWaveform(app);
                measNum = size(measMat,1);
                TcellNew = cell(22,measNum);
                numAcq = numAcq + measNum;
                digitNum = ceil(log10(measNum+1));
                digitNumFormat = strcat('%0',num2str(digitNum),'d');

                for idx = 1:measNum
                    sampleName = app.SampleEditField.Value;
                    description = app.DescriptionEditField.Value;
                    description = strcat(sprintf(digitNumFormat,idx),'_',description);
                    mode = app.ModeDropDown.Value;

                    md1Des = app.Metadata1EditField.Value;
                    md2Des = app.Metadata2EditField.Value;
                    md1Val = app.NumericValueEditField_1.Value;
                    md2Val = app.NumericValueEditField_2.Value;
                    md3Val = [];
                    md4Val = [];
                    md5Val = [];


                    if ~isempty(md1Des)
                        mdDescription = md1Des;
                    else
                        mdDescription = [];
                    end

                    if ~isempty(md2Des)
                        mdDescription = strcat(mdDescription,',',md2Des);
                    end


                    if isempty(md1Val)
                        md1Val = [];
                    end

                    if isempty(md2Val)
                        md2Val = [];
                    end

                    matBaseline = app.matBaseline;
                    matRefernece = app.matReference;

                    % Baseline subtraction check
                    if app.SubtractBaselineCheckBox.Value

                        if isempty(matBaseline)
                            uialert(fig,'No valid baseline','Acquisition aborted');
                            return;
                        end

                        if ~isempty(matRefernece)
                            try
                                matRefernece(1,:,2) = matRefernece(1,:,2) - matBaseline(1,:,2);
                            catch
                                uialert(fig,'Inconsist Waveform length','Baseline subtraction aborted');
                                return;
                            end
                        end

                        if ~isempty(measMat)
                            try
                                measMat(idx,:,2) = measMat(idx,:,2) - matBaseline(1,:,2);
                            catch
                                uialert(fig,'Inconsist Waveform length','Baseline subtraction aborted');
                                return;
                            end
                        end                    
                    end

                    dsDescription = "Sample"; % dataset description
                    ds1 = [measMat(idx,:,1);measMat(idx,:,2)];

                    if ~isempty(matRefernece)
                        ds2 = [matRefernece(1,:,1);matRefernece(1,:,2)];
                        dsDescription = strcat(dsDescription,',',"Reference");
                    else
                        ds2 = [];
                    end

                    ds3 = [];
                    ds4 = [];

                    TcellNew{1,idx} = curCol+idx;
                    TcellNew{2,idx} = sampleName;
                    TcellNew{3,idx} = description;
                    TcellNew{4,idx} = 0; % Instrument profile
                    TcellNew{5,idx} = 0; % User profile
                    TcellNew{6,idx} = 0; %time; % measurement start time
                    TcellNew{7,idx} = mode; % THz-TDS/THz-Imaging/Transmission/Reflection
                    TcellNew{8,idx} = []; % coordinates

                    TcellNew{9,idx} = mdDescription; % metadata description
                    TcellNew{10,idx} = md1Val;
                    TcellNew{11,idx} = md2Val;
                    TcellNew{12,idx} = md3Val; 
                    TcellNew{13,idx} = md4Val; 
                    TcellNew{14,idx} = md5Val; 

                    TcellNew{15,idx} = []; % not used
                    TcellNew{16,idx} = []; % not used
                    TcellNew{17,idx} = []; % not used

                    TcellNew{18,idx} = dsDescription; % dataset description
                    TcellNew{19,idx} = ds1;
                    TcellNew{20,idx} = ds2;
                    TcellNew{21,idx} = ds3; 
                    TcellNew{22,idx} = ds4; 
                end

                updateTcellAcq(app,TcellNew);
                assignin("base","TcellNew",TcellNew);
                app.numAcq = numAcq;
        end
        
        function measMat = readWaveform(app)
            measAverage = app.AverageNumberEditField.Value;
            measTime = app.TimesecEditField.Value;
            measCount = app.AcqusitionCountEditField.Value;
            measMode = app.ModeSwitch.Value;

            if isequal(measMode,'Count')
                cMode = true;
            else
                cMode = false;
            end
            
            %status = pyrunfile("connectSC.py","status");
            output = pyrunfile("getPulse_ml02.py","output", ...
                measurement_average = measAverage, measurement_time = measTime, ...
                measurement_count = measCount, count_mode = cMode);
            % % assignin("base","output",output);
            % % output = cell(output);
            timeAxis = cell(output{1});
            eAmp = cell(output{2});

            measNum = size(timeAxis,2);
            timeMat = [];
            eAmpMat = [];

            for idx = 1:measNum
                timeMat = [timeMat;double(timeAxis{idx})];
                eAmpMat = [eAmpMat;double(eAmp{idx})];
            end

            measMat = cat(3, timeMat, eAmpMat);
            % % assignin("base","measMat",measMat);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, Tcell)
            % Store main app object
            app.MainApp = mainapp;
            app.TcellAcq = Tcell;
            app.numAcq = 0;
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
            fig = app.AcquisitionDialogUIFigure;
            drawnow

            addMeasurement(app);
            app.SystemReadyLamp.Color = "Green";
            app.SystemReadyLampLabel.Text = "Ready";
            drawnow

            % if app.MultipleAcquisitionCheckBox.Value
            %     timeInput = app.TimesecEditField.Value;
            %     numAcqInput = app.AcqusitionCountEditField.Value;
            % 
            %     if timeInput == 0 && numAcqInput == 0
            %         uialert(fig,'Invalid Multiple Acquisition Settings','Aborted');
            %         app.SystemReadyLamp.Color = "Green";
            %         app.SystemReadyLampLabel.Text = "Ready";
            %         return;
            %     end
            % 
            %     if timeInput ~= 0
            %         initTime = datetime;
            %         while ~app.processStop
            %             addMeasurement(app);
            %             timeLeft = timeInput - seconds(datetime - initTime);
            %             if timeLeft <= 0
            %                 app.processStop = true;
            %                 timeLeft = 0;
            %             end
            %             app.TimeLeftsecEditField.Value = timeLeft;
            %         end
            % 
            %     else % numAcqInput ~= 0
            %         while ~app.processStop
            %             addMeasurement(app);
            %             if numAcqInput < scanCnt
            %                 app.processStop = true;
            %             end
            %         end
            % 
            %     end
            % 
            % else
            %     addMeasurement(app);
            %     app.CurrentCountEditField.Value = scanCnt;
            % end



            % Update Main App table
            updateTableRemote(app.MainApp,app.TcellAcq);            
        end

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            app.CurrentCountEditField.Value = 0;
            app.AcqusitionCountEditField.Value = 1;
            app.TimesecEditField.Value = 0;
            app.TimeLeftsecEditField.Value = 0;
            app.processStop = true;
        end

        % Button pushed function: BaselineButton
        function BaselineButtonPushed(app, event)
            
            try
                app.matBaseline = readWaveform(app);
            catch
                app.BaselineLamp.Color = [0.85,0.33,0.10];
                return
            end

            app.BaselineLamp.Color = "Green";

        end

        % Button pushed function: ReferenceButton
        function ReferenceButtonPushed(app, event)
            
            try
                app.matReference = readWaveform(app);
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

        % Value changed function: ModeSwitch
        function ModeSwitchValueChanged(app, event)
            value = app.ModeSwitch.Value;

            if isequal(value,'Count')
                app.TimesecEditField.Editable = "off";
                app.AcqusitionCountEditField.Editable = "on";
                app.AcqusitionCountEditField.BackgroundColor = [0.302 0.7451 0.9333];
                app.TimesecEditField.BackgroundColor = [1,1,1];
            else % time mode
                app.TimesecEditField.Editable = "on";
                app.TimesecEditField.BackgroundColor = [0.302 0.7451 0.9333];
                app.AcqusitionCountEditField.BackgroundColor = [1,1,1];
                app.AcqusitionCountEditField.Editable = "off";

            end

            app.TimesecEditField.Value = 0;
            app.AcqusitionCountEditField.Value = 1;
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
            app.AcquisitionDialogUIFigure.Position = [100 100 435 565];
            app.AcquisitionDialogUIFigure.Name = 'TeraSmart Control';
            app.AcquisitionDialogUIFigure.Icon = fullfile(pathToMLAPP, 'CaT_logo.png');
            app.AcquisitionDialogUIFigure.CloseRequestFcn = createCallbackFcn(app, @AcquisitionDialogUIFigureCloseRequest, true);

            % Create ReadStatusButton
            app.ReadStatusButton = uibutton(app.AcquisitionDialogUIFigure, 'push');
            app.ReadStatusButton.FontWeight = 'bold';
            app.ReadStatusButton.Position = [17 528 109 27];
            app.ReadStatusButton.Text = 'Read Status';

            % Create Image
            app.Image = uiimage(app.AcquisitionDialogUIFigure);
            app.Image.Position = [252 6 167 38];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'MENLO-Logo.png');

            % Create EditField
            app.EditField = uieditfield(app.AcquisitionDialogUIFigure, 'text');
            app.EditField.Editable = 'off';
            app.EditField.Position = [138 529 198 26];

            % Create ReferenceAcquisitionPanel
            app.ReferenceAcquisitionPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.ReferenceAcquisitionPanel.Title = 'Reference Acquisition';
            app.ReferenceAcquisitionPanel.FontWeight = 'bold';
            app.ReferenceAcquisitionPanel.FontSize = 13;
            app.ReferenceAcquisitionPanel.Position = [15 271 409 126];

            % Create BaselineButton
            app.BaselineButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.BaselineButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineButtonPushed, true);
            app.BaselineButton.FontWeight = 'bold';
            app.BaselineButton.Position = [101 43 135 27];
            app.BaselineButton.Text = 'Baseline';

            % Create RemoveBaselineButton
            app.RemoveBaselineButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemoveBaselineButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveBaselineButtonPushed, true);
            app.RemoveBaselineButton.FontWeight = 'bold';
            app.RemoveBaselineButton.Position = [245 43 156 27];
            app.RemoveBaselineButton.Text = 'Remove Baseline';

            % Create ReferenceButton
            app.ReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.ReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @ReferenceButtonPushed, true);
            app.ReferenceButton.FontWeight = 'bold';
            app.ReferenceButton.Position = [101 9 135 27];
            app.ReferenceButton.Text = 'Reference';

            % Create RemoveReferenceButton
            app.RemoveReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemoveReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveReferenceButtonPushed, true);
            app.RemoveReferenceButton.FontWeight = 'bold';
            app.RemoveReferenceButton.Position = [245 9 155 27];
            app.RemoveReferenceButton.Text = 'Remove Reference';

            % Create SubtractBaselineCheckBox
            app.SubtractBaselineCheckBox = uicheckbox(app.ReferenceAcquisitionPanel);
            app.SubtractBaselineCheckBox.Text = 'Subtract Baseline';
            app.SubtractBaselineCheckBox.FontWeight = 'bold';
            app.SubtractBaselineCheckBox.Position = [15 76 123 22];

            % Create BaselineLampLabel
            app.BaselineLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.BaselineLampLabel.HorizontalAlignment = 'right';
            app.BaselineLampLabel.Position = [10 46 51 22];
            app.BaselineLampLabel.Text = 'Baseline';

            % Create BaselineLamp
            app.BaselineLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.BaselineLamp.Position = [70 46 20 20];
            app.BaselineLamp.Color = [0.851 0.3294 0.102];

            % Create ReferenceLampLabel
            app.ReferenceLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.ReferenceLampLabel.HorizontalAlignment = 'right';
            app.ReferenceLampLabel.Position = [7 12 60 22];
            app.ReferenceLampLabel.Text = 'Reference';

            % Create ReferenceLamp
            app.ReferenceLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.ReferenceLamp.Position = [70 12 20 20];
            app.ReferenceLamp.Color = [0.851 0.3255 0.098];

            % Create MeasurementDetailsPanel
            app.MeasurementDetailsPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.MeasurementDetailsPanel.Title = 'Measurement Details';
            app.MeasurementDetailsPanel.FontWeight = 'bold';
            app.MeasurementDetailsPanel.FontSize = 13;
            app.MeasurementDetailsPanel.Position = [16 49 409 212];

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [17 12 185 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.MeasurementDetailsPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [213 12 185 33];
            app.STOPButton.Text = 'STOP';

            % Create SampleEditFieldLabel
            app.SampleEditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.SampleEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleEditFieldLabel.Position = [9 155 46 22];
            app.SampleEditFieldLabel.Text = 'Sample';

            % Create SampleEditField
            app.SampleEditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.SampleEditField.Position = [82 155 163 22];

            % Create DescriptionEditFieldLabel
            app.DescriptionEditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.DescriptionEditFieldLabel.HorizontalAlignment = 'right';
            app.DescriptionEditFieldLabel.Position = [9 123 65 22];
            app.DescriptionEditFieldLabel.Text = 'Description';

            % Create DescriptionEditField
            app.DescriptionEditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.DescriptionEditField.Position = [81 123 310 22];

            % Create ModeDropDownLabel
            app.ModeDropDownLabel = uilabel(app.MeasurementDetailsPanel);
            app.ModeDropDownLabel.HorizontalAlignment = 'right';
            app.ModeDropDownLabel.Position = [259 155 35 22];
            app.ModeDropDownLabel.Text = 'Mode';

            % Create ModeDropDown
            app.ModeDropDown = uidropdown(app.MeasurementDetailsPanel);
            app.ModeDropDown.Items = {'TX', 'RX'};
            app.ModeDropDown.Position = [306 155 83 22];
            app.ModeDropDown.Value = 'TX';

            % Create Metadata1EditFieldLabel
            app.Metadata1EditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.Metadata1EditFieldLabel.HorizontalAlignment = 'right';
            app.Metadata1EditFieldLabel.Position = [9 91 65 22];
            app.Metadata1EditFieldLabel.Text = 'Metadata 1';

            % Create Metadata1EditField
            app.Metadata1EditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.Metadata1EditField.Position = [82 91 142 22];

            % Create NumericValueEditField_2Label
            app.NumericValueEditField_2Label = uilabel(app.MeasurementDetailsPanel);
            app.NumericValueEditField_2Label.HorizontalAlignment = 'right';
            app.NumericValueEditField_2Label.Position = [227 91 83 22];
            app.NumericValueEditField_2Label.Text = 'Numeric Value';

            % Create NumericValueEditField_1
            app.NumericValueEditField_1 = uieditfield(app.MeasurementDetailsPanel, 'numeric');
            app.NumericValueEditField_1.Position = [318 91 70 22];

            % Create Metadata2EditFieldLabel
            app.Metadata2EditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.Metadata2EditFieldLabel.HorizontalAlignment = 'right';
            app.Metadata2EditFieldLabel.Position = [9 60 65 22];
            app.Metadata2EditFieldLabel.Text = 'Metadata 2';

            % Create Metadata2EditField
            app.Metadata2EditField = uieditfield(app.MeasurementDetailsPanel, 'text');
            app.Metadata2EditField.Position = [82 60 142 22];

            % Create NumericValueEditFieldLabel
            app.NumericValueEditFieldLabel = uilabel(app.MeasurementDetailsPanel);
            app.NumericValueEditFieldLabel.HorizontalAlignment = 'right';
            app.NumericValueEditFieldLabel.Position = [228 60 83 22];
            app.NumericValueEditFieldLabel.Text = 'Numeric Value';

            % Create NumericValueEditField_2
            app.NumericValueEditField_2 = uieditfield(app.MeasurementDetailsPanel, 'numeric');
            app.NumericValueEditField_2.Position = [318 60 70 22];

            % Create THzLampLabel
            app.THzLampLabel = uilabel(app.AcquisitionDialogUIFigure);
            app.THzLampLabel.HorizontalAlignment = 'right';
            app.THzLampLabel.Position = [351 531 27 22];
            app.THzLampLabel.Text = 'THz';

            % Create THzLamp
            app.THzLamp = uilamp(app.AcquisitionDialogUIFigure);
            app.THzLamp.Position = [385 531 20 20];

            % Create SystemReadyLampLabel
            app.SystemReadyLampLabel = uilabel(app.AcquisitionDialogUIFigure);
            app.SystemReadyLampLabel.Position = [60 14 83 22];
            app.SystemReadyLampLabel.Text = 'System Ready';

            % Create SystemReadyLamp
            app.SystemReadyLamp = uilamp(app.AcquisitionDialogUIFigure);
            app.SystemReadyLamp.Position = [31 16 20 20];

            % Create MeasurementSettingsPanel
            app.MeasurementSettingsPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.MeasurementSettingsPanel.Title = 'Measurement Settings';
            app.MeasurementSettingsPanel.FontWeight = 'bold';
            app.MeasurementSettingsPanel.Position = [15 406 409 113];

            % Create IntervalsecLabel
            app.IntervalsecLabel = uilabel(app.MeasurementSettingsPanel);
            app.IntervalsecLabel.HorizontalAlignment = 'right';
            app.IntervalsecLabel.FontWeight = 'bold';
            app.IntervalsecLabel.Position = [7 63 101 22];
            app.IntervalsecLabel.Text = 'Average Number';

            % Create AverageNumberEditField
            app.AverageNumberEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.AverageNumberEditField.Limits = [0 10000];
            app.AverageNumberEditField.ValueDisplayFormat = '%.0f';
            app.AverageNumberEditField.FontWeight = 'bold';
            app.AverageNumberEditField.BackgroundColor = [0.9294 0.6941 0.1255];
            app.AverageNumberEditField.Position = [124 63 66 22];
            app.AverageNumberEditField.Value = 1;

            % Create TimesecEditFieldLabel
            app.TimesecEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.TimesecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimesecEditFieldLabel.Position = [11 35 61 22];
            app.TimesecEditFieldLabel.Text = 'Time (sec)';

            % Create TimesecEditField
            app.TimesecEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.TimesecEditField.Limits = [0 100000];
            app.TimesecEditField.ValueDisplayFormat = '%.0f';
            app.TimesecEditField.Editable = 'off';
            app.TimesecEditField.Position = [124 35 66 22];

            % Create AcqusitionCountEditFieldLabel
            app.AcqusitionCountEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.AcqusitionCountEditFieldLabel.HorizontalAlignment = 'right';
            app.AcqusitionCountEditFieldLabel.Position = [10 6 96 22];
            app.AcqusitionCountEditFieldLabel.Text = 'Acqusition Count';

            % Create AcqusitionCountEditField
            app.AcqusitionCountEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.AcqusitionCountEditField.Limits = [0 100000];
            app.AcqusitionCountEditField.ValueDisplayFormat = '%.0f';
            app.AcqusitionCountEditField.BackgroundColor = [0.302 0.7451 0.9333];
            app.AcqusitionCountEditField.Position = [124 6 67 22];
            app.AcqusitionCountEditField.Value = 1;

            % Create CurrentCountEditFieldLabel
            app.CurrentCountEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.CurrentCountEditFieldLabel.HorizontalAlignment = 'right';
            app.CurrentCountEditFieldLabel.Position = [221 6 87 22];
            app.CurrentCountEditFieldLabel.Text = 'Current Count  ';

            % Create CurrentCountEditField
            app.CurrentCountEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.CurrentCountEditField.Limits = [0 Inf];
            app.CurrentCountEditField.ValueDisplayFormat = '%.0f';
            app.CurrentCountEditField.Editable = 'off';
            app.CurrentCountEditField.Position = [316 6 80 22];

            % Create TimeLeftsecEditFieldLabel
            app.TimeLeftsecEditFieldLabel = uilabel(app.MeasurementSettingsPanel);
            app.TimeLeftsecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimeLeftsecEditFieldLabel.Position = [221 35 85 22];
            app.TimeLeftsecEditFieldLabel.Text = 'Time Left (sec)';

            % Create TimeLeftsecEditField
            app.TimeLeftsecEditField = uieditfield(app.MeasurementSettingsPanel, 'numeric');
            app.TimeLeftsecEditField.Limits = [0 Inf];
            app.TimeLeftsecEditField.ValueDisplayFormat = '%5.2f';
            app.TimeLeftsecEditField.Editable = 'off';
            app.TimeLeftsecEditField.Position = [316 35 80 22];

            % Create ModeSwitchLabel
            app.ModeSwitchLabel = uilabel(app.MeasurementSettingsPanel);
            app.ModeSwitchLabel.HorizontalAlignment = 'center';
            app.ModeSwitchLabel.FontWeight = 'bold';
            app.ModeSwitchLabel.Position = [229 63 36 22];
            app.ModeSwitchLabel.Text = 'Mode';

            % Create ModeSwitch
            app.ModeSwitch = uiswitch(app.MeasurementSettingsPanel, 'slider');
            app.ModeSwitch.Items = {'Count', 'Time'};
            app.ModeSwitch.ValueChangedFcn = createCallbackFcn(app, @ModeSwitchValueChanged, true);
            app.ModeSwitch.Position = [319 65 43 19];
            app.ModeSwitch.Value = 'Count';

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