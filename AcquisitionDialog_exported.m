classdef AcquisitionDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        AcquisitionDialogUIFigure       matlab.ui.Figure
        THzLamp                         matlab.ui.control.Lamp
        THzLampLabel                    matlab.ui.control.Label
        SampleAcquisitionPanel          matlab.ui.container.Panel
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
        CurrentMeasurementEditField     matlab.ui.control.NumericEditField
        CurrentMeasurementEditFieldLabel  matlab.ui.control.Label
        STOPButton                      matlab.ui.control.Button
        ACQUIREButton                   matlab.ui.control.Button
        AcqusitionnumberEditField       matlab.ui.control.NumericEditField
        AcqusitionnumberEditFieldLabel  matlab.ui.control.Label
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
        startCol % Start column
        numAcq % total number of acquisitions
        TcellAcq % Acquistion table cell
        matBaseline % Baseline matrix [time stamps; amplitudes]
        matReference % Reference matrix [time stamps; amplitudes]
        matPumpRef % Pump reference matrix [time stamps; amplitudes]
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
            updateTableRemote(app.MainApp,TcellAcq);
        end

        function matCurrent = addMeasurement(app) % single scan#
                numAcq = app.numAcq;
                numAcq = numAcq + 1;
                fig = app.AcquisitionDialogUIFigure;

                curCol = app.startCol + numAcq;
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
        function startupFcn(app, mainapp, startCol)
            % Store main app object
            app.MainApp = mainapp;
            app.startCol = startCol;
            app.numAcq = 0;
        end

        % Value changed function: MultipleAcquisitionCheckBox
        function MultipleAcquisitionCheckBoxValueChanged(app, event)
            value = app.MultipleAcquisitionCheckBox.Value;
            if value
                app.TimesecEditField.Editable = "on";
                app.AcqusitionnumberEditField.Editable = "on";
            else
                app.TimesecEditField.Editable = "off";
                app.AcqusitionnumberEditField.Editable = "off";
                app.TimesecEditField.Value = 0;
                app.AcqusitionnumberEditField.Value = 0;
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
            app.AcqusitionnumberEditField.Value = 0;
        end

        % Value changed function: AcqusitionnumberEditField
        function AcqusitionnumberEditFieldValueChanged(app, event)
            value = app.AcqusitionnumberEditField.Value;
            app.TimesecEditField.Value = 0;
        end

        % Close request function: AcquisitionDialogUIFigure
        function AcquisitionDialogUIFigureCloseRequest(app, event)
            % Enable Acquire button in main app, if the app is still open
            if isvalid(app.MainApp)
                app.MainApp.AcquirefromTeraSmartButton.Enable = "on";
            end

            % Delete the dialog box
            delete(app)            
        end

        % Button pushed function: ACQUIREButton
        function ACQUIREButtonPushed(app, event)
            app.ReadyLamp.Color = [0.85,0.33,0.10];
            app.ReadyLampLabel.Text = "Scaning...";
            addMeasurement(app);
        end

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            app.ReadyLamp.Color = "Green";
            app.ReadyLampLabel.Text = "Ready";  
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
            app.AcquisitionDialogUIFigure.Position = [100 100 438 581];
            app.AcquisitionDialogUIFigure.Name = 'TeraSmart Control';
            app.AcquisitionDialogUIFigure.Icon = fullfile(pathToMLAPP, 'CaT_logo.png');
            app.AcquisitionDialogUIFigure.CloseRequestFcn = createCallbackFcn(app, @AcquisitionDialogUIFigureCloseRequest, true);

            % Create ReadStatusButton
            app.ReadStatusButton = uibutton(app.AcquisitionDialogUIFigure, 'push');
            app.ReadStatusButton.FontWeight = 'bold';
            app.ReadStatusButton.Position = [17 544 109 27];
            app.ReadStatusButton.Text = 'Read Status';

            % Create Image
            app.Image = uiimage(app.AcquisitionDialogUIFigure);
            app.Image.Position = [258 8 167 38];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'MENLO-Logo.png');

            % Create EditField
            app.EditField = uieditfield(app.AcquisitionDialogUIFigure, 'text');
            app.EditField.Editable = 'off';
            app.EditField.Position = [138 545 198 26];

            % Create ReferenceAcquisitionPanel
            app.ReferenceAcquisitionPanel = uipanel(app.AcquisitionDialogUIFigure);
            app.ReferenceAcquisitionPanel.Title = 'Reference Acquisition';
            app.ReferenceAcquisitionPanel.FontWeight = 'bold';
            app.ReferenceAcquisitionPanel.FontSize = 13;
            app.ReferenceAcquisitionPanel.Position = [16 368 409 164];

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
            app.PumpCheckBox.Position = [139 115 53 22];

            % Create SubtractBaselineCheckBox
            app.SubtractBaselineCheckBox = uicheckbox(app.ReferenceAcquisitionPanel);
            app.SubtractBaselineCheckBox.Text = 'Subtract Baseline';
            app.SubtractBaselineCheckBox.Position = [15 115 116 22];

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
            app.SampleAcquisitionPanel.Position = [17 53 409 304];

            % Create MultipleAcquisitionCheckBox
            app.MultipleAcquisitionCheckBox = uicheckbox(app.SampleAcquisitionPanel);
            app.MultipleAcquisitionCheckBox.ValueChangedFcn = createCallbackFcn(app, @MultipleAcquisitionCheckBoxValueChanged, true);
            app.MultipleAcquisitionCheckBox.Text = 'Multiple Acquisition';
            app.MultipleAcquisitionCheckBox.Position = [22 119 124 22];

            % Create TimesecEditFieldLabel
            app.TimesecEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.TimesecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimesecEditFieldLabel.Position = [18 90 61 22];
            app.TimesecEditFieldLabel.Text = 'Time (sec)';

            % Create TimesecEditField
            app.TimesecEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.TimesecEditField.Limits = [0 100000];
            app.TimesecEditField.ValueDisplayFormat = '%.0f';
            app.TimesecEditField.ValueChangedFcn = createCallbackFcn(app, @TimesecEditFieldValueChanged, true);
            app.TimesecEditField.Editable = 'off';
            app.TimesecEditField.Position = [93 90 85 22];

            % Create AcqusitionnumberEditFieldLabel
            app.AcqusitionnumberEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.AcqusitionnumberEditFieldLabel.HorizontalAlignment = 'right';
            app.AcqusitionnumberEditFieldLabel.Position = [188 90 104 22];
            app.AcqusitionnumberEditFieldLabel.Text = 'Acqusition number';

            % Create AcqusitionnumberEditField
            app.AcqusitionnumberEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.AcqusitionnumberEditField.Limits = [0 100000];
            app.AcqusitionnumberEditField.ValueDisplayFormat = '%.0f';
            app.AcqusitionnumberEditField.ValueChangedFcn = createCallbackFcn(app, @AcqusitionnumberEditFieldValueChanged, true);
            app.AcqusitionnumberEditField.Editable = 'off';
            app.AcqusitionnumberEditField.Position = [308 90 80 22];

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.SampleAcquisitionPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [12 18 185 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.SampleAcquisitionPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [208 18 185 33];
            app.STOPButton.Text = 'STOP';

            % Create CurrentMeasurementEditFieldLabel
            app.CurrentMeasurementEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.CurrentMeasurementEditFieldLabel.HorizontalAlignment = 'right';
            app.CurrentMeasurementEditFieldLabel.Position = [174 61 122 22];
            app.CurrentMeasurementEditFieldLabel.Text = 'Current Measurement';

            % Create CurrentMeasurementEditField
            app.CurrentMeasurementEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.CurrentMeasurementEditField.Limits = [0 Inf];
            app.CurrentMeasurementEditField.ValueDisplayFormat = '%.0f';
            app.CurrentMeasurementEditField.Editable = 'off';
            app.CurrentMeasurementEditField.Position = [308 61 80 22];

            % Create ReadyLampLabel
            app.ReadyLampLabel = uilabel(app.SampleAcquisitionPanel);
            app.ReadyLampLabel.Position = [55 60 58 22];
            app.ReadyLampLabel.Text = 'Ready';

            % Create ReadyLamp
            app.ReadyLamp = uilamp(app.SampleAcquisitionPanel);
            app.ReadyLamp.Position = [26 62 20 20];

            % Create SampleEditFieldLabel
            app.SampleEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.SampleEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleEditFieldLabel.Position = [9 251 46 22];
            app.SampleEditFieldLabel.Text = 'Sample';

            % Create SampleEditField
            app.SampleEditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.SampleEditField.Position = [82 251 163 22];

            % Create DescriptionEditFieldLabel
            app.DescriptionEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.DescriptionEditFieldLabel.HorizontalAlignment = 'right';
            app.DescriptionEditFieldLabel.Position = [9 219 65 22];
            app.DescriptionEditFieldLabel.Text = 'Description';

            % Create DescriptionEditField
            app.DescriptionEditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.DescriptionEditField.Position = [81 219 310 22];

            % Create ModeDropDownLabel
            app.ModeDropDownLabel = uilabel(app.SampleAcquisitionPanel);
            app.ModeDropDownLabel.HorizontalAlignment = 'right';
            app.ModeDropDownLabel.Position = [259 251 35 22];
            app.ModeDropDownLabel.Text = 'Mode';

            % Create ModeDropDown
            app.ModeDropDown = uidropdown(app.SampleAcquisitionPanel);
            app.ModeDropDown.Items = {'TX', 'RX'};
            app.ModeDropDown.Position = [306 251 83 22];
            app.ModeDropDown.Value = 'TX';

            % Create Metadata1EditFieldLabel
            app.Metadata1EditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.Metadata1EditFieldLabel.HorizontalAlignment = 'right';
            app.Metadata1EditFieldLabel.Position = [9 187 65 22];
            app.Metadata1EditFieldLabel.Text = 'Metadata 1';

            % Create Metadata1EditField
            app.Metadata1EditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.Metadata1EditField.Position = [82 187 142 22];

            % Create NumericValueEditField_2Label
            app.NumericValueEditField_2Label = uilabel(app.SampleAcquisitionPanel);
            app.NumericValueEditField_2Label.HorizontalAlignment = 'right';
            app.NumericValueEditField_2Label.Position = [227 187 83 22];
            app.NumericValueEditField_2Label.Text = 'Numeric Value';

            % Create NumericValueEditField_1
            app.NumericValueEditField_1 = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.NumericValueEditField_1.Position = [318 187 70 22];

            % Create Metadata2EditFieldLabel
            app.Metadata2EditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.Metadata2EditFieldLabel.HorizontalAlignment = 'right';
            app.Metadata2EditFieldLabel.Position = [9 156 65 22];
            app.Metadata2EditFieldLabel.Text = 'Metadata 2';

            % Create Metadata2EditField
            app.Metadata2EditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.Metadata2EditField.Position = [82 156 142 22];

            % Create NumericValueEditFieldLabel
            app.NumericValueEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.NumericValueEditFieldLabel.HorizontalAlignment = 'right';
            app.NumericValueEditFieldLabel.Position = [228 156 83 22];
            app.NumericValueEditFieldLabel.Text = 'Numeric Value';

            % Create NumericValueEditField_2
            app.NumericValueEditField_2 = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.NumericValueEditField_2.Position = [318 156 70 22];

            % Create AcquisitionTimeEditField
            app.AcquisitionTimeEditField = uieditfield(app.SampleAcquisitionPanel, 'text');
            app.AcquisitionTimeEditField.Editable = 'off';
            app.AcquisitionTimeEditField.HorizontalAlignment = 'right';
            app.AcquisitionTimeEditField.FontColor = [0.502 0.502 0.502];
            app.AcquisitionTimeEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.AcquisitionTimeEditField.Position = [234 119 154 22];
            app.AcquisitionTimeEditField.Value = 'Acquisition Time';

            % Create THzLampLabel
            app.THzLampLabel = uilabel(app.AcquisitionDialogUIFigure);
            app.THzLampLabel.HorizontalAlignment = 'right';
            app.THzLampLabel.Position = [351 547 27 22];
            app.THzLampLabel.Text = 'THz';

            % Create THzLamp
            app.THzLamp = uilamp(app.AcquisitionDialogUIFigure);
            app.THzLamp.Position = [385 547 20 20];

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