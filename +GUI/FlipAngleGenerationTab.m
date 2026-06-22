classdef FlipAngleGenerationTab < handle
    % FlipAngleGenerationTab - Dedicated flip angle generation tab.
    %   Manages FA lobe construction, loading/exporting patterns, and
    %   plotting the resulting flip-angle train.

    properties
        Parent
        TabHandle

        GenPanel

        NPointsLabel
        MinFAEdit
        MaxFAEdit
        NPointsEdit
        RampPointsLabel
        RampPointsEdit
        FlatTopPointsLabel
        FlatTopPointsEdit
        ShapeLabel
        ShapeDropdown
        AddLobeButton
        LobeListBox
        RemoveLobeButton

        LoadFAButton
        ExportFAButton

        FAAxes

        FlipAngles = []
        LoadedFlipAngles = []
        Lobes = struct('MinFA', {}, 'MaxFA', {}, 'NPoints', {}, 'Shape', {}, ...
            'RampPoints', {}, 'FlatTopPoints', {})

        FigureResizeListener
    end

    methods
        function obj = FlipAngleGenerationTab(parentMRFViewer, parentTab)
            obj.Parent = parentMRFViewer;
            obj.TabHandle = parentTab;
            obj.createUI();
        end

        function createUI(obj)
            TAB = obj.TabHandle;

            obj.GenPanel = uipanel(TAB, ...
                'Title', 'Flip Angle Pattern Generator', ...
                'FontWeight', 'bold', ...
                'Position', [10 88 370 500]);
            P = obj.GenPanel;

            uilabel(P, 'Text', 'Min FA (deg)', 'Position', [10 452 90 22]);
            obj.MinFAEdit = uieditfield(P, 'numeric', ...
                'Value', 5, 'Limits', [0 90], ...
                'Position', [103 452 55 22], ...
                'Tooltip', 'Minimum flip angle in degrees');

            uilabel(P, 'Text', 'Max FA (deg)', 'Position', [170 452 90 22]);
            obj.MaxFAEdit = uieditfield(P, 'numeric', ...
                'Value', 60, 'Limits', [0 90], ...
                'Position', [263 452 55 22], ...
                'Tooltip', 'Maximum flip angle in degrees');

            obj.NPointsLabel = uilabel(P, 'Text', 'N Points', 'Position', [10 425 70 22]);
            obj.NPointsEdit = uieditfield(P, 'numeric', ...
                'Value', 50, 'Limits', [2 10000], ...
                'RoundFractionalValues', true, ...
                'Position', [103 425 55 22], ...
                'Tooltip', 'Number of time points in this lobe');

            obj.RampPointsLabel = uilabel(P, 'Text', 'Ramp Points', ...
                'Position', [10 398 80 22], 'Visible', 'off');
            obj.RampPointsEdit = uieditfield(P, 'numeric', ...
                'Value', 30, 'Limits', [1 10000], ...
                'RoundFractionalValues', true, ...
                'Position', [93 398 65 22], ...
                'Tooltip', 'Number of points in the ramp segment', ...
                'Visible', 'off');

            obj.FlatTopPointsLabel = uilabel(P, 'Text', 'Flat-top Pts', ...
                'Position', [170 398 85 22], 'Visible', 'off');
            obj.FlatTopPointsEdit = uieditfield(P, 'numeric', ...
                'Value', 20, 'Limits', [1 10000], ...
                'RoundFractionalValues', true, ...
                'Position', [258 398 60 22], ...
                'Tooltip', 'Number of points in the flat-top segment', ...
                'Visible', 'off');

            obj.ShapeLabel = uilabel(P, 'Text', 'Shape', 'Position', [170 425 45 22]);
            obj.ShapeDropdown = uidropdown(P, ...
                'Items', {'Sine Lobe', 'Sawtooth', 'Ramp + Flat Top'}, ...
                'Value', 'Sine Lobe', ...
                'Position', [220 425 98 22], ...
                'ValueChangedFcn', @(~,~) obj.onShapeChanged());

            obj.AddLobeButton = uibutton(P, ...
                'Text', '+ Add Lobe', ...
                'Position', [10 392 350 26], ...
                'ButtonPushedFcn', @(~,~) obj.addLobe());

            uilabel(P, 'Text', 'Added Lobes', ...
                'Position', [10 366 120 22], 'FontWeight', 'bold');

            obj.LobeListBox = uilistbox(P, ...
                'Items', {}, ...
                'Position', [10 78 268 280], ...
                'Tooltip', 'Select a lobe then press Remove');

            obj.RemoveLobeButton = uibutton(P, ...
                'Text', sprintf('Remove\nSelected'), ...
                'Position', [285 78 75 280], ...
                'ButtonPushedFcn', @(~,~) obj.removeLobe());

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

            obj.FAAxes = uiaxes(TAB, 'Position', [400 20 540 650]);
            title(obj.FAAxes, 'Flip Angle Pattern');
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

            obj.onShapeChanged();
            obj.updateResponsiveLayout();
        end

        function addLobe(obj)
            minFA = obj.MinFAEdit.Value;
            maxFA = obj.MaxFAEdit.Value;
            nPts  = round(obj.NPointsEdit.Value);
            shape = obj.ShapeDropdown.Value;
            rampPts = [];
            flatTopPts = [];

            if minFA >= maxFA
                obj.safeAlert('Min FA must be less than Max FA.', 'Invalid Input', 'warning');
                return;
            end

            if obj.usesRampFlatShape(shape)
                rampPts = round(obj.RampPointsEdit.Value);
                flatTopPts = round(obj.FlatTopPointsEdit.Value);
                nPts = rampPts + flatTopPts;

                if rampPts < 1 || flatTopPts < 1
                    obj.safeAlert('Ramp and flat-top points must both be at least 1.', ...
                        'Invalid Input', 'warning');
                    return;
                end
            end

            newLobe = struct('MinFA', minFA, 'MaxFA', maxFA, ...
                             'NPoints', nPts, 'Shape', shape, ...
                             'RampPoints', rampPts, 'FlatTopPoints', flatTopPts);
            obj.Lobes(end+1) = newLobe;
            obj.updateLobeList();
            obj.updatePlot();
        end

        function removeLobe(obj)
            if isempty(obj.Lobes) && isempty(obj.LoadedFlipAngles)
                return;
            end

            selItem = obj.LobeListBox.Value;
            if isempty(selItem)
                return;
            end

            items = obj.LobeListBox.Items;
            selIdx = find(strcmp(items, selItem), 1);
            if isempty(selIdx)
                return;
            end

            loadedOffset = 0;
            if ~isempty(obj.LoadedFlipAngles)
                if selIdx == 1
                    obj.LoadedFlipAngles = [];
                    obj.updateLobeList();
                    obj.updatePlot();
                    return;
                end
                loadedOffset = 1;
            end

            lobeIdx = selIdx - loadedOffset;
            if lobeIdx < 1 || lobeIdx > numel(obj.Lobes)
                return;
            end

            obj.Lobes(lobeIdx) = [];
            obj.updateLobeList();
            obj.updatePlot();
        end

        function updateLobeList(obj)
            items = {};
            if ~isempty(obj.LoadedFlipAngles)
                items{end+1} = sprintf('Loaded FA File      N=%d', numel(obj.LoadedFlipAngles)); %#ok<AGROW>
            end

            for k = 1:numel(obj.Lobes)
                L = obj.Lobes(k);
                if obj.usesRampFlatShape(L.Shape)
                    items{end+1} = sprintf('%d.  %-16s  %.0f deg - %.0f deg  Ramp=%d Flat=%d', ...
                        k, L.Shape, L.MinFA, L.MaxFA, L.RampPoints, L.FlatTopPoints);
                else
                    items{end+1} = sprintf('%d.  %-16s  %.0f deg - %.0f deg  N=%d', ...
                        k, L.Shape, L.MinFA, L.MaxFA, L.NPoints);
                end
            end
            obj.LobeListBox.Items = items;
            if isempty(items)
                obj.LobeListBox.Value = {};
            else
                obj.LobeListBox.Value = items{1};
            end
        end

        function updatePlot(obj)
            pattern = obj.buildPattern();
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

        function pattern = buildPattern(obj)
            pattern = obj.LoadedFlipAngles(:).';
            for k = 1:numel(obj.Lobes)
                pattern = [pattern, obj.computeLobeWaveform(obj.Lobes(k))]; %#ok<AGROW>
            end
        end

        function loadFlipAngles(obj)
            [file, location] = uigetfile({'*.txt', 'Text Files (*.txt)'}, ...
                'Select Flip Angle File');
            if isequal(file, 0)
                return;
            end

            try
                rawText = fileread(fullfile(location, file));
                lines = splitlines(rawText);

                fa = [];
                expectedCount = [];
                for lineIdx = 1:numel(lines)
                    lineText = strtrim(lines{lineIdx});
                    if isempty(lineText)
                        continue;
                    end

                    if startsWith(lineText, '#')
                        if lineIdx == 1
                            expectedCount = str2double(extractAfter(lineText, '#'));
                            if isnan(expectedCount)
                                error('Invalid flip-angle header. Expected first line in the form #N.');
                            end
                            continue;
                        end

                        continue;
                    end

                    value = str2double(lineText);
                    if isnan(value)
                        error('Invalid flip-angle value on line %d.', lineIdx);
                    end

                    fa(end+1) = value; %#ok<AGROW>
                end

                if isempty(fa)
                    error('No flip-angle values found in file.');
                end

                if ~isempty(expectedCount) && numel(fa) ~= expectedCount
                    error('Header count (%d) does not match loaded flip angles (%d).', expectedCount, numel(fa));
                end
            catch ME
                obj.safeAlert(['Could not read file: ' ME.message], 'Load Error', 'error');
                return;
            end

            obj.LoadedFlipAngles = fa;
            obj.FlipAngles = fa;
            obj.Lobes = struct('MinFA', {}, 'MaxFA', {}, 'NPoints', {}, 'Shape', {}, ...
                'RampPoints', {}, 'FlatTopPoints', {});
            obj.updateLobeList();
            obj.updatePlot();
        end

        function exportFlipAngles(obj)
            if isempty(obj.FlipAngles)
                obj.safeAlert('No flip angle pattern to export.', 'Export Error', 'warning');
                return;
            end

            [file, location] = uiputfile({'*.txt', 'Text File (*.txt)'}, ...
                'Save Flip Angle Pattern');
            if isequal(file, 0)
                return;
            end

            fid = fopen(fullfile(location, file), 'w');
            if fid == -1
                obj.safeAlert('Could not open file for writing.', 'Export Error', 'error');
                return;
            end

            fprintf(fid, '#%d\n', numel(obj.FlipAngles));
            fprintf(fid, '%.6f\n', obj.FlipAngles);
            fclose(fid);

            obj.safeAlert( ...
                sprintf('Exported %d values to:\n%s', numel(obj.FlipAngles), fullfile(location, file)), ...
                'Export Complete', 'success');
        end
    end

    methods
        function updateResponsiveLayout(obj)
            if isempty(obj.TabHandle) || ~isvalid(obj.TabHandle)
                return;
            end

            tabPos = obj.TabHandle.Position;
            tabW = max(tabPos(3), 720);
            tabH = max(tabPos(4), 520);

            margin = 10;
            colGap = 10;

            leftW = 370;
            minAxesW = 220;
            if tabW < (leftW + minAxesW + 3*margin)
                leftW = max(360, tabW - minAxesW - 3*margin);
            end

            rightX = margin + leftW + colGap;
            rightW = max(120, tabW - rightX - margin);

            obj.GenPanel.Position = [margin 88 leftW max(330, tabH - 140)];

            obj.FAAxes.Position = [rightX margin rightW max(120, tabH - 2*margin)];

            obj.layoutGenPanelControls();
            obj.LoadFAButton.Position = [margin 56 floor((leftW - 10)/2) 28];
            obj.ExportFAButton.Position = [margin + floor((leftW - 10)/2) + 10 56 leftW - floor((leftW - 10)/2) - 10 28];
        end

        function layoutGenPanelControls(obj)
            p = obj.GenPanel.Position;
            pw = p(3);
            ph = p(4);

            margin = 10;
            h = 22;
            rowGap = 4;
            titlePad = 24;

            y1 = ph - titlePad - h;
            y2 = y1 - (h + rowGap);
            y3 = y2 - (h + rowGap);
            yAdd = y3 - (26 + rowGap);
            yAdded = yAdd - (h + 2);

            halfW = floor((pw - 2*margin - 10)/2);
            leftX = margin;
            rightX = leftX + halfW + 10;

            obj.positionLabel(obj.GenPanel, 'Min FA (deg)', [leftX y1 90 h]);
            obj.MinFAEdit.Position = [leftX + 93 y1 max(40, halfW - 93) h];

            obj.positionLabel(obj.GenPanel, 'Max FA (deg)', [rightX y1 90 h]);
            obj.MaxFAEdit.Position = [rightX + 93 y1 max(40, halfW - 93) h];

            obj.NPointsLabel.Position = [leftX y2 70 h];
            obj.NPointsEdit.Position = [leftX + 73 y2 max(40, halfW - 73) h];

            obj.ShapeLabel.Position = [rightX y2 45 h];
            obj.ShapeDropdown.Position = [rightX + 48 y2 max(60, halfW - 48) h];

            obj.RampPointsLabel.Position = [leftX y3 80 h];
            obj.RampPointsEdit.Position = [leftX + 83 y3 max(40, halfW - 83) h];

            obj.FlatTopPointsLabel.Position = [rightX y3 85 h];
            obj.FlatTopPointsEdit.Position = [rightX + 88 y3 max(40, halfW - 88) h];

            obj.AddLobeButton.Position = [margin yAdd max(120, pw - 2*margin) 26];
            obj.positionLabel(obj.GenPanel, 'Added Lobes', [margin yAdded 120 h]);

            listY = 7;
            listTop = yAdded - 2;
            listH = max(36, listTop - listY);
            rmW = min(90, max(72, floor(0.24 * pw)));
            listW = max(80, pw - 2*margin - rmW - 7);

            obj.LobeListBox.Position = [margin listY listW listH];
            obj.RemoveLobeButton.Position = [margin + listW + 7 listY rmW listH];
        end

        function onShapeChanged(obj)
            isRampFlat = obj.usesRampFlatShape(obj.ShapeDropdown.Value);

            obj.NPointsLabel.Visible = obj.onOff(~isRampFlat);
            obj.NPointsEdit.Visible = obj.onOff(~isRampFlat);
            obj.RampPointsLabel.Visible = obj.onOff(isRampFlat);
            obj.RampPointsEdit.Visible = obj.onOff(isRampFlat);
            obj.FlatTopPointsLabel.Visible = obj.onOff(isRampFlat);
            obj.FlatTopPointsEdit.Visible = obj.onOff(isRampFlat);

            obj.updateResponsiveLayout();
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

        function tf = usesRampFlatShape(~, shape)
            tf = strcmp(shape, 'Ramp + Flat Top');
        end

        function value = onOff(~, tf)
            if tf
                value = 'on';
            else
                value = 'off';
            end
        end

        function waveform = computeLobeWaveform(~, lobe)
            n = lobe.NPoints;
            lo = lobe.MinFA;
            hi = lobe.MaxFA;

            switch lobe.Shape
                case 'Sine Lobe'
                    t = linspace(0, pi, n);
                    waveform = lo + (hi - lo) .* sin(t);
                case 'Ramp + Flat Top'
                    rampPts = lobe.RampPoints;
                    flatTopPts = lobe.FlatTopPoints;
                    waveform = [linspace(lo, hi, rampPts), repmat(hi, 1, flatTopPts)];
                otherwise
                    waveform = linspace(lo, hi, n);
            end
        end
    end
end
