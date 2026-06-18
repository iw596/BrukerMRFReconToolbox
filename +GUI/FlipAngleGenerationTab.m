classdef FlipAngleGenerationTab < handle
    % FlipAngleGenerationTab - Dedicated flip angle generation tab.
    %   Manages FA lobe construction, loading/exporting patterns, and
    %   plotting the resulting flip-angle train.

    properties
        Parent
        TabHandle

        GenPanel

        MinFAEdit
        MaxFAEdit
        NPointsEdit
        ShapeDropdown
        AddLobeButton
        LobeListBox
        RemoveLobeButton

        LoadFAButton
        ExportFAButton

        FAAxes

        FlipAngles = []
        Lobes = struct('MinFA', {}, 'MaxFA', {}, 'NPoints', {}, 'Shape', {})

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

            uilabel(P, 'Text', 'N Points', 'Position', [10 425 70 22]);
            obj.NPointsEdit = uieditfield(P, 'numeric', ...
                'Value', 50, 'Limits', [2 10000], ...
                'RoundFractionalValues', true, ...
                'Position', [103 425 55 22], ...
                'Tooltip', 'Number of time points in this lobe');

            uilabel(P, 'Text', 'Shape', 'Position', [170 425 45 22]);
            obj.ShapeDropdown = uidropdown(P, ...
                'Items', {'Sine Lobe', 'Sawtooth'}, ...
                'Value', 'Sine Lobe', ...
                'Position', [220 425 98 22]);

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

            obj.updateResponsiveLayout();
        end

        function addLobe(obj)
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
                             'NPoints', nPts, 'Shape', shape);
            obj.Lobes(end+1) = newLobe;
            obj.updateLobeList();
            obj.updatePlot();
        end

        function removeLobe(obj)
            if isempty(obj.Lobes)
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

            obj.Lobes(selIdx) = [];
            obj.updateLobeList();
            obj.updatePlot();
        end

        function updateLobeList(obj)
            n = numel(obj.Lobes);
            items = cell(1, n);
            for k = 1:n
                L = obj.Lobes(k);
                items{k} = sprintf('%d.  %-10s  %.0f deg - %.0f deg  N=%d', ...
                    k, L.Shape, L.MinFA, L.MaxFA, L.NPoints);
            end
            obj.LobeListBox.Items = items;
        end

        function updatePlot(obj)
            pattern = obj.buildPattern();
            obj.FlipAngles = pattern;
            obj.Parent.FlipAngles = pattern;

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
            pattern = [];
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
                fa = readmatrix(fullfile(location, file));
                fa = fa(:).';
            catch ME
                uialert(obj.TabHandle.Parent, ...
                    ['Could not read file: ' ME.message], 'Load Error');
                return;
            end

            obj.FlipAngles = fa;
            obj.Parent.FlipAngles = fa;
            obj.Lobes = struct('MinFA', {}, 'MaxFA', {}, 'NPoints', {}, 'Shape', {});
            obj.updateLobeList();
            obj.updatePlot();
        end

        function exportFlipAngles(obj)
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
                sprintf('Exported %d values to:\n%s', numel(obj.FlipAngles), fullfile(location, file)), ...
                'Export Complete', 'Icon', 'success');
        end
    end

    methods (Access = private)
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
            yAdd = y2 - (26 + rowGap);
            yAdded = yAdd - (h + 2);

            halfW = floor((pw - 2*margin - 10)/2);
            leftX = margin;
            rightX = leftX + halfW + 10;

            obj.positionLabel(obj.GenPanel, 'Min FA (deg)', [leftX y1 90 h]);
            obj.MinFAEdit.Position = [leftX + 93 y1 max(40, halfW - 93) h];

            obj.positionLabel(obj.GenPanel, 'Max FA (deg)', [rightX y1 90 h]);
            obj.MaxFAEdit.Position = [rightX + 93 y1 max(40, halfW - 93) h];

            obj.positionLabel(obj.GenPanel, 'N Points', [leftX y2 70 h]);
            obj.NPointsEdit.Position = [leftX + 73 y2 max(40, halfW - 73) h];

            obj.positionLabel(obj.GenPanel, 'Shape', [rightX y2 45 h]);
            obj.ShapeDropdown.Position = [rightX + 48 y2 max(60, halfW - 48) h];

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

        function positionLabel(~, panel, labelText, pos)
            h = findobj(panel, 'Type', 'uilabel', 'Text', labelText);
            if ~isempty(h)
                h(1).Position = pos;
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
                otherwise
                    waveform = linspace(lo, hi, n);
            end
        end
    end
end
