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
        DimensionalityLabel
        DimensionalityDropdown
        ReconTargetLabel
        ReconTargetDropdown
        LambdaLabel
        LambdaEdit
        BlockSizeLabel
        BlockSizeEdit
        StrideLabel
        StrideEdit
        OuterIterationsLabel
        OuterIterationsEdit
        InnerIterationsLabel
        InnerIterationsEdit
        RhoLabel
        RhoEdit
        EstimateMaskCheckbox
        DataInfoLabel
        DataInfoTextArea
        DictionaryInfoLabel
        MRFReconModeLabel
        MRFReconModeDropdown
        B1CorrectionLabel
        B1CorrectionDropdown
        LoadB1MapButton
        B1MapInfoLabel
        OpenReconImagesButton

        ReconSettings = struct()
        LoadedMethodParams = struct() % Raw Bruker method parameters


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
                'Text','Load Method File',...
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
                'ValueChangedFcn', @(~,~) obj.updateRegularizationModeUI(), ...
                'Tooltip', 'Select regularization method for reconstruction');

            obj.DimensionalityLabel = uilabel(obj.TabHandle, ...
                'Text', 'Dimensionality', ...
                'Position', [20 560 130 22]);
            obj.DimensionalityDropdown = uidropdown(obj.TabHandle, ...
                'Items', {'2D', '3D'}, ...
                'Value', '2D', ...
                'Position', [160 560 180 22], ...
                'Enable', 'off', ...
                'Tooltip', 'Set automatically from loaded method field NDim');

            obj.ReconTargetLabel = uilabel(obj.TabHandle, ...
                'Text', 'Reconstruction target', ...
                'Position', [460 560 150 22], ...
                'FontWeight', 'bold');
            
            obj.ReconTargetDropdown = uidropdown(obj.TabHandle, ...
                'Items', {'MRF', 'T1', 'T2'}, ...
                'Value', 'MRF', ...
                'Position', [620 560 170 22], ...
                'ValueChangedFcn', @(~,~) obj.updateReconTargetUI(), ...
                'Tooltip', 'Select which output to reconstruct');

            obj.MRFReconModeLabel = uilabel(obj.TabHandle, ...
                'Text', 'MRF Recon Mode', ...
                'Position', [460 560 150 22], ...
                'FontWeight', 'bold');
            
            obj.MRFReconModeDropdown = uidropdown(obj.TabHandle, ...
                'Items', {'Direct', 'Iterative'}, ...
                'Value', 'Direct', ...
                'Position', [620 550 170 22], ...
                'ValueChangedFcn', @(~,~) obj.updateMRFReconModeUI(), ...
                'Tooltip', 'Select which output to reconstruct');

            obj.B1CorrectionLabel = uilabel(obj.TabHandle, ...
                'Text', 'B1 Correction', ...
                'Position', [460 520 150 22], ...
                'FontWeight', 'bold');

            obj.B1CorrectionDropdown = uidropdown(obj.TabHandle, ...
                'Items', {'None', 'Estimate from dictionary', 'Use B1 map'}, ...
                'Value', 'None', ...
                'Position', [620 520 170 22], ...
                'ValueChangedFcn', @(~,~) obj.updateB1CorrectionUI(), ...
                'Tooltip', 'Select how B1 correction is applied during MRF matching');

            obj.LoadB1MapButton = uibutton(obj.TabHandle, ...
                'Text', 'Load B1 Map', ...
                'Position', [460 490 150 24], ...
                'ButtonPushedFcn', @(~,~) obj.loadB1Map(), ...
                'Tooltip', 'Load a B1 map for voxel-wise B1-corrected MRF matching');

            obj.B1MapInfoLabel = uilabel(obj.TabHandle, ...
                'Text', 'B1 map: none loaded', ...
                'Position', [620 490 320 22]);

            obj.OpenReconImagesButton = uibutton(obj.TabHandle, ...
                'Text', 'Open Recon Images', ...
                'Position', [820 580 180 30], ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(~,~) obj.Parent.openReconstructionImagesTab(), ...
                'Tooltip', 'Open the reconstructed image browser');

            obj.LambdaLabel = uilabel(obj.TabHandle, ...
                'Text', 'Lambda', ...
                'Position', [20 510 130 22]);
            obj.LambdaEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 0.01, ...
                'Limits', [0 Inf], ...
                'LowerLimitInclusive', false, ...
                'Position', [160 510 180 22], ...
                'Tooltip', 'Regularization strength (must be > 0)');

            obj.BlockSizeLabel = uilabel(obj.TabHandle, ...
                'Text', 'Block size', ...
                'Position', [20 478 130 22]);
            obj.BlockSizeEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 8, ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', true, ...
                'Position', [160 478 180 22], ...
                'Tooltip', 'LLR patch/block size (pixels)');

            obj.StrideLabel = uilabel(obj.TabHandle, ...
                'Text', 'Stride', ...
                'Position', [20 446 130 22]);
            obj.StrideEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 4, ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', true, ...
                'Position', [160 446 180 22], ...
                'Tooltip', 'LLR sliding-window stride (pixels)');

            obj.OuterIterationsLabel = uilabel(obj.TabHandle, ...
                'Text', 'Outer iterations', ...
                'Position', [20 414 130 22]);
            obj.OuterIterationsEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 10, ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', true, ...
                'Position', [160 414 180 22], ...
                'Tooltip', 'ADMM outer iteration count');

            obj.InnerIterationsLabel = uilabel(obj.TabHandle, ...
                'Text', 'Inner iterations', ...
                'Position', [20 382 130 22]);
            obj.InnerIterationsEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 5, ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', true, ...
                'Position', [160 382 180 22], ...
                'Tooltip', 'ADMM inner iteration count');

            obj.RhoLabel = uilabel(obj.TabHandle, ...
                'Text', 'Rho', ...
                'Position', [20 350 130 22]);
            obj.RhoEdit = uieditfield(obj.TabHandle, 'numeric', ...
                'Value', 1, ...
                'Limits', [0 Inf], ...
                'LowerLimitInclusive', false, ...
                'Position', [160 350 180 22], ...
                'Tooltip', 'ADMM penalty parameter (must be > 0)');

            obj.EstimateMaskCheckbox = uicheckbox(obj.TabHandle, ...
                'Text', 'Estimate mask', ...
                'Value', false, ...
                'Position', [20 318 180 22], ...
                'Tooltip', 'Estimate mask automatically during reconstruction');

            obj.DataInfoLabel = uilabel(obj.TabHandle, ...
                'Text', 'Loaded method info', ...
                'FontWeight', 'bold', ...
                'Position', [20 430 180 22]);

            obj.DataInfoTextArea = uitextarea(obj.TabHandle, ...
                'Editable', 'off', ...
                'Value', {'No data loaded.'}, ...
                'Position', [20 280 420 145]);

            obj.DictionaryInfoLabel = uilabel(obj.TabHandle, ...
                'Text', 'Dictionary: none loaded', ...
                'Position', [20 252 420 22]);

            obj.updateRegularizationModeUI();
            obj.updateReconTargetUI();
            obj.updateMRFReconModeUI();
            obj.updateB1CorrectionUI();
            obj.resizeUI([]);
        end

        function runReconstruction(obj)
            % Placeholder for the reconstruction action.
            % Collects current UI parameters for downstream reconstruction.

            regMode = obj.RegModeDropdown.Value;
            if isfield(obj.LoadedMethodParams, 'NDim')
                dimensionality = obj.inferDimensionalityFromNDim(obj.LoadedMethodParams.NDim);
            else
                dimensionality = obj.DimensionalityDropdown.Value;
            end
            lambda = obj.LambdaEdit.Value;
            estimateMask = obj.EstimateMaskCheckbox.Value;
            reconTarget = obj.ReconTargetDropdown.Value;
            outerIterations = obj.OuterIterationsEdit.Value;
            innerIterations = obj.InnerIterationsEdit.Value;
            rho = obj.RhoEdit.Value;
            MRFReconMode = obj.MRFReconModeDropdown.Value;
            usesIterativeParams = strcmp(reconTarget, 'MRF') && strcmp(MRFReconMode, 'Iterative');
            b1CorrectionMode = obj.B1CorrectionDropdown.Value;
            estimateB1Map = strcmp(b1CorrectionMode, 'Estimate from dictionary');
            useProvidedB1Map = strcmp(b1CorrectionMode, 'Use B1 map');

            if isempty(fieldnames(obj.LoadedMethodParams))
                obj.showAlert('Load a Bruker method file first (NDim is required).', ...
                    'Method File Required', 'warning');
                return;
            end

            if usesIterativeParams
                if isempty(lambda) || ~isfinite(lambda) || lambda <= 0
                    obj.showAlert('Lambda must be a positive number.', ...
                        'Invalid Lambda', 'warning');
                    return;
                end

                if isempty(outerIterations) || ~isfinite(outerIterations) || outerIterations <= 0 || mod(outerIterations,1) ~= 0
                    obj.showAlert('Outer iterations must be a positive integer.', ...
                        'Invalid Outer Iterations', 'warning');
                    return;
                end

                if isempty(innerIterations) || ~isfinite(innerIterations) || innerIterations <= 0 || mod(innerIterations,1) ~= 0
                    obj.showAlert('Inner iterations must be a positive integer.', ...
                        'Invalid Inner Iterations', 'warning');
                    return;
                end

                if isempty(rho) || ~isfinite(rho) || rho <= 0
                    obj.showAlert('Rho must be a positive number.', ...
                        'Invalid Rho', 'warning');
                    return;
                end
            end

            settings = struct();
            settings.Dimensionality = dimensionality;
            settings.RegularizationMode = regMode;
            settings.Lambda = lambda;
            settings.ReconstructionTarget = reconTarget;
            settings.EstimateMask = estimateMask;
            settings.OuterIterations = outerIterations;
            settings.InnerIterations = innerIterations;
            settings.MRFReconMode = MRFReconMode;
            settings.Rho = rho;
            settings.B1CorrectionMode = b1CorrectionMode;
            settings.EstimateB1Map = estimateB1Map;
            settings.B1Map = [];
            if usesIterativeParams && strcmp(regMode, 'Locally-low rank')
                blockSize = obj.BlockSizeEdit.Value;
                stride = obj.StrideEdit.Value;
                if isempty(blockSize) || ~isfinite(blockSize) || blockSize <= 0 || mod(blockSize,1) ~= 0
                    uialert(obj.TabHandle.Parent, ...
                        'Block size must be a positive integer.', ...
                        'Invalid Block Size', 'Icon', 'warning');
                    return;
                end
                if isempty(stride) || ~isfinite(stride) || stride <= 0 || mod(stride,1) ~= 0
                    uialert(obj.TabHandle.Parent, ...
                        'Stride must be a positive integer.', ...
                        'Invalid Stride', 'Icon', 'warning');
                    return;
                end
                settings.BlockSize = blockSize;
                settings.Stride = stride;
            end

            if useProvidedB1Map
                if ~isfield(obj.ReconSettings, 'B1MapPath') || isempty(obj.ReconSettings.B1MapPath)
                    obj.showAlert('Select a B1 map file first, or switch B1 correction mode.', ...
                        'B1 Map Required', 'warning');
                    return;
                end

                try
                    settings.B1Map = obj.loadB1MapData(obj.ReconSettings.B1MapPath);
                    settings.B1MapPath = obj.ReconSettings.B1MapPath;
                catch ME
                    obj.showAlert(['Could not load B1 map: ' ME.message], ...
                        'B1 Map Error', 'error');
                    return;
                end
            end

            settings.LoadDir = obj.Parent.LastLoadDir;
            if isfield(obj.ReconSettings, 'DataPath')
                settings.DataPath = obj.ReconSettings.DataPath;
            end
            if isfield(obj.ReconSettings, 'DictionaryPath')
                settings.DictionaryPath = obj.ReconSettings.DictionaryPath;
            end
            settings.MethodParams = obj.LoadedMethodParams;

            obj.ReconSettings = settings;

            progressDlg = [];
            fig = ancestor(obj.TabHandle, 'figure');
            if ~isempty(fig) && isvalid(fig)
                progressDlg = uiprogressdlg(fig, ...
                    'Title', 'MRF Reconstruction', ...
                    'Message', 'Preparing reconstruction settings...', ...
                    'Indeterminate', 'on');
                drawnow limitrate;
            end

            try
                if ~isempty(progressDlg) && isvalid(progressDlg)
                    progressDlg.Message = 'Running reconstruction pipeline...';
                    drawnow limitrate;
                end

                result = runMRFReconstruction(obj.LoadedMethodParams, settings);
            catch ME
                if ~isempty(progressDlg) && isvalid(progressDlg)
                    close(progressDlg);
                end
                obj.showAlert(['Reconstruction skeleton failed: ' ME.message], ...
                    'Reconstruction Error', 'error');
                return;
            end

            if ~isempty(progressDlg) && isvalid(progressDlg)
                progressDlg.Message = 'Finalizing reconstruction output...';
                drawnow limitrate;
                close(progressDlg);
            end

            obj.ReconSettings.LastResult = result;
            hasReconImages = isstruct(result) && isfield(result, 'images') && ~isempty(result.images);
            if hasReconImages
                obj.OpenReconImagesButton.Enable = 'on';
                obj.Parent.ReconResult = result;
                obj.Parent.openReconstructionImagesTab();
            else
                obj.OpenReconImagesButton.Enable = 'off';
            end

            statusText = 'Completed';
            if isstruct(result) && isfield(result, 'Status') && ~isempty(result.Status)
                statusText = result.Status;
            end

            logLines = {'Reconstruction completed.'};
            if isstruct(result) && isfield(result, 'Log') && ~isempty(result.Log)
                logLines = result.Log(:)';
            end

            obj.DataInfoTextArea.Value = [ ...
                {['Reconstruction mode: ' char(dimensionality)]}, ...
                {['Target: ' char(reconTarget)]}, ...
                {['Regularizer: ' char(regMode)]}, ...
                {['Status: ' char(string(statusText))]}, ...
                logLines'];

            disp('Reconstruction skeleton completed with settings:');
            disp(settings);
            disp(result);
        end

        function loadFile(obj)
            % Load Bruker method file and display parsed method metadata.
            [file, folder] = uigetfile({'*','Bruker method file (usually named method)'}, ...
                'Select Bruker method file');
            if isequal(file, 0)
                return;
            end

            methodPath = fullfile(folder, file);
            scanDir = folder;
            try
                params = LoadBrukerData(scanDir, true);
            catch ME
                obj.showAlert(['Could not load Bruker method file: ' ME.message], ...
                    'Data Load Error', 'error');
                return;
            end

            trMs = NaN;
            teMs = NaN;
            nPrep = NaN;
            nFA = NaN;
            thickMm = NaN;
            if isfield(params, 'TR') && ~isempty(params.TR)
                trMs = params.TR * 1000;
            end
            if isfield(params, 'TE') && ~isempty(params.TE)
                teMs = params.TE * 1000;
            end
            if isfield(params, 'NPointsPerPrep') && ~isempty(params.NPointsPerPrep)
                nPrep = params.NPointsPerPrep;
            end
            if isfield(params, 'MRFFA') && ~isempty(params.MRFFA)
                nFA = numel(params.MRFFA);
            elseif isfield(params, 'NMRFFA') && ~isempty(params.NMRFFA)
                nFA = params.NMRFFA;
            end
            if isfield(params, 'Thickness') && ~isempty(params.Thickness)
                thickMm = params.Thickness * 1000;
            end

            ndimText = 'Unknown';
            inferredDimensionality = '2D';
            if isfield(params, 'NDim') && ~isempty(params.NDim)
                ndimText = num2str(params.NDim);
                inferredDimensionality = obj.inferDimensionalityFromNDim(params.NDim);
            end
            obj.DimensionalityDropdown.Value = inferredDimensionality;
            obj.LoadedMethodParams = params;

            obj.DataInfoTextArea.Value = {
                ['Method file: ' file], ...
                ['Scan dir: ' scanDir], ...
                ['NDim: ' ndimText], ...
                ['Reconstruction mode: ' inferredDimensionality], ...
                sprintf('TR: %.3f ms', trMs), ...
                sprintf('TE: %.3f ms', teMs), ...
                sprintf('Slice thickness: %.3f mm', thickMm), ...
                sprintf('NPointsPerPrep: %d', round(nPrep)), ...
                sprintf('FA points: %d', round(nFA)) ...
            };

            obj.Parent.LastLoadDir = folder;
            obj.ReconSettings.DataPath = methodPath;
            obj.ReconSettings.MethodPath = methodPath;
            obj.ReconSettings.ScanDir = scanDir;
            obj.ReconSettings.MethodParams = params;
            obj.ReconSettings.Dimensionality = inferredDimensionality;

            disp(['Loaded Bruker method file: ', methodPath]);
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
                obj.showAlert(['Could not load dictionary: ' ME.message], ...
                    'Dictionary Load Error', 'error');
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

            obj.DimensionalityLabel.Position = [margin y 130 22];
            obj.DimensionalityDropdown.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            rightX = min(tabW - margin - 320, margin + 420);
            rightX = max(rightX, margin + 360);
            obj.ReconTargetLabel.Position = [rightX yTop 150 22];
            obj.ReconTargetDropdown.Position = [rightX + 155 yTop 165 22];
            
            obj.MRFReconModeLabel.Position = [rightX yTop-30 150 22];
            obj.MRFReconModeDropdown.Position = [rightX + 155 yTop-30 165 22];

            obj.B1CorrectionLabel.Position = [rightX yTop-60 150 22];
            obj.B1CorrectionDropdown.Position = [rightX + 155 yTop-60 165 22];
            obj.LoadB1MapButton.Position = [rightX yTop-90 150 24];
            obj.B1MapInfoLabel.Position = [rightX + 155 yTop-92 max(140, tabW - (rightX + 155) - margin) 22];
            obj.OpenReconImagesButton.Position = [rightX yTop-120 180 30];


            obj.LambdaLabel.Position = [margin y 130 22];
            obj.LambdaEdit.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            isLLR = strcmp(obj.RegModeDropdown.Value, 'Locally-low rank');
            if isLLR
                obj.BlockSizeLabel.Position = [margin y 130 22];
                obj.BlockSizeEdit.Position = [margin + 140 y fieldW 22];
                y = y - rowGap - 22;

                obj.StrideLabel.Position = [margin y 130 22];
                obj.StrideEdit.Position = [margin + 140 y fieldW 22];
                y = y - rowGap - 22;
            end

            obj.OuterIterationsLabel.Position = [margin y 130 22];
            obj.OuterIterationsEdit.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.InnerIterationsLabel.Position = [margin y 130 22];
            obj.InnerIterationsEdit.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.RhoLabel.Position = [margin y 130 22];
            obj.RhoEdit.Position = [margin + 140 y fieldW 22];
            y = y - rowGap - 22;

            obj.EstimateMaskCheckbox.Position = [margin y 180 22];

            y = y - rowGap - 24;
            obj.DataInfoLabel.Position = [margin y 180 22];

            infoH = max(80, min(180, y - 70));
            obj.DataInfoTextArea.Position = [margin y - infoH - 4 max(320, tabW - 2*margin) infoH];

            obj.DictionaryInfoLabel.Position = [margin y - infoH - 30 max(320, tabW - 2*margin) 22];
        end

        function updateRegularizationModeUI(obj)
            isIterativeMRF = strcmp(obj.ReconTargetDropdown.Value, 'MRF') && strcmp(obj.MRFReconModeDropdown.Value, 'Iterative');
            isLLR = strcmp(obj.RegModeDropdown.Value, 'Locally-low rank') && isIterativeMRF;

            vis = 'off';
            if isLLR
                vis = 'on';
            end

            obj.BlockSizeLabel.Visible = vis;
            obj.BlockSizeEdit.Visible = vis;
            obj.StrideLabel.Visible = vis;
            obj.StrideEdit.Visible = vis;

            obj.resizeUI([]);
        end

        function updateReconTargetUI(obj)
            isMRF = strcmp(obj.ReconTargetDropdown.Value, 'MRF');

            if isMRF
                obj.LoadDictionaryButton.Visible = 'on';
                obj.MRFReconModeLabel.Visible = 'on';
                obj.MRFReconModeDropdown.Visible = 'on';
                obj.B1CorrectionLabel.Visible = 'on';
                obj.B1CorrectionDropdown.Visible = 'on';
            else
                obj.LoadDictionaryButton.Visible = 'off';
                obj.MRFReconModeLabel.Visible = 'off';
                obj.MRFReconModeDropdown.Visible = 'off';
                obj.B1CorrectionLabel.Visible = 'off';
                obj.B1CorrectionDropdown.Visible = 'off';
                obj.LoadB1MapButton.Visible = 'off';
                obj.B1MapInfoLabel.Visible = 'off';
            end

            obj.updateMRFReconModeUI();
            obj.updateB1CorrectionUI();
            obj.resizeUI([]);
        end

        function updateMRFReconModeUI(obj)
            isIterativeMRF = strcmp(obj.ReconTargetDropdown.Value, 'MRF') && strcmp(obj.MRFReconModeDropdown.Value, 'Iterative');

            vis = 'off';
            if isIterativeMRF
                vis = 'on';
            end

            obj.RegModeLabel.Visible = vis;
            obj.RegModeDropdown.Visible = vis;
            obj.LambdaLabel.Visible = vis;
            obj.LambdaEdit.Visible = vis;
            obj.OuterIterationsLabel.Visible = vis;
            obj.OuterIterationsEdit.Visible = vis;
            obj.InnerIterationsLabel.Visible = vis;
            obj.InnerIterationsEdit.Visible = vis;
            obj.RhoLabel.Visible = vis;
            obj.RhoEdit.Visible = vis;

            obj.updateRegularizationModeUI();

            obj.resizeUI([]);
        end

        function updateB1CorrectionUI(obj)
            isMRF = strcmp(obj.ReconTargetDropdown.Value, 'MRF');
            useProvidedB1Map = strcmp(obj.B1CorrectionDropdown.Value, 'Use B1 map');

            vis = 'off';
            if isMRF && useProvidedB1Map
                vis = 'on';
            end

            obj.LoadB1MapButton.Visible = vis;
            obj.B1MapInfoLabel.Visible = vis;

            obj.resizeUI([]);
        end

        function loadB1Map(obj)
            [file, folder] = uigetfile({'*.mat;*.nii;*.nii.gz', 'B1 map files (*.mat, *.nii, *.nii.gz)'}, ...
                'Select B1 map file');
            if isequal(file, 0)
                return;
            end

            fullPath = fullfile(folder, file);
            try
                [dims, nDims, ~, sourceText] = obj.getDataDimensions(fullPath);
            catch ME
                obj.showAlert(['Could not read B1 map file: ' ME.message], ...
                    'B1 Map Load Error', 'error');
                return;
            end

            dimsText = strjoin(arrayfun(@num2str, dims, 'UniformOutput', false), ' x ');
            obj.B1MapInfoLabel.Text = ['B1 map: ', file, ' (', num2str(nDims), 'D, ', dimsText, ', ', sourceText, ')'];

            obj.Parent.LastLoadDir = folder;
            obj.ReconSettings.B1MapPath = fullPath;

            disp(['Loaded B1 map file: ', fullPath]);
        end

        function B1Map = loadB1MapData(~, filePath)
            [~,~,ext] = fileparts(filePath);

            switch lower(ext)
                case '.mat'
                    S = load(filePath);
                    names = fieldnames(S);
                    if isempty(names)
                        error('MAT file is empty.');
                    end

                    idx = find(structfun(@isnumeric, S), 1, 'first');
                    if isempty(idx)
                        error('MAT file contains no numeric variable for B1 map.');
                    end

                    B1Map = double(S.(names{idx}));

                case {'.nii', '.gz'}
                    info = niftiinfo(filePath);
                    B1Map = double(niftiread(info));

                otherwise
                    error('Unsupported B1 map format. Use MAT or NIfTI.');
            end

            if isempty(B1Map)
                error('Loaded B1 map is empty.');
            end
        end

        function showAlert(obj, messageText, dialogTitle, iconType)
            parentFig = obj.resolveDialogParent();
            if ~isempty(parentFig)
                uialert(parentFig, messageText, dialogTitle, 'Icon', iconType);
            else
                errordlg(messageText, dialogTitle);
            end
        end

        function parentFig = resolveDialogParent(obj)
            parentFig = [];

            if ~isempty(obj.TabHandle) && isvalid(obj.TabHandle)
                try
                    parentFig = ancestor(obj.TabHandle, 'figure');
                catch
                    parentFig = [];
                end
            end

            if isempty(parentFig) && ~isempty(obj.Parent) && isvalid(obj.Parent)
                try
                    parentFig = ancestor(obj.Parent, 'figure');
                catch
                    parentFig = [];
                end
            end

            if isempty(parentFig) || ~isvalid(parentFig)
                parentFig = [];
            end
        end


        function dimensionality = inferDimensionalityFromNDim(~, ndimValue)
            dimensionality = '2D';
            if isempty(ndimValue)
                return;
            end

            if isnumeric(ndimValue)
                n = double(ndimValue(1));
            else
                n = str2double(char(string(ndimValue)));
            end

            if ~isnan(n) && n >= 3
                dimensionality = '3D';
            end
        end

        
    end
end
