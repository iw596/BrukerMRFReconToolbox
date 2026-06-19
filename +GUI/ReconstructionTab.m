classdef ReconstructionTab < handle
    % ReconstructionTab - Handles the Reconstruction tab UI and functionality
    %   This class manages reconstruction operations and related controls

    properties
        Parent          % Reference to main MRFViewer instance
        TabHandle       % Handle to the tab itself

        % Controls
        RunReconButton
        LoadFileButton
        RegModeLabel
        RegModeDropdown
        LambdaLabel
        LambdaEdit
        EstimateMaskCheckbox

        ReconSettings = struct()


    end
    methods
        function obj = ReconstructionTab(parentMRFViewer, parentTab)
            % Initialize ReconstructionTab
            %   parentMRFViewer: Reference to the MRFViewer instance
            %   parentTab: The uitab container for this tab

            obj.Parent = parentMRFViewer;
            obj.TabHandle = parentTab;

            obj.createUI();
        end

        function createUI(obj)
            % Create all UI elements for the Reconstruction tab

            obj.RunReconButton = uibutton(obj.TabHandle,...
                'Text','Run Reconstruction',...
                'Position',[20 620 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.runReconstruction());

            obj.LoadFileButton = uibutton(obj.TabHandle,...
                'Text','Load File',...
                'Position',[20 580 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.loadFile());

            obj.RegModeLabel = uilabel(obj.TabHandle, ...
                'Text', 'Regularization mode', ...
                'Position', [20 540 130 22]);
            obj.RegModeDropdown = uidropdown(obj.TabHandle, ...
                'Items', {'Locally-low rank', 'Wavelet', 'Total variation'}, ...
                'Value', 'Locally-low rank', ...
                'Position', [160 540 180 22], ...
                'Tooltip', 'Select regularization method for reconstruction');

            obj.LambdaLabel = uilabel(obj.TabHandle, ...
                'Text', 'Lambda', ...
                'Position', [20 510 130 22]);
            obj.LambdaEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 0.01, ...
                'Limits', [0 Inf], ...
                'LowerLimitInclusive', false, ...
                'Position', [160 510 180 22], ...
                'Tooltip', 'Regularization strength (must be > 0)');

            obj.EstimateMaskCheckbox = uicheckbox(obj.TabHandle, ...
                'Text', 'Estimate mask', ...
                'Value', false, ...
                'Position', [20 478 180 22], ...
                'Tooltip', 'Estimate mask automatically during reconstruction');

            obj.resizeUI([]);
        end

        function runReconstruction(obj)
            % Placeholder for the reconstruction action.
            % Collects current UI parameters for downstream reconstruction.

            regMode = obj.RegModeDropdown.Value;
            lambda = obj.LambdaEdit.Value;
            estimateMask = obj.EstimateMaskCheckbox.Value;

            if isempty(lambda) || ~isfinite(lambda) || lambda <= 0
                uialert(obj.TabHandle.Parent, ...
                    'Lambda must be a positive number.', ...
                    'Invalid Lambda', 'Icon', 'warning');
                return;
            end

            settings = struct();
            settings.RegularizationMode = regMode;
            settings.Lambda = lambda;
            settings.EstimateMask = estimateMask;
            settings.LoadDir = obj.Parent.LastLoadDir;

            obj.ReconSettings = settings;

            disp('Reconstruction initiated with settings:');
            disp(settings);
        end

        function loadFile(obj)
            disp("Load File")
            % Open a directory selection dialog and store the selected path
            % Uses uigetdir for directory selection; if cancelled, do nothing
            startDir = pwd;
            selectedDir = uigetdir(startDir, 'Select directory containing files');
            if isequal(selectedDir, 0)
                % User cancelled
                return;
            end
            % Store selected directory in the shared parent state
            obj.Parent.LastLoadDir = selectedDir;
            % Optionally display the chosen directory
            disp(['Selected directory: ', selectedDir])
        end
        
        function resizeUI(obj, ~)
            % Update UI element positions based on current tab dimensions.

            if isempty(obj.TabHandle) || ~isvalid(obj.TabHandle)
                return;
            end

            tabPos = obj.TabHandle.Position;
            tabW = max(tabPos(3), 420);
            tabH = max(tabPos(4), 320);

            margin = 20;
            rowGap = 10;
            ctrlH = 28;
            fieldW = min(220, max(160, floor(0.35 * tabW)));

            yTop = tabH - margin - ctrlH;

            obj.RunReconButton.Position = [margin yTop 180 ctrlH];
            y = yTop - rowGap - ctrlH;

            obj.LoadFileButton.Position = [margin y 180 ctrlH];
            y = y - rowGap - 22;

            obj.RegModeLabel.Position = [margin y 130 22];
            obj.RegModeDropdown.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.LambdaLabel.Position = [margin y 130 22];
            obj.LambdaEdit.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.EstimateMaskCheckbox.Position = [margin y 180 22];
        end

        
    end
end
