classdef ReconstructionTab < handle
    % ReconstructionTab - Handles the Reconstruction tab UI and functionality
    %   This class manages reconstruction operations and related controls

    properties
        Parent          % Reference to main MRFViewer instance
        TabHandle       % Handle to the tab itself

        % Controls
        RunReconButton
        LoadFileButton
        LoadDictionaryButton
        RegModeLabel
        RegModeDropdown
        LambdaLabel
        LambdaEdit
        EstimateMaskCheckbox
        DataInfoLabel
        DataInfoTextArea
        DictionaryInfoLabel

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
                'Text','Load Data',...
                'Position',[20 580 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.loadFile());

            obj.LoadDictionaryButton = uibutton(obj.TabHandle,...
                'Text','Load Dictionary',...
                'Position',[210 580 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.loadDictionary());

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

            obj.DataInfoLabel = uilabel(obj.TabHandle, ...
                'Text', 'Loaded data info', ...
                'FontWeight', 'bold', ...
                'Position', [20 430 180 22]);

            obj.DataInfoTextArea = uitextarea(obj.TabHandle, ...
                'Editable', 'off', ...
                'Value', {'No data loaded.'}, ...
                'Position', [20 280 420 145]);

            obj.DictionaryInfoLabel = uilabel(obj.TabHandle, ...
                'Text', 'Dictionary: none loaded', ...
                'Position', [20 252 420 22]);

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
            if isfield(obj.ReconSettings, 'DataPath')
                settings.DataPath = obj.ReconSettings.DataPath;
            end
            if isfield(obj.ReconSettings, 'DictionaryPath')
                settings.DictionaryPath = obj.ReconSettings.DictionaryPath;
            end

            obj.ReconSettings = settings;

            disp('Reconstruction initiated with settings:');
            disp(settings);
        end

        function loadFile(obj)
            % Load reconstruction data file and display basic metadata.
            [file, folder] = uigetfile( ...
                {'*.mat;*.nii;*.nii.gz','MRF Data Files (*.mat, *.nii, *.nii.gz)'; ...
                 '*.*','All Files (*.*)'}, ...
                'Select reconstruction data file');
            if isequal(file, 0)
                return;
            end

            fullPath = fullfile(folder, file);
            try
                [dims, nDims, nPoints, sourceText] = obj.getDataDimensions(fullPath);
            catch ME
                uialert(obj.TabHandle.Parent, ...
                    ['Could not load data info: ' ME.message], ...
                    'Data Load Error', 'Icon', 'error');
                return;
            end

            sizeStr = strjoin(arrayfun(@num2str, dims, 'UniformOutput', false), ' x ');
            obj.DataInfoTextArea.Value = {
                ['File: ' file], ...
                ['Source: ' sourceText], ...
                ['Size: ' sizeStr], ...
                ['Dimensions: ' num2str(nDims)], ...
                ['Points: ' num2str(nPoints)] ...
            };

            obj.Parent.LastLoadDir = folder;
            obj.ReconSettings.DataPath = fullPath;
            obj.ReconSettings.DataSize = dims;
            obj.ReconSettings.DataDimensions = nDims;
            obj.ReconSettings.DataPoints = nPoints;

            disp(['Loaded data file: ', fullPath]);
        end

        function loadDictionary(obj)
            % Load MRF dictionary MAT file and display summary.
            [file, folder] = uigetfile( ...
                {'*.mat','MAT Files (*.mat)'}, ...
                'Select MRF dictionary file');
            if isequal(file, 0)
                return;
            end

            fullPath = fullfile(folder, file);
            try
                [dictSize, lutSize] = obj.getDictionarySummary(fullPath);
            catch ME
                uialert(obj.TabHandle.Parent, ...
                    ['Could not load dictionary: ' ME.message], ...
                    'Dictionary Load Error', 'Icon', 'error');
                return;
            end

            dictSizeStr = strjoin(arrayfun(@num2str, dictSize, 'UniformOutput', false), ' x ');
            if isempty(lutSize)
                lutText = 'LUT: not found';
            else
                lutText = ['LUT: ' strjoin(arrayfun(@num2str, lutSize, 'UniformOutput', false), ' x ')];
            end

            obj.DictionaryInfoLabel.Text = ['Dictionary: ', file, '  (dict ', dictSizeStr, '; ', lutText, ')'];

            obj.Parent.LastLoadDir = folder;
            obj.ReconSettings.DictionaryPath = fullPath;
            obj.ReconSettings.DictionarySize = dictSize;
            obj.ReconSettings.LUTSize = lutSize;

            disp(['Loaded dictionary file: ', fullPath]);
        end

        function [dims, nDims, nPoints, sourceText] = getDataDimensions(~, filePath)
            % Return metadata summary for supported data files.
            [~,~,ext] = fileparts(filePath);

            switch lower(ext)
                case '.mat'
                    vars = whos('-file', filePath);
                    if isempty(vars)
                        error('MAT file is empty.');
                    end

                    candidateIdx = find(arrayfun(@(v) isnumericType(v.class), vars), 1, 'first');
                    if isempty(candidateIdx)
                        candidateIdx = 1;
                    end

                    dims = vars(candidateIdx).size;
                    sourceText = ['MAT variable: ', vars(candidateIdx).name];

                case '.nii'
                    info = niftiinfo(filePath);
                    dims = info.ImageSize;
                    sourceText = 'NIfTI image';

                case '.gz'
                    info = niftiinfo(filePath);
                    dims = info.ImageSize;
                    sourceText = 'NIfTI image';

                otherwise
                    data = readmatrix(filePath);
                    if isempty(data)
                        error('File contains no numeric data.');
                    end
                    dims = size(data);
                    sourceText = 'Numeric text matrix';
            end

            dims = double(dims(:).');
            nDims = numel(dims);
            nPoints = prod(dims);

            function tf = isnumericType(className)
                tf = ismember(className, ...
                    {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64','logical'});
            end
        end

        function [dictSize, lutSize] = getDictionarySummary(~, filePath)
            % Read dictionary metadata from a MAT file.
            vars = whos('-file', filePath);
            if isempty(vars)
                error('MAT file is empty.');
            end

            names = {vars.name};
            idxDict = find(strcmpi(names, 'dict'), 1, 'first');
            if isempty(idxDict)
                error('No variable named "dict" found in MAT file.');
            end

            dictSize = vars(idxDict).size;

            idxLUT = find(strcmpi(names, 'LUT'), 1, 'first');
            if isempty(idxLUT)
                lutSize = [];
            else
                lutSize = vars(idxLUT).size;
            end
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
            fieldW = min(260, max(160, floor(0.35 * tabW)));

            yTop = tabH - margin - ctrlH;

            obj.RunReconButton.Position = [margin yTop 180 ctrlH];
            y = yTop - rowGap - ctrlH;

            obj.LoadFileButton.Position = [margin y 180 ctrlH];
            obj.LoadDictionaryButton.Position = [margin + 190 y 180 ctrlH];
            y = y - rowGap - 22;

            obj.RegModeLabel.Position = [margin y 130 22];
            obj.RegModeDropdown.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.LambdaLabel.Position = [margin y 130 22];
            obj.LambdaEdit.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.EstimateMaskCheckbox.Position = [margin y 180 22];

            y = y - rowGap - 24;
            obj.DataInfoLabel.Position = [margin y 180 22];

            infoH = max(80, min(180, y - 70));
            obj.DataInfoTextArea.Position = [margin y - infoH - 4 max(320, tabW - 2*margin) infoH];

            obj.DictionaryInfoLabel.Position = [margin y - infoH - 30 max(320, tabW - 2*margin) 22];
        end

        
    end
end
