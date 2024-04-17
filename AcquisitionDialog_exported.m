classdef AcquisitionDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TeraSmartControlUIFigure        matlab.ui.Figure
        THzLamp                         matlab.ui.control.Lamp
        THzLampLabel                    matlab.ui.control.Label
        SampleAcquisitionPanel          matlab.ui.container.Panel
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
            TcellAcq = app.TcellAcq;
            updateTableRemote(app.MainApp,TcellAcq);
        end
      
        function updateTcellAcq(app)
            
        end

        function matCurrent = readWaveform(app) % single scan

            matCurrent = [];
            
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

        % Close request function: TeraSmartControlUIFigure
        function TeraSmartControlUIFigureCloseRequest(app, event)
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
            updateMain(app)
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

            % Create TeraSmartControlUIFigure and hide until all components are created
            app.TeraSmartControlUIFigure = uifigure('Visible', 'off');
            app.TeraSmartControlUIFigure.Position = [100 100 438 436];
            app.TeraSmartControlUIFigure.Name = 'TeraSmart Control';
            app.TeraSmartControlUIFigure.Icon = fullfile(pathToMLAPP, 'CaT_logo.png');
            app.TeraSmartControlUIFigure.CloseRequestFcn = createCallbackFcn(app, @TeraSmartControlUIFigureCloseRequest, true);

            % Create ReadStatusButton
            app.ReadStatusButton = uibutton(app.TeraSmartControlUIFigure, 'push');
            app.ReadStatusButton.FontWeight = 'bold';
            app.ReadStatusButton.Position = [17 399 109 27];
            app.ReadStatusButton.Text = 'Read Status';

            % Create Image
            app.Image = uiimage(app.TeraSmartControlUIFigure);
            app.Image.Position = [259 8 167 38];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'MENLO-Logo.png');

            % Create EditField
            app.EditField = uieditfield(app.TeraSmartControlUIFigure, 'text');
            app.EditField.Editable = 'off';
            app.EditField.Position = [138 400 198 26];

            % Create ReferenceAcquisitionPanel
            app.ReferenceAcquisitionPanel = uipanel(app.TeraSmartControlUIFigure);
            app.ReferenceAcquisitionPanel.Title = 'Reference Acquisition';
            app.ReferenceAcquisitionPanel.FontWeight = 'bold';
            app.ReferenceAcquisitionPanel.FontSize = 13;
            app.ReferenceAcquisitionPanel.Position = [16 223 409 164];

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
            app.SampleAcquisitionPanel = uipanel(app.TeraSmartControlUIFigure);
            app.SampleAcquisitionPanel.Title = 'Sample Acquisition';
            app.SampleAcquisitionPanel.FontWeight = 'bold';
            app.SampleAcquisitionPanel.FontSize = 13;
            app.SampleAcquisitionPanel.Position = [17 50 409 162];

            % Create MultipleAcquisitionCheckBox
            app.MultipleAcquisitionCheckBox = uicheckbox(app.SampleAcquisitionPanel);
            app.MultipleAcquisitionCheckBox.ValueChangedFcn = createCallbackFcn(app, @MultipleAcquisitionCheckBoxValueChanged, true);
            app.MultipleAcquisitionCheckBox.Text = 'Multiple Acquisition';
            app.MultipleAcquisitionCheckBox.Position = [20 114 124 22];

            % Create TimesecEditFieldLabel
            app.TimesecEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.TimesecEditFieldLabel.HorizontalAlignment = 'right';
            app.TimesecEditFieldLabel.Position = [17 88 61 22];
            app.TimesecEditFieldLabel.Text = 'Time (sec)';

            % Create TimesecEditField
            app.TimesecEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.TimesecEditField.Limits = [0 100000];
            app.TimesecEditField.ValueDisplayFormat = '%.0f';
            app.TimesecEditField.ValueChangedFcn = createCallbackFcn(app, @TimesecEditFieldValueChanged, true);
            app.TimesecEditField.Editable = 'off';
            app.TimesecEditField.Position = [92 88 85 22];

            % Create AcqusitionnumberEditFieldLabel
            app.AcqusitionnumberEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.AcqusitionnumberEditFieldLabel.HorizontalAlignment = 'right';
            app.AcqusitionnumberEditFieldLabel.Position = [190 89 104 22];
            app.AcqusitionnumberEditFieldLabel.Text = 'Acqusition number';

            % Create AcqusitionnumberEditField
            app.AcqusitionnumberEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.AcqusitionnumberEditField.Limits = [0 100000];
            app.AcqusitionnumberEditField.ValueDisplayFormat = '%.0f';
            app.AcqusitionnumberEditField.ValueChangedFcn = createCallbackFcn(app, @AcqusitionnumberEditFieldValueChanged, true);
            app.AcqusitionnumberEditField.Editable = 'off';
            app.AcqusitionnumberEditField.Position = [303 89 85 22];

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.SampleAcquisitionPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [14 14 185 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.SampleAcquisitionPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [209 14 185 33];
            app.STOPButton.Text = 'STOP';

            % Create CurrentMeasurementEditFieldLabel
            app.CurrentMeasurementEditFieldLabel = uilabel(app.SampleAcquisitionPanel);
            app.CurrentMeasurementEditFieldLabel.HorizontalAlignment = 'right';
            app.CurrentMeasurementEditFieldLabel.Position = [175 61 122 22];
            app.CurrentMeasurementEditFieldLabel.Text = 'Current Measurement';

            % Create CurrentMeasurementEditField
            app.CurrentMeasurementEditField = uieditfield(app.SampleAcquisitionPanel, 'numeric');
            app.CurrentMeasurementEditField.Limits = [0 Inf];
            app.CurrentMeasurementEditField.ValueDisplayFormat = '%.0f';
            app.CurrentMeasurementEditField.Editable = 'off';
            app.CurrentMeasurementEditField.Position = [303 61 85 22];

            % Create ReadyLampLabel
            app.ReadyLampLabel = uilabel(app.SampleAcquisitionPanel);
            app.ReadyLampLabel.Position = [51 60 58 22];
            app.ReadyLampLabel.Text = 'Ready';

            % Create ReadyLamp
            app.ReadyLamp = uilamp(app.SampleAcquisitionPanel);
            app.ReadyLamp.Position = [22 62 20 20];

            % Create THzLampLabel
            app.THzLampLabel = uilabel(app.TeraSmartControlUIFigure);
            app.THzLampLabel.HorizontalAlignment = 'right';
            app.THzLampLabel.Position = [351 402 27 22];
            app.THzLampLabel.Text = 'THz';

            % Create THzLamp
            app.THzLamp = uilamp(app.TeraSmartControlUIFigure);
            app.THzLamp.Position = [385 402 20 20];

            % Show the figure after all components are created
            app.TeraSmartControlUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AcquisitionDialog_exported(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TeraSmartControlUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TeraSmartControlUIFigure)
        end
    end
end