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
        FAGenPanel          % Flip angle lobe builder

        % --- Dictionary parameter controls ---
        T1Edit
        T2Edit
        B1Edit

        % --- Sequence timing controls ---
        TREdit
        TEEdit
        LoadMethodsButton

        % --- Inversion pulse controls ---
        InversionCheckbox
        InversionTypeDropdown
        RFDurationLabel
        RFDurationEdit
        RasterTimeLabel
        RasterTimeEdit

        % --- FA Generator controls ---
        MinFAEdit
        MaxFAEdit
        NPointsEdit
        ShapeDropdown
        AddLobeButton
        LobeListBox
        RemoveLobeButton

        % --- Bottom-area buttons ---
        LoadFAButton
        ExportFAButton
        GenerateDictButton

        % --- Visualisation ---
        FAAxes

        % --- Data ---
        FlipAngles  % Combined FA pattern (numeric row vector)
        Lobes       % struct array: MinFA, MaxFA, NPoints, Shape

        %---Dictionary Controller ---
        DictionaryGenerationController
    end

    % ------------------------------------------------------------------ %
    methods

        function obj = DictionaryTab(parentMRFViewer, parentTab)
            % Constructor.
            obj.Parent    = parentMRFViewer;
            obj.TabHandle = parentTab;
            obj.Lobes     = struct('MinFA', {}, 'MaxFA', {}, ...
                                   'NPoints', {}, 'Shape', {});
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
                'Position', [10 507 370 93]);
            P = obj.DictParamPanel;

            uilabel(P, 'Text', 'T1 values (ms)', ...
                'Position', [10 48 115 22], 'FontWeight', 'bold');
            obj.T1Edit = uieditfield(P, 'text', ...
                'Value', '100:50:3000', ...
                'Position', [130 48 220 22], ...
                'Tooltip', 'MATLAB range or vector, e.g. 100:50:2000');

            uilabel(P, 'Text', 'T2 values (ms)', ...
                'Position', [10 24 115 22], 'FontWeight', 'bold');
            obj.T2Edit = uieditfield(P, 'text', ...
                'Value', '10:5:500', ...
                'Position', [130 24 220 22], ...
                'Tooltip', 'MATLAB range or vector, e.g. 10:5:300');

            uilabel(P, 'Text', 'B1 values', ...
                'Position', [10 1 115 22], 'FontWeight', 'bold');
            obj.B1Edit = uieditfield(P, 'text', ...
                'Value', '1', ...
                'Position', [130 1 220 22], ...
                'Tooltip', 'MATLAB range or vector, e.g. 0.8:0.05:1.2');

            % ============================================================
            % SECTION 2 – Sequence Timing panel
            % ============================================================
            obj.SeqTimingPanel = uipanel(TAB, ...
                'Title', 'Sequence Timing', ...
                'FontWeight', 'bold', ...
                'Position', [10 404 370 100]);
            P = obj.SeqTimingPanel;

            obj.LoadMethodsButton = uibutton(P, ...
                'Text', 'Load from Bruker Methods File', ...
                'Position', [10 52 350 26], ...
                'Tooltip', 'Parse TR and TE from a Bruker method file', ...
                'ButtonPushedFcn', @(~,~) obj.loadMethodsFile());

            uilabel(P, 'Text', 'TR (ms)', ...
                'Position', [10 26 70 22], 'FontWeight', 'bold');
            obj.TREdit = uieditfield(P, 'numeric', ...
                'Value', 10, ...
                'Limits', [0 Inf], ...
                'Position', [85 26 100 22], ...
                'Tooltip', 'Repetition time in ms');

            uilabel(P, 'Text', 'TE (ms)', ...
                'Position', [200 26 70 22], 'FontWeight', 'bold');
            obj.TEEdit = uieditfield(P, 'numeric', ...
                'Value', 2, ...
                'Limits', [0 Inf], ...
                'Position', [275 26 75 22], ...
                'Tooltip', 'Echo time in ms');

            % ============================================================
            % SECTION 3 – Inversion Pulse panel
            % ============================================================
            obj.InversionPanel = uipanel(TAB, ...
                'Title', 'Inversion Pulse  (180°, not included in FA array)', ...
                'FontWeight', 'bold', ...
                'Position', [10 292 370 109]);
            P = obj.InversionPanel;

            obj.InversionCheckbox = uicheckbox(P, ...
                'Text', 'Include inversion pulse before acquisition', ...
                'Value', false, ...
                'Position', [10 65 350 22], ...
                'ValueChangedFcn', @(~,~) obj.onInversionToggled());

            uilabel(P, 'Text', 'Type', ...
                'Position', [10 39 40 22], 'FontWeight', 'bold');
            obj.InversionTypeDropdown = uidropdown(P, ...
                'Items', {'Instant', 'Hard Pulse'}, ...
                'Value', 'Instant', ...
                'Enable', 'off', ...
                'Position', [55 39 130 22], ...
                'Tooltip', 'Instant: ideal inversion; Hard Pulse: specify RF parameters', ...
                'ValueChangedFcn', @(~,~) obj.onInversionTypeChanged());

            obj.RFDurationLabel = uilabel(P, ...
                'Text', 'RF Duration (ms)', ...
                'Position', [10 13 115 22], ...
                'Enable', 'off');
            obj.RFDurationEdit = uieditfield(P, 'numeric', ...
                'Value', 0.5, ...
                'Limits', [0 Inf], ...
                'Position', [128 13 60 22], ...
                'Enable', 'off', ...
                'Tooltip', 'Duration of the inversion hard pulse in ms');

            obj.RasterTimeLabel = uilabel(P, ...
                'Text', 'Raster Time (µs)', ...
                'Position', [200 13 115 22], ...
                'Enable', 'off');
            obj.RasterTimeEdit = uieditfield(P, 'numeric', ...
                'Value', 10, ...
                'Limits', [0 Inf], ...
                'Position', [315 13 45 22], ...
                'Enable', 'off', ...
                'Tooltip', 'RF raster time in µs');

            % ============================================================
            % SECTION 4 – Flip Angle Pattern Generator panel
            % ============================================================
            obj.FAGenPanel = uipanel(TAB, ...
                'Title', 'Flip Angle Pattern Generator', ...
                'FontWeight', 'bold', ...
                'Position', [10 88 370 200]);
            P = obj.FAGenPanel;

            % Lobe parameters – two per row for compactness
            uilabel(P, 'Text', 'Min FA (deg)', 'Position', [10 152 90 22]);
            obj.MinFAEdit = uieditfield(P, 'numeric', ...
                'Value', 5, 'Limits', [0 90], ...
                'Position', [103 152 55 22], ...
                'Tooltip', 'Minimum flip angle in degrees');

            uilabel(P, 'Text', 'Max FA (deg)', 'Position', [170 152 90 22]);
            obj.MaxFAEdit = uieditfield(P, 'numeric', ...
                'Value', 60, 'Limits', [0 90], ...
                'Position', [263 152 55 22], ...
                'Tooltip', 'Maximum flip angle in degrees');

            uilabel(P, 'Text', 'N Points', 'Position', [10 125 70 22]);
            obj.NPointsEdit = uieditfield(P, 'numeric', ...
                'Value', 50, 'Limits', [2 10000], ...
                'RoundFractionalValues', true, ...
                'Position', [103 125 55 22], ...
                'Tooltip', 'Number of time points in this lobe');

            uilabel(P, 'Text', 'Shape', 'Position', [170 125 45 22]);
            obj.ShapeDropdown = uidropdown(P, ...
                'Items', {'Sine Lobe', 'Sawtooth'}, ...
                'Value', 'Sine Lobe', ...
                'Position', [220 125 98 22]);

            obj.AddLobeButton = uibutton(P, ...
                'Text', '+ Add Lobe', ...
                'Position', [10 96 350 26], ...
                'ButtonPushedFcn', @(~,~) obj.addLobe());

            uilabel(P, 'Text', 'Added Lobes', ...
                'Position', [10 72 120 22], 'FontWeight', 'bold');

            obj.LobeListBox = uilistbox(P, ...
                'Items', {}, ...
                'Position', [10 7 268 63], ...
                'Tooltip', 'Select a lobe then press Remove');

            obj.RemoveLobeButton = uibutton(P, ...
                'Text', sprintf('Remove\nSelected'), ...
                'Position', [285 7 75 58], ...
                'ButtonPushedFcn', @(~,~) obj.removeLobe());

            % ============================================================
            % SECTION 5 – Bottom action buttons
            % ============================================================
            obj.LoadFAButton = uibutton(TAB, ...
                'Text', 'Load FA File', ...
                'Position', [10 56 178 28], ...
                'Tooltip', 'Load a flip angle pattern from a .txt file', ...
                'ButtonPushedFcn', @(~,~) obj.loadFlipAngles());

            obj.ExportFAButton = uibutton(TAB, ...
                'Text', 'Export FA Pattern', ...
                'Position', [197 56 183 28], ...
                'Tooltip', 'Save current flip angle pattern to a .txt file', ...
                'ButtonPushedFcn', @(~,~) obj.exportFlipAngles());

            obj.GenerateDictButton = uibutton(TAB, ...
                'Text', 'Generate Dictionary', ...
                'Position', [10 15 370 36], ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) obj.generateDictionary());

            % ============================================================
            % SECTION 6 – Flip angle axes (right-hand column)
            % ============================================================
            obj.FAAxes = uiaxes(TAB, 'Position', [400 20 540 550]);
            title(obj.FAAxes,  'Flip Angle Pattern');
            xlabel(obj.FAAxes, 'Frame Number');
            ylabel(obj.FAAxes, 'Flip Angle (deg)');
            grid(obj.FAAxes, 'on');
        end

        % -------------------------------------------------------------- %
        % Inversion pulse callbacks
        % -------------------------------------------------------------- %
        function onInversionToggled(obj)
            % Enable / disable inversion type controls when checkbox changes.
            if obj.InversionCheckbox.Value
                obj.InversionTypeDropdown.Enable = 'on';
                obj.onInversionTypeChanged();   % apply current type state
            else
                obj.InversionTypeDropdown.Enable  = 'off';
                obj.RFDurationLabel.Enable   = 'off';
                obj.RFDurationEdit.Enable    = 'off';
                obj.RasterTimeLabel.Enable   = 'off';
                obj.RasterTimeEdit.Enable    = 'off';
            end
        end

        function onInversionTypeChanged(obj)
            % Enable RF Duration / Raster Time only for Hard Pulse mode.
            isHard = strcmp(obj.InversionTypeDropdown.Value, 'Hard Pulse') ...
                     && obj.InversionCheckbox.Value;
            state = obj.tf2onoff(isHard);
            obj.RFDurationLabel.Enable  = state;
            obj.RFDurationEdit.Enable   = state;
            obj.RasterTimeLabel.Enable  = state;
            obj.RasterTimeEdit.Enable   = state;
        end

        % -------------------------------------------------------------- %
        function loadMethodsFile(obj)
            % Load TR and TE from a Bruker method file.
            % TODO: implement Bruker method file parsing here.
            pth = uigetdir('Select Bruker Directory');
            %%if isequal(file, 0)
              %%  return;
            %%end
            % Example stub – replace with real parser:
            % params = parseBrukerMethod(fullfile(location, file));
            params = LoadBrukerData(pth,false);
            obj.TREdit.Value = params.TR;

            
            % obj.TREdit.Value = params.TR;
            % obj.TEEdit.Value = params.TE;
            % uialert(obj.TabHandle.Parent, ...
            %     sprintf('Selected: %s\nImplement parsing in loadMethodsFile().', ...
            %         pth, ...
            %     'Methods File', 'Icon', 'info');
        end

        % -------------------------------------------------------------- %
        function addLobe(obj)
            % Read lobe parameters and append to the Lobes list.
            minFA = obj.MinFAEdit.Value;
            maxFA = obj.MaxFAEdit.Value;
            nPts  = round(obj.NPointsEdit.Value);
            shape = obj.ShapeDropdown.Value;

            if minFA >= maxFA
                uialert(obj.TabHandle.Parent, ...
                    'Min FA must be less than Max FA.', 'Invalid Input');
                return;
            end

            newLobe = struct('MinFA', minFA, 'MaxFA', maxFA, ...
                             'NPoints', nPts,  'Shape', shape);
            obj.Lobes(end+1) = newLobe;

            obj.updateLobeList();
            obj.updatePlot();
        end

        % -------------------------------------------------------------- %
        function removeLobe(obj)
            % Remove the currently selected lobe from the list.
            if isempty(obj.Lobes)
                return;
            end

            selItem = obj.LobeListBox.Value;
            if isempty(selItem)
                return;
            end

            items  = obj.LobeListBox.Items;
            selIdx = find(strcmp(items, selItem), 1);
            if isempty(selIdx)
                return;
            end

            obj.Lobes(selIdx) = [];
            obj.updateLobeList();
            obj.updatePlot();
        end

        % -------------------------------------------------------------- %
        function updateLobeList(obj)
            % Rebuild the listbox items from the stored Lobes struct array.
            n     = numel(obj.Lobes);
            items = cell(1, n);
            for k = 1:n
                L        = obj.Lobes(k);
                items{k} = sprintf('%d.  %-10s  %.0f deg - %.0f deg  N=%d', ...
                    k, L.Shape, L.MinFA, L.MaxFA, L.NPoints);
            end
            obj.LobeListBox.Items = items;
        end

        % -------------------------------------------------------------- %
        function updatePlot(obj)
            % Recompute the full flip angle pattern and refresh the axes.
            pattern        = obj.buildPattern();
            obj.FlipAngles = pattern;

            ax = obj.FAAxes;
            cla(ax);

            if isempty(pattern)
                title(ax, 'Flip Angle Pattern (no lobes defined)');
                return;
            end

            plot(ax, 1:numel(pattern), pattern, 'b-', 'LineWidth', 1.2);
            title(ax, sprintf('Flip Angle Pattern  (%d frames)', numel(pattern)));
            xlabel(ax, 'Frame Number');
            ylabel(ax, 'Flip Angle (deg)');
            grid(ax, 'on');
            ylim(ax, [0, max(pattern) * 1.15 + 1]);
        end

        % -------------------------------------------------------------- %
        function pattern = buildPattern(obj)
            % Concatenate all lobe waveforms into a single row vector.
            pattern = [];
            for k = 1:numel(obj.Lobes)
                pattern = [pattern, obj.computeLobeWaveform(obj.Lobes(k))]; %#ok<AGROW>
            end
        end

        % -------------------------------------------------------------- %
        function generateDictionary(obj)
            % Validate inputs and pass all parameters to dictionary engine.

            % --- Parse search-space ranges ---
            try
                T1 = obj.parseRangeString(obj.T1Edit.Value);
                T2 = obj.parseRangeString(obj.T2Edit.Value);
                B1 = obj.parseRangeString(obj.B1Edit.Value);
            catch ME
                uialert(obj.TabHandle.Parent, ME.message, 'Parameter Error');
                return;
            end

            if isempty(obj.FlipAngles)
                uialert(obj.TabHandle.Parent, ...
                    'No flip angle pattern defined. Add lobes or load a file.', ...
                    'Missing FA Pattern');
                return;
            end

            % --- Collect sequence timing ---
            TR = obj.TREdit.Value;
            TE = obj.TEEdit.Value;

            % --- Collect inversion pulse parameters ---
            useInversion = obj.InversionCheckbox.Value;
            invType      = obj.InversionTypeDropdown.Value;
            rfDuration   = obj.RFDurationEdit.Value;
            rasterTime   = obj.RasterTimeEdit.Value;

            fprintf(['Generating dictionary:\n' ...
                '  T1: %d values  T2: %d values  B1: %d values\n' ...
                '  TR: %.2f ms  TE: %.2f ms\n' ...
                '  FA frames: %d\n' ...
                '  Inversion: %s'], ...
                numel(T1), numel(T2), numel(B1), TR, TE, ...
                numel(obj.FlipAngles), ...
                obj.inversionSummary(useInversion, invType, rfDuration, rasterTime));
            
            % Pass parameters to dictionary engine


            % TODO: pass parameters to your dictionary engine, e.g.:
            % params.T1          = T1;
            % params.T2          = T2;
            % params.B1          = B1;
            % params.TR          = TR;
            % params.TE          = TE;
            % params.FA          = obj.FlipAngles;
            % params.useInv      = useInversion;
            % params.invType     = invType;
            % params.rfDuration  = rfDuration;
            % params.rasterTime  = rasterTime;
            % dictionary = generateMRFDictionary(params);
        end

        % -------------------------------------------------------------- %
        function loadFlipAngles(obj)
            % Load a flip angle pattern from a plain-text file.
            [file, location] = uigetfile({'*.txt', 'Text Files (*.txt)'}, ...
                'Select Flip Angle File');
            if isequal(file, 0)
                return;
            end

            try
                fa = readmatrix(fullfile(location, file));
                fa = fa(:).';   % ensure row vector
            catch ME
                uialert(obj.TabHandle.Parent, ...
                    ['Could not read file: ' ME.message], 'Load Error');
                return;
            end

            obj.FlipAngles = fa;
            % Clear stored lobes — pattern now comes from an external file
            obj.Lobes = struct('MinFA', {}, 'MaxFA', {}, ...
                               'NPoints', {}, 'Shape', {});
            obj.updateLobeList();
            obj.updatePlot();
        end

        % -------------------------------------------------------------- %
        function exportFlipAngles(obj)
            % Write the current flip angle pattern to a text file,
            % one value per line.
            if isempty(obj.FlipAngles)
                uialert(obj.TabHandle.Parent, ...
                    'No flip angle pattern to export.', 'Export Error');
                return;
            end

            [file, location] = uiputfile({'*.txt', 'Text File (*.txt)'}, ...
                'Save Flip Angle Pattern');
            if isequal(file, 0)
                return;
            end

            fid = fopen(fullfile(location, file), 'w');
            if fid == -1
                uialert(obj.TabHandle.Parent, ...
                    'Could not open file for writing.', 'Export Error');
                return;
            end

            fprintf(fid, '%.6f\n', obj.FlipAngles);
            fclose(fid);

            uialert(obj.TabHandle.Parent, ...
                sprintf('Exported %d values to:\n%s', ...
                    numel(obj.FlipAngles), fullfile(location, file)), ...
                'Export Complete', 'Icon', 'success');
        end

    end % public methods

    % ------------------------------------------------------------------ %
    methods (Access = private)

        function waveform = computeLobeWaveform(~, lobe)
            % Generate the flip angle waveform for a single lobe.
            %
            %   Sine Lobe : half-sine envelope, rising from MinFA to peak
            %               at MaxFA and returning to MinFA.
            %   Sawtooth  : linear ramp from MinFA up to MaxFA.
            n  = lobe.NPoints;
            lo = lobe.MinFA;
            hi = lobe.MaxFA;

            switch lobe.Shape
                case 'Sine Lobe'
                    t        = linspace(0, pi, n);
                    waveform = lo + (hi - lo) .* sin(t);
                case 'Sawtooth'
                    waveform = linspace(lo, hi, n);
                otherwise
                    waveform = linspace(lo, hi, n);
            end
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

        % -------------------------------------------------------------- %
        function s = inversionSummary(~, useInv, invType, rfDur, raster)
            % Build a compact summary string for console output.
            if ~useInv
                s = 'none';
            elseif strcmp(invType, 'Instant')
                s = 'Instant (ideal 180°)';
            else
                s = sprintf('Hard Pulse  duration=%.3f ms  raster=%.1f µs', ...
                    rfDur, raster);
            end
        end

    end % private methods

end

