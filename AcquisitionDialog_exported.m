classdef AcquisitionDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AcquisitionDialogUIFigure       matlab.ui.Figure
        THzLamp                         matlab.ui.control.Lamp
        THzLampLabel                    matlab.ui.control.Label
        SampleAcquisitionPanel          matlab.ui.container.Panel
        TimeLeftsecEditField            matlab.ui.control.NumericEditField
        TimeLeftsecEditFieldLabel       matlab.ui.control.Label
        IntervalsecEditField            matlab.ui.control.NumericEditField
        IntervalsecLabel                matlab.ui.control.Label
        AcquisitionTimeEditField        matlab.ui.control.EditField
        NumericValueEditField_2         matlab.ui.control.NumericEditField
        NumericValueEditFieldLabel      matlab.ui.control.Label
        Metadata2EditField              matlab.ui.control.EditField
        Metadata2EditFieldLabel         matlab.ui.control.Label
        NumericValueEditField_1         matlab.ui.control.NumericEditField
        NumericValueEditField_2Label    matlab.ui.control.Label
        Metadata1EditField              matlab.ui.control.EditField
        Metadata1EditFieldLabel         matlab.ui.control.Label
        ModeDropDown                    matlab.ui.control.DropDown
        ModeDropDownLabel               matlab.ui.control.Label
        DescriptionEditField            matlab.ui.control.EditField
        DescriptionEditFieldLabel       matlab.ui.control.Label
        SampleEditField                 matlab.ui.control.EditField
        SampleEditFieldLabel            matlab.ui.control.Label
        ReadyLamp                       matlab.ui.control.Lamp
        ReadyLampLabel                  matlab.ui.control.Label
        CurrentMeasurementCountEditField  matlab.ui.control.NumericEditField
        CurrentMeasurementCountEditFieldLabel  matlab.ui.control.Label
        STOPButton                      matlab.ui.control.Button
        ACQUIREButton                   matlab.ui.control.Button
        AcqusitionNumberEditField       matlab.ui.control.NumericEditField
        AcqusitionNumberEditFieldLabel  matlab.ui.control.Label
        TimesecEditField                matlab.ui.control.NumericEditField
        TimesecEditFieldLabel           matlab.ui.control.Label
        MultipleAcquisitionCheckBox     matlab.ui.control.CheckBox
        ReferenceAcquisitionPanel       matlab.ui.container.Panel
        PumpLamp                        matlab.ui.control.Lamp
        PumpLampLabel                   matlab.ui.control.Label
        ReferenceLamp                   matlab.ui.control.Lamp
        ReferenceLampLabel              matlab.ui.control.Label
        BaselineLamp                    matlab.ui.control.Lamp
        BaselineLampLabel               matlab.ui.control.Label
        SubtractBaselineCheckBox        matlab.ui.control.CheckBox
        PumpCheckBox                    matlab.ui.control.CheckBox
        RemovePumpReferenceButton       matlab.ui.control.Button
        PumpReferenceButton             matlab.ui.control.Button
        RemoveReferenceButton           matlab.ui.control.Button
        ReferenceButton                 matlab.ui.control.Button
        RemoveBaselineButton            matlab.ui.control.Button
        BaselineButton                  matlab.ui.control.Button
        EditField                       matlab.ui.control.EditField
        Image                           matlab.ui.control.Image
        ReadStatusButton                matlab.ui.control.Button
    end

    
    properties (Access = private)
        MainApp % Main app
        numAcq % total number of acquisitions
        TcellAcq % Acquistion table cell
        matBaseline % Baseline matrix [time stamps; amplitudes]
        matReference % Reference matrix [time stamps; amplitudes]
        matPumpRef % Pump reference matrix [time stamps; amplitudes]
        processStop % Is Stop-button pressed?
    end
    
    methods (Access = private)
        
        function updateMain(app)
            % Call main app's public function
            %TcellAcq = app.TcellAcq;
            %updateTableRemote(app.MainApp,TcellAcq);
        end
      
        function updateTcellAcq(app,TcellCol)
            TcellAcq = app.TcellAcq;
            TcellAcq = [TcellAcq, TcellCol];
            app.TcellAcq = TcellAcq;
        end

        function matCurrent = addMeasurement(app) % single scan#
                numAcq = app.numAcq;
                numAcq = numAcq + 1;
                fig = app.AcquisitionDialogUIFigure;

                curCol = size(app.TcellAcq,2) + 1;
                TcellCol = cell(22,1);
                matMeas = readWaveform(app); % get the current waveform from TeraSmart

                time = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF');
                app.AcquisitionTimeEditField.Value = time;
                sampleName = app.SampleEditField.Value;
                description = app.DescriptionEditField.Value;
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
                matPumpRef = app.matPumpRef;

                % Baseline subtraction check
                if app.SubtractBaselineCheckBox.Value
                    
                    if isempty(matBaseline)
                        uialert(fig,'No valid baseline','Acquisition aborted');
                        return;
                    end

                    if ~isempty(matRefernece)
                        try
                            matRefernece(2,:) = matRefernece(2,:) - matBaseline(2,:);
                        catch
                            uialert(fig,'Inconsist Waveform length','Baseline subtraction aborted');
                            return;
                        end
                    end

                    if ~isempty(matMeas)
                        try
                            matMeas(2,:) = matMeas(2,:) - matBaseline(2,:);
                        catch
                            uialert(fig,'Inconsist Waveform length','Baseline subtraction aborted');
                            return;
                        end
                    end                    

                    if app.PumpCheckBox.Value && ~isempty(matPumpRef)
                        try
                            matPumpRef(2,:) = matPumpRef(2,:) - matBaseline(2,:);
                        catch
                            uialert(fig,'Inconsist Waveform length','Baseline subtraction aborted');
                            return;
                        end
                    end
                end


                dsDescription = "Sample"; % dataset description
                ds1 = matMeas;

                if ~isempty(matRefernece)
                    ds2 = matRefernece;
                    dsDescription = strcat(dsDescription,',',"Reference");
                else
                    ds2 = [];
                end

                if app.PumpCheckBox.Value && ~isempty(matPumpRef)
                    ds3 = matRefernece;
                    dsDescription = strcat(dsDescription,',',"PumpRef");
                else
                    ds3 = [];
                end

                ds4 = [];

                TcellCol{1} = curCol;
                TcellCol{2} = sampleName;
                TcellCol{3} = description;
                TcellCol{4} = 0; % Instrument profile
                TcellCol{5} = 0; % User profile
                TcellCol{6} = time; % measurement start time
                TcellCol{7} = mode; % THz-TDS/THz-Imaging/Transmission/Reflection
                TcellCol{8} = []; % coordinates
                
                TcellCol{9} = mdDescription; % metadata description
                TcellCol{10} = md1Val;
                TcellCol{11} = md2Val;
                TcellCol{12} = md3Val; 
                TcellCol{13} = md4Val; 
                TcellCol{14} = md5Val; 

                TcellCol{15} = []; % not used
                TcellCol{16} = []; % not used
                TcellCol{17} = []; % not used

                TcellCol{18} = dsDescription; % dataset description
                TcellCol{19} = ds1;
                TcellCol{20} = ds2;
                TcellCol{21} = ds3; 
                TcellCol{22} = ds4; 

                matCurrent = ds1;
                updateTcellAcq(app,TcellCol);
                app.numAcq = numAcq;
        end
        
        function matMeas = readWaveform(app)
            % Following part will be replaced with Python call function
            vecTime = linspace(0,100);
            vecAmp = linspace(0,100);

            matMeas = [vecTime; vecAmp];
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

        % Value changed function: MultipleAcquisitionCheckBox
        function MultipleAcquisitionCheckBoxValueChanged(app, event)
            value = app.MultipleAcquisitionCheckBox.Value;
            if value
                app.TimesecEditField.Editable = "on";
                app.AcqusitionNumberEditField.Editable = "on";
                app.IntervalsecEditField.Editable = "on";
            else
                app.TimesecEditField.Editable = "off";
                app.AcqusitionNumberEditField.Editable = "off";
                app.IntervalsecEditField.Editable = "off";
                app.TimesecEditField.Value = 0;
                app.AcqusitionNumberEditField.Value = 0;
            end
        end

        % Value changed function: PumpCheckBox
        function PumpCheckBoxValueChanged(app, event)
            value = app.PumpCheckBox.Value;
            if value
                app.PumpReferenceButton.Visible = "on";
                app.RemovePumpReferenceButton.Visible = "on";
                app.PumpLampLabel.Visible = "on";
                app.PumpLamp.Visible = "on";
            else
                app.PumpReferenceButton.Visible = "off";
                app.RemovePumpReferenceButton.Visible = "off";
                app.PumpLampLabel.Visible = "off";
                app.PumpLamp.Visible = "off";
            end
        end

        % Value changed function: TimesecEditField
        function TimesecEditFieldValueChanged(app, event)
            value = app.TimesecEditField.Value;
            app.AcqusitionNumberEditField.Value = 0;
        end

        % Value changed function: AcqusitionNumberEditField
        function AcqusitionNumberEditFieldValueChanged(app, event)
            value = app.AcqusitionNumberEditField.Value;
            app.TimesecEditField.Value = 0;
            app.TimeLeftsecEditField.Value = 0;
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
            app.ReadyLamp.Color = [0.85,0.33,0.10];
            app.ReadyLampLabel.Text = "Scaning...";
            app.processStop = false;
            intervalTime = app.IntervalsecEditField.Value;
            fig = app.AcquisitionDialogUIFigure;
            scanCnt = 1;

            if app.MultipleAcquisitionCheckBox.Value
                timeInput = app.TimesecEditField.Value;
                numAcqInput = app.AcqusitionNumberEditField.Value;

                if timeInput == 0 && numAcqInput == 0
                    uialert(fig,'Invalid Multiple Acquisition Settings','Aborted');
                    app.ReadyLamp.Color = "Green";
                    app.ReadyLampLabel.Text = "Ready";
                    return;
                end

                if timeInput ~= 0
                    initTime = datetime;
                    while ~app.processStop
                        addMeasurement(app);
                        pause(intervalTime); % Delete this line for actual usage
                        app.CurrentMeasurementCountEditField.Value = scanCnt;
                        scanCnt = scanCnt + 1;
                        timeLeft = timeInput - seconds(datetime - initTime);
                        if timeLeft <= 0
                            app.processStop = true;
                            timeLeft = 0;
                        end
                        app.TimeLeftsecEditField.Value = timeLeft;
                    end

                else % numAcqInput ~= 0
                    while ~app.processStop
                        addMeasurement(app);
                        pause(intervalTime);
                        app.CurrentMeasurementCountEditField.Value = scanCnt;
                        scanCnt = scanCnt + 1;
                        if numAcqInput < scanCnt
                            app.processStop = true;
                        end
                    end

                end

            else
                addMeasurement(app);
                app.CurrentMeasurementCountEditField.Value = scanCnt;
            end

            app.ReadyLamp.Color = "Green";
            app.ReadyLampLabel.Text = "Ready";

            % Update Main App table
            updateTableRemote(app.MainApp,app.TcellAcq);
            
        end

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            app.CurrentMeasurementCountEditField.Value = 0;
            app.AcqusitionNumberEditField.Value = 0;
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

        % Button pushed function: PumpReferenceButton
        function PumpReferenceButtonPushed(app, event)
            
            try
                app.matPumpRef = readWaveform(app);
            catch
                app.PumpLamp.Color = [0.85,0.33,0.10];
                return
            end

            app.PumpLamp.Color = "Green";
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

        % Button pushed function: RemovePumpReferenceButton
        function RemovePumpReferenceButtonPushed(app, event)
            app.matPumpRef = [];
            app.PumpLamp.Color = [0.85,0.33,0.10];
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
            app.AcquisitionDialogUIFigure.Position = [100 100 435 608];
            app.AcquisitionDialogUIFigure.Name = 'TeraSmart Control';
            app.AcquisitionDialogUIFigure.Icon = fullfile(pathToMLAPP, 'CaT_logo.png');
            app.AcquisitionDialogUIFigure.CloseRequestFcn = createCallbackFcn(app, @AcquisitionDialogUIFigureCloseRequest, true);

            % Create ReadStatusButton
            app.ReadStatusButton = uibutton(app.AcquisitionDialogUIFigure, 'push');
            app.ReadStatusButton.FontWeight = 'bold';
            app.ReadStatusButton.Position = [17 571 109 27];
            app.ReadStatusButton.Text = 'Read Status';

            % Create Image
            app.Image = uiimage(app.AcquisitionDialogUIFigure);
            app.Image.Position = [258 9 167 38];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'MENLO-Logo.png');

            % Create EditField
            app.EditField = uieditfield(app.AcquisitionDialogUIFigure, 'text');
            app.EditField.Editable = 'off';
            app.EditField.Position = [138 572 198 26];

            % Create ReferenceAcquisitionPanel
            app.ReferenceAcquisitionPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.ReferenceAcquisitionPanel.Title = 'Reference Acquisition';
            app.ReferenceAcquisitionPanel.FontWeight = 'bold';
            app.ReferenceAcquisitionPanel.FontSize = 13;
            app.ReferenceAcquisitionPanel.Position = [16 395 409 164];

            % Create BaselineButton
            app.BaselineButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.BaselineButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineButtonPushed, true);
            app.BaselineButton.FontWeight = 'bold';
            app.BaselineButton.Position = [101 81 135 27];
            app.BaselineButton.Text = 'Baseline';

            % Create RemoveBaselineButton
            app.RemoveBaselineButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemoveBaselineButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveBaselineButtonPushed, true);
            app.RemoveBaselineButton.FontWeight = 'bold';
            app.RemoveBaselineButton.Position = [245 81 156 27];
            app.RemoveBaselineButton.Text = 'Remove Baseline';

            % Create ReferenceButton
            app.ReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.ReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @ReferenceButtonPushed, true);
            app.ReferenceButton.FontWeight = 'bold';
            app.ReferenceButton.Position = [101 44 135 27];
            app.ReferenceButton.Text = 'Reference';

            % Create RemoveReferenceButton
            app.RemoveReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemoveReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveReferenceButtonPushed, true);
            app.RemoveReferenceButton.FontWeight = 'bold';
            app.RemoveReferenceButton.Position = [245 44 155 27];
            app.RemoveReferenceButton.Text = 'Remove Reference';

            % Create PumpReferenceButton
            app.PumpReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.PumpReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @PumpReferenceButtonPushed, true);
            app.PumpReferenceButton.FontWeight = 'bold';
            app.PumpReferenceButton.Visible = 'off';
            app.PumpReferenceButton.Position = [101 8 135 27];
            app.PumpReferenceButton.Text = 'Pump Reference';

            % Create RemovePumpReferenceButton
            app.RemovePumpReferenceButton = uibutton(app.ReferenceAcquisitionPanel, 'push');
            app.RemovePumpReferenceButton.ButtonPushedFcn = createCallbackFcn(app, @RemovePumpReferenceButtonPushed, true);
            app.RemovePumpReferenceButton.FontWeight = 'bold';
            app.RemovePumpReferenceButton.Visible = 'off';
            app.RemovePumpReferenceButton.Position = [245 8 155 27];
            app.RemovePumpReferenceButton.Text = 'Remove Pump Reference';

            % Create PumpCheckBox
            app.PumpCheckBox = uicheckbox(app.ReferenceAcquisitionPanel);
            app.PumpCheckBox.ValueChangedFcn = createCallbackFcn(app, @PumpCheckBoxValueChanged, true);
            app.PumpCheckBox.Text = 'Pump';
            app.PumpCheckBox.FontWeight = 'bold';
            app.PumpCheckBox.Position = [139 115 55 22];

            % Create SubtractBaselineCheckBox
            app.SubtractBaselineCheckBox = uicheckbox(app.ReferenceAcquisitionPanel);
            app.SubtractBaselineCheckBox.Text = 'Subtract Baseline';
            app.SubtractBaselineCheckBox.FontWeight = 'bold';
            app.SubtractBaselineCheckBox.Position = [15 115 123 22];

            % Create BaselineLampLabel
            app.BaselineLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.BaselineLampLabel.HorizontalAlignment = 'right';
            app.BaselineLampLabel.Position = [10 84 51 22];
            app.BaselineLampLabel.Text = 'Baseline';

            % Create BaselineLamp
            app.BaselineLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.BaselineLamp.Position = [70 84 20 20];
            app.BaselineLamp.Color = [0.851 0.3294 0.102];

            % Create ReferenceLampLabel
            app.ReferenceLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.ReferenceLampLabel.HorizontalAlignment = 'right';
            app.ReferenceLampLabel.Position = [7 47 60 22];
            app.ReferenceLampLabel.Text = 'Reference';

            % Create ReferenceLamp
            app.ReferenceLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.ReferenceLamp.Position = [70 47 20 20];
            app.ReferenceLamp.Color = [0.851 0.3255 0.098];

            % Create PumpLampLabel
            app.PumpLampLabel = uilabel(app.ReferenceAcquisitionPanel);
            app.PumpLampLabel.HorizontalAlignment = 'right';
            app.PumpLampLabel.Visible = 'off';
            app.PumpLampLabel.Position = [15 12 36 22];
            app.PumpLampLabel.Text = 'Pump';

            % Create PumpLamp
            app.PumpLamp = uilamp(app.ReferenceAcquisitionPanel);
            app.PumpLamp.Visible = 'off';
            app.PumpLamp.Position = [70 12 20 20];
            app.PumpLamp.Color = [0.851 0.3255 0.098];

            % Create SampleAcquisitionPanel
            app.SampleAcquisitionPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.SampleAcquisitionPanel.Title = 'Sample Acquisition';
            app.SampleAcquisitionPanel.FontWeight = 'bold';
            app.SampleAcquisitionPanel.FontSize = 13;
            app.SampleAcquisitionPanel.Position = [17 55 409 329];

            % Create MultipleAcquisitionCheckBox
            app.MultipleAcquisitionCheckBox = uicheckbox(app.SampleAcquisitionPanel);
            app.MultipleAcquisitionCheckBox.ValueChangedFcn = createCallbackFcn(app, @MultipleAcquisitionCheckBoxValueChanged, true);
            app.MultipleAcquisitionCheckBox.Text = 'Multiple Acquisition';
            app.MultipleAcquisitionCheckBox.FontWeight = 'bold';
            app.MultipleAcquisitionCheckBox.Position = [22 144 136 22];

            % Create TimesecEditFieldLabel
            app.TimesecEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.TimesecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimesecEditFieldLabel.Position = [18 112 61 22];
            app.TimesecEditFieldLabel.Text = 'Time (sec)';

            % Create TimesecEditField
            app.TimesecEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.TimesecEditField.Limits = [0 100000];
            app.TimesecEditField.ValueDisplayFormat = '%.0f';
            app.TimesecEditField.ValueChangedFcn = createCallbackFcn(app, @TimesecEditFieldValueChanged, true);
            app.TimesecEditField.Editable = 'off';
            app.TimesecEditField.Position = [131 112 66 22];

            % Create AcqusitionNumberEditFieldLabel
            app.AcqusitionNumberEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.AcqusitionNumberEditFieldLabel.HorizontalAlignment = 'right';
            app.AcqusitionNumberEditFieldLabel.Position = [17 83 106 22];
            app.AcqusitionNumberEditFieldLabel.Text = 'Acqusition Number';

            % Create AcqusitionNumberEditField
            app.AcqusitionNumberEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.AcqusitionNumberEditField.Limits = [0 100000];
            app.AcqusitionNumberEditField.ValueDisplayFormat = '%.0f';
            app.AcqusitionNumberEditField.ValueChangedFcn = createCallbackFcn(app, @AcqusitionNumberEditFieldValueChanged, true);
            app.AcqusitionNumberEditField.Editable = 'off';
            app.AcqusitionNumberEditField.Position = [132 83 67 22];

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.SampleAcquisitionPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [12 12 185 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.SampleAcquisitionPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [208 12 185 33];
            app.STOPButton.Text = 'STOP';

            % Create CurrentMeasurementCountEditFieldLabel
            app.CurrentMeasurementCountEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.CurrentMeasurementCountEditFieldLabel.HorizontalAlignment = 'right';
            app.CurrentMeasurementCountEditFieldLabel.Position = [132 55 164 22];
            app.CurrentMeasurementCountEditFieldLabel.Text = 'Current Measurement Count  ';

            % Create CurrentMeasurementCountEditField
            app.CurrentMeasurementCountEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.CurrentMeasurementCountEditField.Limits = [0 Inf];
            app.CurrentMeasurementCountEditField.ValueDisplayFormat = '%.0f';
            app.CurrentMeasurementCountEditField.Editable = 'off';
            app.CurrentMeasurementCountEditField.Position = [308 55 80 22];

            % Create ReadyLampLabel
            app.ReadyLampLabel = uilabel(app.SampleAcquisitionPanel);
            app.ReadyLampLabel.Position = [55 54 58 22];
            app.ReadyLampLabel.Text = 'Ready';

            % Create ReadyLamp
            app.ReadyLamp = uilamp(app.SampleAcquisitionPanel);
            app.ReadyLamp.Position = [26 56 20 20];

            % Create SampleEditFieldLabel
            app.SampleEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.SampleEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleEditFieldLabel.Position = [9 276 46 22];
            app.SampleEditFieldLabel.Text = 'Sample';

            % Create SampleEditField
            app.SampleEditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.SampleEditField.Position = [82 276 163 22];

            % Create DescriptionEditFieldLabel
            app.DescriptionEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.DescriptionEditFieldLabel.HorizontalAlignment = 'right';
            app.DescriptionEditFieldLabel.Position = [9 244 65 22];
            app.DescriptionEditFieldLabel.Text = 'Description';

            % Create DescriptionEditField
            app.DescriptionEditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.DescriptionEditField.Position = [81 244 310 22];

            % Create ModeDropDownLabel
            app.ModeDropDownLabel = uilabel(app.SampleAcquisitionPanel);
            app.ModeDropDownLabel.HorizontalAlignment = 'right';
            app.ModeDropDownLabel.Position = [259 276 35 22];
            app.ModeDropDownLabel.Text = 'Mode';

            % Create ModeDropDown
            app.ModeDropDown = uidropdown(app.SampleAcquisitionPanel);
            app.ModeDropDown.Items = {'TX', 'RX'};
            app.ModeDropDown.Position = [306 276 83 22];
            app.ModeDropDown.Value = 'TX';

            % Create Metadata1EditFieldLabel
            app.Metadata1EditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.Metadata1EditFieldLabel.HorizontalAlignment = 'right';
            app.Metadata1EditFieldLabel.Position = [9 212 65 22];
            app.Metadata1EditFieldLabel.Text = 'Metadata 1';

            % Create Metadata1EditField
            app.Metadata1EditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.Metadata1EditField.Position = [82 212 142 22];

            % Create NumericValueEditField_2Label
            app.NumericValueEditField_2Label = uilabel(app.SampleAcquisitionPanel);
            app.NumericValueEditField_2Label.HorizontalAlignment = 'right';
            app.NumericValueEditField_2Label.Position = [227 212 83 22];
            app.NumericValueEditField_2Label.Text = 'Numeric Value';

            % Create NumericValueEditField_1
            app.NumericValueEditField_1 = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.NumericValueEditField_1.Position = [318 212 70 22];

            % Create Metadata2EditFieldLabel
            app.Metadata2EditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.Metadata2EditFieldLabel.HorizontalAlignment = 'right';
            app.Metadata2EditFieldLabel.Position = [9 181 65 22];
            app.Metadata2EditFieldLabel.Text = 'Metadata 2';

            % Create Metadata2EditField
            app.Metadata2EditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.Metadata2EditField.Position = [82 181 142 22];

            % Create NumericValueEditFieldLabel
            app.NumericValueEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.NumericValueEditFieldLabel.HorizontalAlignment = 'right';
            app.NumericValueEditFieldLabel.Position = [228 181 83 22];
            app.NumericValueEditFieldLabel.Text = 'Numeric Value';

            % Create NumericValueEditField_2
            app.NumericValueEditField_2 = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.NumericValueEditField_2.Position = [318 181 70 22];

            % Create AcquisitionTimeEditField
            app.AcquisitionTimeEditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.AcquisitionTimeEditField.Editable = 'off';
            app.AcquisitionTimeEditField.HorizontalAlignment = 'right';
            app.AcquisitionTimeEditField.FontColor = [0.502 0.502 0.502];
            app.AcquisitionTimeEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.AcquisitionTimeEditField.Position = [229 144 154 22];
            app.AcquisitionTimeEditField.Value = 'Acquisition Time';

            % Create IntervalsecLabel
            app.IntervalsecLabel = uilabel(app.SampleAcquisitionPanel);
            app.IntervalsecLabel.HorizontalAlignment = 'right';
            app.IntervalsecLabel.Position = [237 83 74 22];
            app.IntervalsecLabel.Text = 'Interval (sec)';

            % Create IntervalsecEditField
            app.IntervalsecEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.IntervalsecEditField.Limits = [0 Inf];
            app.IntervalsecEditField.ValueDisplayFormat = '%5.2f';
            app.IntervalsecEditField.Editable = 'off';
            app.IntervalsecEditField.Position = [321 83 67 22];
            app.IntervalsecEditField.Value = 0.1;

            % Create TimeLeftsecEditFieldLabel
            app.TimeLeftsecEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.TimeLeftsecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimeLeftsecEditFieldLabel.Position = [225 112 85 22];
            app.TimeLeftsecEditFieldLabel.Text = 'Time Left (sec)';

            % Create TimeLeftsecEditField
            app.TimeLeftsecEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.TimeLeftsecEditField.Limits = [0 Inf];
            app.TimeLeftsecEditField.ValueDisplayFormat = '%5.2f';
            app.TimeLeftsecEditField.Editable = 'off';
            app.TimeLeftsecEditField.Position = [321 112 67 22];

            % Create THzLampLabel
            app.THzLampLabel = uilabel(app.AcquisitionDialogUIFigure);
            app.THzLampLabel.HorizontalAlignment = 'right';
            app.THzLampLabel.Position = [351 574 27 22];
            app.THzLampLabel.Text = 'THz';

            % Create THzLamp
            app.THzLamp = uilamp(app.AcquisitionDialogUIFigure);
            app.THzLamp.Position = [385 574 20 20];

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