classdef DictionaryTab < handle
    % DictionaryTab - Handles the Dictionary tab UI and functionality.
    %   Manages dictionary search parameters (T1, T2, B1), sequence timing
    %   (TR, TE), an optional inversion pulse, flip angle pattern
    %   construction (sine lobe / sawtooth), and dictionary generation.

    % ------------------------------------------------------------------ %
    properties
        Parent      % Reference to main MRFViewer instance
        TabHandle   % Handle to the uitab container

        % --- Panels ---
        DictParamPanel      % T1 / T2 / B1
        SeqTimingPanel      % TR / TE / Load Methods
        InversionPanel      % Inversion pulse options
        PrepListPanel       % Prep list load and preview

        % --- Dictionary parameter controls ---
        T1Edit
        T2Edit
        B1Edit
        
        %--- RF power parameters ---
        RefPow


        % --- Sequence timing controls ---
        TREdit
        TEEdit
        SimTimeStepEdit
        SpoilerAmpEdit
        SpoilerFlatTopEdit
        SpoilerRiseTimeEdit
        SliceThicknessEdit
        NIsochromatsEdit
        LoadMethodsButton

        % --- Inversion pulse controls ---
        RasterTimeLabel
        RasterTimeEdit
        InstantInversionCheckbox
        ParallelSimulationCheckbox

        % --- Bottom-area buttons ---
        GenerateDictButton
        SaveDictButton
        LoadPrepListButton
        PrepListSummaryLabel
        PrepListTable

        % --- Visualisation ---
        FAAxes

        % --- Data ---
        FlipAngles  % Combined FA pattern (numeric row vector)
        LoadedMethodParams = struct()
        LoadedMethodPath = ''
        PrepListMatrix = []
        PrepListNames = {}
        PrepListDeclaredCount = NaN
        GeneratedDictionary = []
        GeneratedLUT = []
        GeneratedDictionaryParams = struct()

        %---Dictionary Controller ---
        DictionaryGenerationController

        % --- Responsive layout listener ---
        FigureResizeListener
    end

    % ------------------------------------------------------------------ %
    methods

        function obj = DictionaryTab(parentMRFViewer, parentTab)
            % Constructor.
            obj.Parent    = parentMRFViewer;
            obj.TabHandle = parentTab;
            obj.FlipAngles = [];
            obj.createUI();
        end

        % -------------------------------------------------------------- %
        function createUI(obj)
            % Build all UI elements for the Dictionary tab.
            %
            % Left column  (x =  10 – 390): parameter panels + FA builder
            % Right column (x = 400 – 960): live flip angle axes

            TAB = obj.TabHandle;

            % ============================================================
            % SECTION 1 – Dictionary Parameters panel (top of left column)
            % ============================================================
            obj.DictParamPanel = uipanel(TAB, ...
                'Title', 'Dictionary Parameters', ...
                'FontWeight', 'bold', ...
                'Position', [10 485 370 115]);
            P = obj.DictParamPanel;

            uilabel(P, 'Text', 'T1 values (ms)', ...
                'Position', [10 68 115 22], 'FontWeight', 'bold');
            obj.T1Edit = uieditfield(P, 'text', ...
                'Value', '100:50:3000', ...
                'Position', [130 68 220 22], ...
                'Tooltip', 'MATLAB range or vector, e.g. 100:50:2000');

            uilabel(P, 'Text', 'T2 values (ms)', ...
                'Position', [10 46 115 22], 'FontWeight', 'bold');
            obj.T2Edit = uieditfield(P, 'text', ...
                'Value', '10:5:500', ...
                'Position', [130 46 220 22], ...
                'Tooltip', 'MATLAB range or vector, e.g. 10:5:300');

            uilabel(P, 'Text', 'B1 values', ...
                'Position', [10 24 70 22], 'FontWeight', 'bold');
            obj.B1Edit = uieditfield(P, 'text', ...
                'Value', '1', ...
                'Position', [80 24 85 22], ...
                'Tooltip', 'MATLAB range or vector, e.g. 0.8:0.05:1.2');

            obj.RasterTimeLabel = uilabel(P, ...
                'Text', 'Raster Time (µs)', ...
                'Position', [180 46 100 22], ...
                'FontWeight', 'bold', ...
                'Enable', 'on');
            obj.RasterTimeEdit = uieditfield(P, 'numeric', ...
                'Value', 10, ...
                'Limits', [0 Inf], ...
                'Position', [285 46 65 22], ...
                'Enable', 'on', ...
                'Tooltip', 'Editable simulation raster time in µs');

            uilabel(P, 'Text', 'Slice thickness (mm)', ...
                'Position', [180 24 100 22], 'FontWeight', 'bold');
            obj.SliceThicknessEdit = uieditfield(P, 'numeric', ...
                'Value', 2, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [285 24 65 22], ...
                'Tooltip', 'Loaded from Bruker method file');

            uilabel(P, 'Text', 'N isochromats', ...
                'Position', [10 2 115 22], 'FontWeight', 'bold');
            obj.NIsochromatsEdit = uieditfield(P, 'numeric', ...
                'Value', 200, ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', true, ...
                'Enable', 'on', ...
                'Position', [130 2 220 22], ...
                'Tooltip', 'User-editable isochromat count used in Bloch simulation');

            % ============================================================
            % SECTION 2 – Sequence Timing panel
            % ============================================================
            obj.SeqTimingPanel = uipanel(TAB, ...
                'Title', 'Sequence Timing (Loaded from Method)', ...
                'FontWeight', 'bold', ...
                'Position', [10 363 370 120]);
            P = obj.SeqTimingPanel;

            obj.LoadMethodsButton = uibutton(P, ...
                'Text', 'Select Bruker Method File', ...
                'Position', [10 88 350 24], ...
                'Tooltip', 'Load all sequence parameters from Bruker method file', ...
                'ButtonPushedFcn', @(~,~) obj.loadMethodsFile());

            uilabel(P, 'Text', 'TR (ms)', ...
                'Position', [10 56 50 22], 'FontWeight', 'bold');
            obj.TREdit = uieditfield(P, 'numeric', ...
                'Value', 10, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [65 56 90 22], ...
                'Tooltip', 'Loaded from Bruker method file');

            uilabel(P, 'Text', 'TE (ms)', ...
                'Position', [190 56 50 22], 'FontWeight', 'bold');
            obj.TEEdit = uieditfield(P, 'numeric', ...
                'Value', 2, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [245 56 105 22], ...
                'Tooltip', 'Loaded from Bruker method file');

            uilabel(P, 'Text', 'Step (µs)', ...
                'Position', [10 30 80 22], 'FontWeight', 'bold');
            obj.SimTimeStepEdit = uieditfield(P, 'numeric', ...
                'Value', 10, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [90 30 65 22], ...
                'Tooltip', 'Mirrors raster time (editable in dictionary parameters)');

            uilabel(P, 'Text', 'Amp (mT)', ...
                'Position', [190 30 70 22], 'FontWeight', 'bold');
            obj.SpoilerAmpEdit = uieditfield(P, 'numeric', ...
                'Value', 20, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [265 30 85 22], ...
                'Tooltip', 'Loaded from Bruker method file');

            uilabel(P, 'Text', 'Flat top (ms)', ...
                'Position', [10 4 85 22], 'FontWeight', 'bold');
            obj.SpoilerFlatTopEdit = uieditfield(P, 'numeric', ...
                'Value', 2, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [98 4 57 22], ...
                'Tooltip', 'Loaded from Bruker method file');

            uilabel(P, 'Text', 'Rise (ms)', ...
                'Position', [190 4 70 22], 'FontWeight', 'bold');
            obj.SpoilerRiseTimeEdit = uieditfield(P, 'numeric', ...
                'Value', 0.2, ...
                'Limits', [0 Inf], ...
                'Enable', 'off', ...
                'Position', [265 4 85 22], ...
                'Tooltip', 'Loaded from Bruker method file');

            % ============================================================
            % SECTION 3 – Inversion Pulse panel
            % ============================================================
            obj.InversionPanel = uipanel(TAB, ...
                'Title', 'Inversion', ...
                'FontWeight', 'bold', ...
                'Position', [10 228 370 131]);
            P = obj.InversionPanel;

            obj.InstantInversionCheckbox = uicheckbox(P, ...
                'Text', 'Instant inversion', ...
                'Value', true, ...
                'Position', [10 88 220 24], ...
                'Tooltip', 'If checked, use ideal instant inversion model');

            obj.ParallelSimulationCheckbox = uicheckbox(P, ...
                'Text', 'Use parallel simulation', ...
                'Value', true, ...
                'Position', [10 62 220 24], ...
                'Tooltip', 'If enabled, uses parfor with automatic fallback to serial mode on failure');

            obj.GenerateDictButton = uibutton(TAB, ...
                'Text', 'Generate Dictionary', ...
                'Position', [10 57 370 36], ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) obj.generateDictionary());

            obj.SaveDictButton = uibutton(TAB, ...
                'Text', 'Save Dict/LUT (.mat)', ...
                'Position', [10 15 370 36], ...
                'Enable', 'off', ...
                'Tooltip', 'Save the latest generated dictionary and LUT to a MAT file', ...
                'ButtonPushedFcn', @(~,~) obj.saveGeneratedDictionary());

            % ============================================================
            % SECTION 6 – Preparation list panel (right-hand column, top)
            % ============================================================
            obj.PrepListPanel = uipanel(TAB, ...
                'Title', 'Preparation Modules', ...
                'FontWeight', 'bold', ...
                'Position', [400 430 540 240]);

            obj.LoadPrepListButton = uibutton(obj.PrepListPanel, ...
                'Text', 'Load Prep List', ...
                'Position', [10 200 140 26], ...
                'Tooltip', 'Load preparation module list from text file', ...
                'ButtonPushedFcn', @(~,~) obj.loadPrepListFile());

            obj.PrepListSummaryLabel = uilabel(obj.PrepListPanel, ...
                'Text', 'No prep list loaded', ...
                'Position', [160 200 360 26], ...
                'HorizontalAlignment', 'left');

            obj.PrepListTable = uitable(obj.PrepListPanel, ...
                'Data', cell(0,4), ...
                'ColumnName', {'#','Module','Prep Time (ms)','Wait Time (ms)'}, ...
                'ColumnEditable', [false false false false], ...
                'ColumnWidth', {45 130 130 130}, ...
                'RowName', {}, ...
                'Position', [10 10 520 185]);

            % ============================================================
            % SECTION 7 – Flip angle axes (right-hand column, bottom)
            % ============================================================
            obj.FAAxes = uiaxes(TAB, 'Position', [400 20 540 400]);
            title(obj.FAAxes,  'Flip Angle Pattern');
            xlabel(obj.FAAxes, 'Frame Number');
            ylabel(obj.FAAxes, 'Flip Angle (deg)');
            grid(obj.FAAxes, 'on');

            if isprop(TAB, 'SizeChangedFcn')
                TAB.SizeChangedFcn = @(~,~) obj.updateResponsiveLayout();
            end

            fig = ancestor(TAB, 'figure');
            if ~isempty(fig)
                try
                    obj.FigureResizeListener = addlistener(fig, 'SizeChanged', ...
                        @(~,~) obj.updateResponsiveLayout());
                catch
                end
            end

            obj.refreshFAPlot();
            obj.updateResponsiveLayout();

        end

        % -------------------------------------------------------------- %
        function loadMethodsFile(obj)
            % Load all non-search-space parameters from a Bruker method file.

            [fileName, folderPath] = uigetfile({'*','Bruker method file (usually named method)'}, ...
                'Select Bruker method file');
            if isequal(fileName, 0)
                return;
            end

            selectedPath = fullfile(folderPath, fileName);
            scanDir = folderPath;

            try
                params = LoadBrukerData(scanDir, false);
            catch ME
                obj.safeAlert(['Unable to parse Bruker method file: ' ME.message], ...
                    'Method Load Error', 'error');
                return;
            end

            obj.LoadedMethodParams = params;
            obj.LoadedMethodPath = selectedPath;

            if isfield(params, 'TR')
                obj.TREdit.Value = params.TR * 1000;
            end
            if isfield(params, 'TE')
                obj.TEEdit.Value = params.TE * 1000;
            end

            if isfield(params, 'RiseTime')
                riseMs = params.RiseTime * 1000;
                obj.SpoilerRiseTimeEdit.Value = riseMs;
            else
                riseMs = obj.SpoilerRiseTimeEdit.Value;
            end

            if isfield(params, 'MRFSpoiler')
                if isfield(params.MRFSpoiler, 'duration')
                    obj.SpoilerFlatTopEdit.Value = max(0, params.MRFSpoiler.duration - 2 * riseMs);
                end
                if isfield(params.MRFSpoiler, 'amplitude')
                    obj.SpoilerAmpEdit.Value = obj.convertBrukerGradientToMT(params.MRFSpoiler.amplitude, params);
                end
            end

            if isfield(params, 'Thickness')
                obj.SliceThicknessEdit.Value = params.Thickness * 1000;
            end

            if isfield(params, 'RefPow')
                obj.RefPow = params.RefPow;
            end

            if isfield(params, 'MRFInversionPulse')
                obj.InstantInversionCheckbox.Value = false;
            else
                obj.InstantInversionCheckbox.Value = true;
            end

            if isfield(params, 'MRFFA') && ~isempty(params.MRFFA)
                obj.FlipAngles = params.MRFFA(:).';
                obj.refreshFAPlot();
            end

            obj.SimTimeStepEdit.Value = obj.RasterTimeEdit.Value;

            [~, loadedName, loadedExt] = fileparts(selectedPath);
            obj.LoadMethodsButton.Text = ['Loaded: ' loadedName loadedExt];
        end

        % -------------------------------------------------------------- %
        function generateDictionary(obj)
            % Validate inputs and generate dictionary using loaded method params
            % plus T1/T2/B1/raster-time overrides.

            if isempty(fieldnames(obj.LoadedMethodParams))
                obj.safeAlert('Load a Bruker method file first. Sequence parameters are now method-driven.', ...
                    'Method File Required', 'warning');
                return;
            end

            if isempty(obj.PrepListMatrix)
                obj.safeAlert('Load a prep list file before generating the dictionary.', ...
                    'Prep List Required', 'warning');
                return;
            end

            % --- Parse search-space ranges ---
            try
                T1 = obj.parseRangeString(obj.T1Edit.Value);
                T2 = obj.parseRangeString(obj.T2Edit.Value);
                B1 = obj.parseRangeString(obj.B1Edit.Value);
            catch ME
                obj.safeAlert(ME.message, 'Parameter Error', 'warning');
                return;
            end

            % --- Start from loaded Bruker method parameters ---
            params = obj.LoadedMethodParams;

            % --- User-overridable fields ---
            rasterTime = obj.RasterTimeEdit.Value;
            params.T1 = T1;
            params.T2 = T2;
            params.B1 = B1;
            params.dt = rasterTime * 1e-6;
            params.RasterTime = rasterTime * 1e-6;

            % --- Method-derived sequence settings ---
            params.TR = obj.TREdit.Value / 1000;
            params.TE = obj.TEEdit.Value / 1000;
            params.SliceThickness_mm = obj.SliceThicknessEdit.Value;
            params.NIsochromats = round(obj.NIsochromatsEdit.Value);
            obj.NIsochromatsEdit.Value = params.NIsochromats;
            params.RefPow = obj.RefPow;
            params.InstantInversion = obj.InstantInversionCheckbox.Value;
            params.UseParallel = obj.ParallelSimulationCheckbox.Value;
            params.PrepList = obj.PrepListMatrix;

            if ~isfield(params, 'MRFSpoiler')
                params.MRFSpoiler = struct();
            end
            params.MRFSpoiler.amplitude = obj.SpoilerAmpEdit.Value;
            params.MRFSpoiler.duration = obj.SpoilerFlatTopEdit.Value + 2 * obj.SpoilerRiseTimeEdit.Value;
            params.RiseTime = obj.SpoilerRiseTimeEdit.Value / 1000;

            % Prefer FA from flip-angle generation tab; fall back to method file.
            fa = obj.resolveFlipAngles();
            if isempty(fa)
                obj.safeAlert('No flip-angle pattern available. Generate/load FA first or ensure MRFFA exists in method file.', ...
                    'Flip Angles Missing', 'warning');
                return;
            end
            obj.FlipAngles = fa;
            params.FA = fa;

            useInstantInversion = obj.InstantInversionCheckbox.Value;
            spoilerAmp_mT = obj.SpoilerAmpEdit.Value;
            spoilerFlatTop_ms = obj.SpoilerFlatTopEdit.Value;
            spoilerRise_ms = obj.SpoilerRiseTimeEdit.Value;
            TR = params.TR * 1000;
            TE = params.TE * 1000;
            simTimeStep_us = rasterTime;
            sliceThickness_mm = params.SliceThickness_mm;
            nIsochromats = params.NIsochromats;

            fprintf(['Generating dictionary:\n' ...
                '  T1: %d values  T2: %d values  B1: %d values\n' ...
                '  TR: %.2f ms  TE: %.2f ms\n' ...
                '  Step: %.2f µs  Slice: %.2f mm  N Iso: %d\n' ...
                '  Spoiler: Amp=%.3f mT  Flat=%.3f ms  Rise=%.3f ms\n' ...
                '  FA frames: %d\n' ...
                '  Instant inversion: %s'], ...
                numel(T1), numel(T2), numel(B1), TR, TE, ...
                simTimeStep_us, sliceThickness_mm, nIsochromats, ...
                spoilerAmp_mT, spoilerFlatTop_ms, spoilerRise_ms, ...
                numel(fa), ...
                obj.tf2onoff(useInstantInversion));

            obj.GeneratedDictionary = [];
            obj.GeneratedLUT = [];
            obj.GeneratedDictionaryParams = struct();
            if ~isempty(obj.SaveDictButton) && isvalid(obj.SaveDictButton)
                obj.SaveDictButton.Enable = 'off';
            end

            obj.ensureToolboxOnPath();

            fig = [];
            if ~isempty(obj.Parent) && isprop(obj.Parent, 'Fig') ...
                    && ~isempty(obj.Parent.Fig) && isvalid(obj.Parent.Fig)
                fig = obj.Parent.Fig;
            elseif ~isempty(obj.TabHandle) && isvalid(obj.TabHandle)
                fig = ancestor(obj.TabHandle, 'figure');
            end

            dlg = [];
            if ~isempty(fig) && isvalid(fig)
                try
                    dlg = uiprogressdlg(fig, ...
                        'Title', 'Generating Dictionary', ...
                        'Message', 'Running Bloch simulation. Please wait...', ...
                        'Indeterminate', 'off', ...
                        'Value', 0, ...
                        'Cancelable', 'off');
                catch
                end
            end

            originalButtonText = '';
            if ~isempty(obj.GenerateDictButton) && isvalid(obj.GenerateDictButton)
                originalButtonText = obj.GenerateDictButton.Text;
                obj.GenerateDictButton.Enable = 'off';
                obj.GenerateDictButton.Text = 'Generating...';
            end
            drawnow;

            cleanupObj = onCleanup(@() obj.cleanupDictionaryGenerationUI(dlg, originalButtonText)); %#ok<NASGU>

            try
                %dictionary = DictionaryGeneration(params);
                %dictionary.RunSimulation;
                params.ProgressFcn = @(progress) obj.updateDictionaryGenerationProgress(dlg, progress);
                [dict, LUT] = SimulateFISPMRF(params, obj.PrepListMatrix, T1, T2, B1, simTimeStep_us, nIsochromats, useInstantInversion, params.ProgressFcn);
            catch ME
                obj.safeAlert(['Dictionary generation failed: ' ME.message], ...
                    'Simulation Error', 'error');
                return;
            end

            obj.GeneratedDictionary = dict;
            obj.GeneratedLUT = LUT;
            obj.GeneratedDictionaryParams = params;
            if ~isempty(obj.SaveDictButton) && isvalid(obj.SaveDictButton)
                obj.SaveDictButton.Enable = 'on';
            end

            obj.safeAlert('Dictionary generation finished.', ...
                'Simulation Complete', 'success');

        end

    end % public methods

    % ------------------------------------------------------------------ %
    methods (Access = private)

        function updateResponsiveLayout(obj)
            % Reflow panel and axes positions based on current tab size.
            if isempty(obj.TabHandle) || ~isvalid(obj.TabHandle)
                return;
            end

            tabPos = obj.TabHandle.Position;
            tabW = max(tabPos(3), 420);
            tabH = max(tabPos(4), 360);

            margin = 10;
            colGap = 10;
            rowGap = 6;

            % Give controls more room while preserving a usable right column.
            minAxesW = 170;
            leftW = max(340, min(520, round(0.42 * tabW)));
            if tabW < (leftW + minAxesW + 3*margin)
                leftW = max(220, tabW - minAxesW - 3*margin);
            end

            rightX = margin + leftW + colGap;
            rightW = max(120, tabW - rightX - margin);

            % Bottom controls block
            genH = 36;
            ySave = 15;
            yGen = ySave + genH + rowGap;
            stackBottom = yGen + genH + rowGap;
            stackTop = tabH - margin;

            available = max(140, stackTop - stackBottom - 2*rowGap);
            if leftW < 430
                % Reserve extra height for single-column Sequence Timing mode.
                weights = [0.28 0.40 0.32];  % Dict / Seq / Inv
                minH = [132 176 150];
            else
                weights = [0.30 0.34 0.36];  % Dict / Seq / Inv
                minH = [118 120 146];
            end

            h = round(available * weights);
            h = max(h, minH);

            totalH = sum(h);
            if totalH > available
                excess = totalH - available;
                order = [3 2 1];
                for k = order
                    reducible = h(k) - minH(k);
                    if reducible <= 0
                        continue;
                    end
                    take = min(reducible, excess);
                    h(k) = h(k) - take;
                    excess = excess - take;
                    if excess == 0
                        break;
                    end
                end
            end

            % Place stacked left-column panels from top to bottom
            y = stackTop;
            y = y - h(1);
            obj.DictParamPanel.Position = [margin y leftW h(1)];

            y = y - rowGap - h(2);
            obj.SeqTimingPanel.Position = [margin y leftW h(2)];

            y = y - rowGap - h(3);
            obj.InversionPanel.Position = [margin y leftW h(3)];

            % Generate button
            obj.GenerateDictButton.Position = [margin yGen leftW genH];
            obj.SaveDictButton.Position = [margin ySave leftW genH];

            % Right-side area split: prep list panel (top) and FA plot (bottom)
            rightGap = 8;
            rightAvailH = max(100, tabH - 2*margin - rightGap);
            minAxesH = 95;
            prepPanelH = min(260, max(120, round(0.38 * rightAvailH)));
            if prepPanelH + minAxesH > rightAvailH
                prepPanelH = max(90, rightAvailH - minAxesH);
            end
            axesH = max(80, rightAvailH - prepPanelH);
            prepPanelY = margin + axesH + rightGap;

            obj.PrepListPanel.Position = [rightX prepPanelY rightW prepPanelH];
            obj.FAAxes.Position = [rightX margin rightW axesH];

            % Internal per-panel control layouts (fully dynamic)
            obj.layoutDictParamPanelControls();
            obj.layoutSeqTimingPanelControls();
            obj.layoutInversionPanelControls();
            obj.layoutPrepListPanelControls();
        end

        function layoutDictParamPanelControls(obj)
            p = obj.DictParamPanel.Position;
            pw = p(3);
            ph = p(4);

            margin = 10;
            h = 22;
            rowGap = 2;
            titlePad = 24;

            y1 = ph - titlePad - h;
            y2 = y1 - (h + rowGap);
            y3 = y2 - (h + rowGap);
            y4 = y3 - (h + rowGap);

            useSingleCol = (pw < 430) && (ph >= 128);
            if useSingleCol
                lblW = 110;
                editX = margin + lblW + 8;
                editW = max(80, pw - editX - margin);

                obj.positionLabel(obj.DictParamPanel, 'T1 values (ms)', [margin y1 lblW h]);
                obj.T1Edit.Position = [editX y1 editW h];

                obj.positionLabel(obj.DictParamPanel, 'T2 values (ms)', [margin y2 lblW h]);
                obj.T2Edit.Position = [editX y2 editW h];

                obj.positionLabel(obj.DictParamPanel, 'B1 values', [margin y3 lblW h]);
                obj.B1Edit.Position = [editX y3 max(45, floor(editW*0.42)) h];

                rightX = editX + max(45, floor(editW*0.42)) + 6;
                rightW = max(45, pw - rightX - margin);
                obj.RasterTimeLabel.Position = [rightX y3 95 h];
                obj.RasterTimeEdit.Position = [rightX + 98 y3 max(45, rightW - 98) h];

                obj.positionLabel(obj.DictParamPanel, 'Slice thickness (mm)', [margin y4 lblW h]);
                obj.SliceThicknessEdit.Position = [editX y4 editW h];

                y5 = y4 - (h + rowGap);
                obj.positionLabel(obj.DictParamPanel, 'N isochromats', [margin y5 lblW h]);
                obj.NIsochromatsEdit.Position = [editX y5 editW h];
            else
                lblW = 110;
                editX = margin + lblW + 8;
                editW = max(80, pw - editX - margin);

                obj.positionLabel(obj.DictParamPanel, 'T1 values (ms)', [margin y1 lblW h]);
                obj.T1Edit.Position = [editX y1 editW h];

                obj.positionLabel(obj.DictParamPanel, 'T2 values (ms)', [margin y2 lblW h]);
                obj.T2Edit.Position = [editX y2 editW h];

                halfW = floor((pw - 2*margin - 10) / 2);
                leftX = margin;
                rightX = leftX + halfW + 10;

                obj.positionLabel(obj.DictParamPanel, 'B1 values', [leftX y3 70 h]);
                obj.B1Edit.Position = [leftX + 73 y3 max(45, halfW - 73) h];

                obj.positionLabel(obj.DictParamPanel, 'Slice thickness (mm)', [rightX y3 100 h]);
                obj.SliceThicknessEdit.Position = [rightX + 103 y3 max(45, halfW - 103) h];

                obj.RasterTimeLabel.Position = [leftX y4 95 h];
                obj.RasterTimeEdit.Position = [leftX + 98 y4 max(45, halfW - 98) h];

                obj.positionLabel(obj.DictParamPanel, 'N isochromats', [rightX y4 95 h]);
                obj.NIsochromatsEdit.Position = [rightX + 98 y4 max(45, halfW - 98) h];
            end
        end

        function layoutSeqTimingPanelControls(obj)
            p = obj.SeqTimingPanel.Position;
            pw = p(3);
            ph = p(4);

            margin = 10;
            h = 22;
            rowGap = 2;
            titlePad = 24;

            y1 = ph - titlePad - h;
            y2 = y1 - (h + rowGap);
            y3 = y2 - (h + rowGap);
            y4 = y3 - (h + rowGap);

            obj.LoadMethodsButton.Position = [margin y1 max(120, pw - 2*margin) h];

            useSingleCol = (pw < 430) && (ph >= 170);
            if useSingleCol
                y = y2;
                labelW = 88;
                fieldX = margin + labelW + 6;
                fieldW = max(60, pw - fieldX - margin);

                obj.positionLabel(obj.SeqTimingPanel, 'TR (ms)', [margin y labelW h]);
                obj.TREdit.Position = [fieldX y fieldW h];

                y = y - (h + rowGap);
                obj.positionLabel(obj.SeqTimingPanel, 'TE (ms)', [margin y labelW h]);
                obj.TEEdit.Position = [fieldX y fieldW h];

                y = y - (h + rowGap);
                obj.positionLabel(obj.SeqTimingPanel, 'Step (µs)', [margin y labelW h]);
                obj.SimTimeStepEdit.Position = [fieldX y fieldW h];

                y = y - (h + rowGap);
                obj.positionLabel(obj.SeqTimingPanel, 'Amp (mT)', [margin y labelW h]);
                obj.SpoilerAmpEdit.Position = [fieldX y fieldW h];

                y = y - (h + rowGap);
                obj.positionLabel(obj.SeqTimingPanel, 'Flat top (ms)', [margin y labelW h]);
                obj.SpoilerFlatTopEdit.Position = [fieldX y fieldW h];

                y = y - (h + rowGap);
                obj.positionLabel(obj.SeqTimingPanel, 'Rise (ms)', [margin y labelW h]);
                obj.SpoilerRiseTimeEdit.Position = [fieldX y fieldW h];
            else
                halfW = floor((pw - 2*margin - 10) / 2);
                leftX = margin;
                rightX = leftX + halfW + 10;

                obj.positionLabel(obj.SeqTimingPanel, 'TR (ms)', [leftX y2 50 h]);
                obj.TREdit.Position = [leftX + 53 y2 max(45, halfW - 53) h];

                obj.positionLabel(obj.SeqTimingPanel, 'TE (ms)', [rightX y2 50 h]);
                obj.TEEdit.Position = [rightX + 53 y2 max(45, halfW - 53) h];

                obj.positionLabel(obj.SeqTimingPanel, 'Step (µs)', [leftX y3 70 h]);
                obj.SimTimeStepEdit.Position = [leftX + 73 y3 max(45, halfW - 73) h];

                obj.positionLabel(obj.SeqTimingPanel, 'Amp (mT)', [rightX y3 65 h]);
                obj.SpoilerAmpEdit.Position = [rightX + 68 y3 max(45, halfW - 68) h];

                obj.positionLabel(obj.SeqTimingPanel, 'Flat top (ms)', [leftX y4 85 h]);
                obj.SpoilerFlatTopEdit.Position = [leftX + 88 y4 max(45, halfW - 88) h];

                obj.positionLabel(obj.SeqTimingPanel, 'Rise (ms)', [rightX y4 65 h]);
                obj.SpoilerRiseTimeEdit.Position = [rightX + 68 y4 max(45, halfW - 68) h];
            end
        end

        function layoutInversionPanelControls(obj)
            p = obj.InversionPanel.Position;
            pw = p(3);
            ph = p(4);

            margin = 10;
            h = 22;
            titlePad = 24;

            y1 = ph - titlePad - h;
            y2 = y1 - (h + 4);
            obj.InstantInversionCheckbox.Position = [margin y1 max(140, pw - 2*margin) h + 2];
            obj.ParallelSimulationCheckbox.Position = [margin y2 max(140, pw - 2*margin) h + 2];
        end

        function layoutPrepListPanelControls(obj)
            if isempty(obj.PrepListPanel) || ~isvalid(obj.PrepListPanel)
                return;
            end

            p = obj.PrepListPanel.Position;
            pw = p(3);
            ph = p(4);

            margin = 10;
            gap = 6;
            btnH = 26;
            labelH = 22;
            titlePad = 24;

            if ph < 180
                margin = 8;
                gap = 4;
                btnH = 24;
                labelH = 20;
                titlePad = 26;
            end

            innerW = max(80, pw - 2 * margin);
            isNarrow = pw < 500;

            topY = ph - titlePad;
            if isNarrow
                % Small-width mode: stack controls to avoid collisions.
                btnW = min(170, max(120, innerW));
                btnY = topY - btnH;
                obj.LoadPrepListButton.Position = [margin btnY btnW btnH];

                labelY = btnY - gap - labelH;
                obj.PrepListSummaryLabel.Position = [margin labelY innerW labelH];

                tableTop = labelY - gap;
            else
                btnW = min(160, max(130, floor(0.34 * innerW)));
                btnY = topY - btnH;
                obj.LoadPrepListButton.Position = [margin btnY btnW btnH];

                labelX = margin + btnW + 10;
                labelW = max(80, pw - labelX - margin);
                obj.PrepListSummaryLabel.Position = [labelX btnY labelW labelH];

                tableTop = btnY - gap;
            end

            tableY = margin;
            tableW = max(120, innerW);
            tableH = max(60, tableTop - tableY);
            obj.PrepListTable.Position = [margin tableY tableW tableH];
        end

        function loadPrepListFile(obj)
            [fileName, folderPath] = uigetfile({'*.txt;*.dat','Prep List Files (*.txt, *.dat)'}, ...
                'Select Preparation List File');
            if isequal(fileName, 0)
                return;
            end

            filePath = fullfile(folderPath, fileName);
            try
                [prepMatrix, prepNames, declaredCount] = obj.parsePrepListFile(filePath);
            catch ME
                obj.safeAlert(['Unable to parse prep list: ' ME.message], ...
                    'Prep List Error', 'error');
                return;
            end

            obj.PrepListMatrix = prepMatrix;
            obj.PrepListNames = prepNames;
            obj.PrepListDeclaredCount = declaredCount;

            nRows = size(prepMatrix, 1);
            tableData = cell(nRows, 4);
            for ii = 1:nRows
                tableData{ii,1} = ii;
                tableData{ii,2} = prepNames{ii};
                tableData{ii,3} = prepMatrix(ii,2);
                tableData{ii,4} = prepMatrix(ii,3);
            end
            obj.PrepListTable.Data = tableData;

            if isnan(declaredCount)
                obj.PrepListSummaryLabel.Text = sprintf('%d prep module(s) loaded', nRows);
            else
                obj.PrepListSummaryLabel.Text = sprintf('%d loaded (header: %d)', nRows, declaredCount);
            end
        end

        function [prepMatrix, prepNames, declaredCount] = parsePrepListFile(obj, filePath)
            txt = fileread(filePath);
            rawLines = splitlines(txt);

            lines = {};
            for i = 1:numel(rawLines)
                ln = strtrim(rawLines{i});
                if isempty(ln)
                    continue;
                end
                lines{end+1} = ln; %#ok<AGROW>
            end

            if isempty(lines)
                error('Prep list file is empty.');
            end

            declaredCount = NaN;
            lineStart = 1;
            if startsWith(lines{1}, '#')
                declaredCount = str2double(extractAfter(lines{1}, '#'));
                lineStart = 2;
            end

            prepMatrix = zeros(0,3);
            prepNames = {};
            for i = lineStart:numel(lines)
                ln = lines{i};
                parts = strsplit(ln);
                if numel(parts) < 2
                    continue;
                end

                moduleToken = parts{1};
                prepTime = str2double(parts{2});
                if isnan(prepTime)
                    continue;
                end

                waitTime = 0;
                if numel(parts) >= 3
                    wt = str2double(parts{3});
                    if ~isnan(wt)
                        waitTime = wt;
                    end
                end

                moduleCode = str2double(moduleToken);
                if isnan(moduleCode)
                    moduleCode = obj.prepCodeFromName(moduleToken);
                    moduleName = moduleToken;
                else
                    moduleName = obj.prepNameFromCode(moduleCode);
                end

                prepMatrix(end+1,:) = [moduleCode, prepTime, waitTime]; %#ok<AGROW>
                prepNames{end+1} = moduleName; %#ok<AGROW>
            end

            if isempty(prepMatrix)
                error('No valid preparation rows found in file.');
            end
        end

        function code = prepCodeFromName(~, name)
            switch lower(strtrim(name))
                case {'t1prep','t1'}
                    code = 0;
                case {'t2prep','t2'}
                    code = 1;
                case {'bir4','bir'}
                    code = 2;
                otherwise
                    code = NaN;
            end
        end

        function name = prepNameFromCode(~, code)
            if isequal(code,0)
                name = 'T1Prep';
            elseif isequal(code,1)
                name = 'T2Prep';
            elseif isequal(code,2)
                name = 'BIR4';
            else
                name = sprintf('Code %.3g', code);
            end
        end

        function positionLabel(~, panel, labelText, pos)
            h = findobj(panel, 'Type', 'uilabel', 'Text', labelText);
            if ~isempty(h)
                h(1).Position = pos;
            end
        end

        function safeAlert(obj, messageText, titleText, iconName)
            if nargin < 4 || isempty(iconName)
                iconName = 'info';
            end

            fig = [];
            if ~isempty(obj.Parent) && isprop(obj.Parent, 'Fig') ...
                    && ~isempty(obj.Parent.Fig) && isvalid(obj.Parent.Fig)
                fig = obj.Parent.Fig;
            elseif ~isempty(obj.TabHandle) && isvalid(obj.TabHandle)
                fig = ancestor(obj.TabHandle, 'figure');
            end

            if isempty(fig) || ~isvalid(fig)
                warning('%s: %s', titleText, messageText);
                return;
            end

            uialert(fig, messageText, titleText, 'Icon', iconName);
        end

        function cleanupDictionaryGenerationUI(obj, dlg, originalButtonText)
            if ~isempty(dlg) && isvalid(dlg)
                close(dlg);
            end

            if ~isempty(obj.GenerateDictButton) && isvalid(obj.GenerateDictButton)
                obj.GenerateDictButton.Enable = 'on';
                if ~isempty(originalButtonText)
                    obj.GenerateDictButton.Text = originalButtonText;
                else
                    obj.GenerateDictButton.Text = 'Generate Dictionary';
                end
            end
        end

            function updateDictionaryGenerationProgress(obj, dlg, progress)
                if isempty(dlg) || ~isvalid(dlg) || ~isstruct(progress)
                    return;
                end

                if progress.Total <= 0
                    dlg.Value = 1;
                    dlg.Message = progress.Message;
                    drawnow limitrate;
                    return;
                end

                dlg.Value = max(0, min(1, progress.Percent));

                if isinf(progress.RemainingSec)
                    etaText = 'estimating...';
                else
                    etaText = obj.formatDuration(progress.RemainingSec);
                end

                elapsedText = obj.formatDuration(progress.ElapsedSec);
                dlg.Message = sprintf('%d/%d (%.1f%%) | elapsed %s | remaining %s', ...
                    progress.Completed, progress.Total, progress.Percent * 100, ...
                    elapsedText, etaText);
                drawnow limitrate;
            end

            function text = formatDuration(~, secondsValue)
                secondsValue = max(0, secondsValue);
                hoursValue = floor(secondsValue / 3600);
                minutesValue = floor(mod(secondsValue, 3600) / 60);
                secondsValue = round(mod(secondsValue, 60));

                if hoursValue > 0
                    text = sprintf('%dh %02dm %02ds', hoursValue, minutesValue, secondsValue);
                elseif minutesValue > 0
                    text = sprintf('%dm %02ds', minutesValue, secondsValue);
                else
                    text = sprintf('%ds', secondsValue);
                end
            end

        function ensureToolboxOnPath(~)
            thisFile = mfilename('fullpath');
            toolboxRoot = fileparts(fileparts(thisFile));
            if isfolder(toolboxRoot)
                addpath(genpath(toolboxRoot));
            end
        end

        function saveGeneratedDictionary(obj)
            if isempty(obj.GeneratedDictionary) || isempty(obj.GeneratedLUT)
                obj.safeAlert('Generate a dictionary first, then save it.', ...
                    'Nothing To Save', 'warning');
                return;
            end

            [fName, fPath] = uiputfile({'*.mat','MAT-file (*.mat)'}, ...
                'Save dictionary and LUT', ...
                'dictionary_lut.mat');
            if isequal(fName,0)
                return;
            end

            dict = obj.GeneratedDictionary;
            LUT = obj.GeneratedLUT;
            params = obj.GeneratedDictionaryParams;

            % Remove function handles and GUI references before saving to prevent
            % unwanted GUI instantiation when the file is loaded
            if isstruct(params) && isfield(params, 'ProgressFcn')
                params = rmfield(params, 'ProgressFcn');
            end

            try
                save(fullfile(fPath,fName), 'dict', 'LUT', 'params', '-v7.3');
            catch ME
                obj.safeAlert(['Failed to save MAT file: ' ME.message], ...
                    'Save Error', 'error');
                return;
            end

            obj.safeAlert('Dictionary and LUT saved successfully.', ...
                'Save Complete', 'success');
        end

        function ampMT = convertBrukerGradientToMT(~, ampRaw, params)
            % Convert Bruker gradient amplitudes to mT/m when possible.
            ampMT = ampRaw;
            if isfield(params, 'PVM_GradCalConst') && ~isempty(params.PVM_GradCalConst)
                gyro = 42.577e6; % Hz/T
                hzPerM = params.PVM_GradCalConst * (ampRaw / 100);
                ampMT = (hzPerM / gyro) * 1000;
            end
        end

        function fa = resolveFlipAngles(obj)
            fa = [];
            if ~isempty(obj.FlipAngles)
                fa = obj.FlipAngles(:).';
                return;
            end
            if ~isempty(fieldnames(obj.LoadedMethodParams)) ...
                    && isfield(obj.LoadedMethodParams, 'MRFFA') ...
                    && ~isempty(obj.LoadedMethodParams.MRFFA)
                fa = obj.LoadedMethodParams.MRFFA(:).';
            end
        end

        function refreshFAPlot(obj)
            ax = obj.FAAxes;
            if isempty(ax) || ~isvalid(ax)
                return;
            end

            fa = obj.resolveFlipAngles();
            cla(ax);

            if isempty(fa)
                title(ax, 'Flip Angle Pattern (none loaded)');
                xlabel(ax, 'Frame Number');
                ylabel(ax, 'Flip Angle (deg)');
                grid(ax, 'on');
                return;
            end

            plot(ax, 1:numel(fa), fa, 'b-', 'LineWidth', 1.2);
            title(ax, sprintf('Flip Angle Pattern (%d frames)', numel(fa)));
            xlabel(ax, 'Frame Number');
            ylabel(ax, 'Flip Angle (deg)');
            grid(ax, 'on');
            ylim(ax, [0 max(fa) * 1.15 + 1]);
        end

        % -------------------------------------------------------------- %
        function values = parseRangeString(~, str)
            % Evaluate a MATLAB-style range/vector string,
            % e.g. '100:50:3000' or '[100, 200, 500]'.
            try
                values = eval(['[' str ']']);
                validateattributes(values, {'numeric'}, ...
                    {'vector', 'real', 'positive', 'finite'});
            catch
                error('Invalid range specification: ''%s''', str);
            end
        end

        % -------------------------------------------------------------- %
        function s = tf2onoff(~, tf)
            % Convert a logical value to 'on' / 'off' string.
            if tf
                s = 'on';
            else
                s = 'off';
            end
        end

    end % private methods

end

