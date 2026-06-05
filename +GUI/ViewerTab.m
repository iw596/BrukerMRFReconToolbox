classdef ViewerTab < handle
    % ViewerTab - Handles the Viewer tab UI and functionality
    %   This class manages the MRF/GT image viewer, ROI analysis,
    %   and display controls

    properties
        Parent          % Reference to main MRFViewer instance
        TabHandle       % Handle to the tab itself

        % Display Controls
        LoadMRFButton
        LoadGTButton
        SliceSlider
        SliceLabel

        MapDropdown
        MapLabel

        ColorScaleModeDropdown
        ColorScaleModeLabel
        ColorScaleMinLabel
        ColorScaleMinField
        ColorScaleMaxLabel
        ColorScaleMaxField

        InfoLabel

        % Axes
        MRFAxes
        GTAxes

        % ROI Controls
        ROIPanel
        ROIDrawModeLabel
        ROIDrawModeDropdown
        AddROIButton
        DeleteROIButton
        SaveROIButton
        LoadROIButton
        ShowAllROIStatsButton
        CorrelationPlotButton
        ROIListBox
        ROIStatsMeanLabel
        ROIStatsStdLabel
    end

    methods
        function obj = ViewerTab(parentMRFViewer, parentTab)
            % Initialize ViewerTab
            %   parentMRFViewer: Reference to the MRFViewer instance
            %   parentTab: The uitable container for this tab

            obj.Parent = parentMRFViewer;
            obj.TabHandle = parentTab;

            obj.createUI();
        end

        function createUI(obj)
            % Create all UI elements for the Viewer tab

            % ---------------------------------------------------------
            % Buttons
            % ---------------------------------------------------------

            obj.LoadMRFButton = uibutton(obj.TabHandle,...
                'Text','Load MRF',...
                'Position',[20 620 120 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.loadMRF());

            obj.LoadGTButton = uibutton(obj.TabHandle,...
                'Text','Load Ground Truth',...
                'Position',[160 620 140 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.loadGT());

            % ---------------------------------------------------------
            % Map selector
            % ---------------------------------------------------------

            obj.MapLabel = uilabel(obj.TabHandle,...
                'Position',[340 620 40 25],...
                'Text','Map');

            obj.MapDropdown = uidropdown(obj.TabHandle,...
                'Position',[380 620 150 30],...
                'Items',{'Map 1'},...
                'ValueChangedFcn',...
                @(src,event)obj.changeMap());

            obj.ColorScaleModeLabel = uilabel(obj.TabHandle,...
                'Position',[560 620 80 25],...
                'Text','Scale mode');

            obj.ColorScaleModeDropdown = uidropdown(obj.TabHandle,...
                'Position',[640 620 100 30],...
                'Items',{'Auto','Manual'},...
                'Value','Auto',...
                'ValueChangedFcn',...
                @(src,event)obj.changeColorScaleMode());

            obj.ColorScaleMinLabel = uilabel(obj.TabHandle,...
                'Position',[760 620 30 25],...
                'Text','Min');

            obj.ColorScaleMinField = uieditfield(obj.TabHandle,'numeric',...
                'Position',[795 620 80 30],...
                'Value',0,...
                'Enable','off',...
                'ValueChangedFcn',...
                @(src,event)obj.applyColorScale());

            obj.ColorScaleMaxLabel = uilabel(obj.TabHandle,...
                'Position',[885 620 35 25],...
                'Text','Max');

            obj.ColorScaleMaxField = uieditfield(obj.TabHandle,'numeric',...
                'Position',[925 620 80 30],...
                'Value',1,...
                'Enable','off',...
                'ValueChangedFcn',...
                @(src,event)obj.applyColorScale());

            % ---------------------------------------------------------
            % ROI controls
            % ---------------------------------------------------------

            obj.ROIPanel = uipanel(obj.TabHandle,...
                'Title','ROI Controls',...
                'Position',[1180 180 180 470]);

            obj.ROIDrawModeLabel = uilabel(obj.ROIPanel,...
                'Position',[10 410 160 22],...
                'Text','Draw mode');

            obj.ROIDrawModeDropdown = uidropdown(obj.ROIPanel,...
                'Position',[10 380 160 30],...
                'Items',{'Rectangle','Freehand'},...
                'Value','Rectangle');

            obj.AddROIButton = uibutton(obj.ROIPanel,...
                'Text','Draw ROI',...
                'Position',[10 340 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.startROIDraw());

            obj.DeleteROIButton = uibutton(obj.ROIPanel,...
                'Text','Delete ROI',...
                'Position',[10 300 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.deleteROI());

            obj.SaveROIButton = uibutton(obj.ROIPanel,...
                'Text','Save ROIs',...
                'Position',[10 260 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.saveROIs());

            obj.LoadROIButton = uibutton(obj.ROIPanel,...
                'Text','Load ROIs',...
                'Position',[10 220 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.loadROIs());

            obj.ShowAllROIStatsButton = uibutton(obj.ROIPanel,...
                'Text','All map stats',...
                'Position',[10 185 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.showAllMapStats());

            obj.CorrelationPlotButton = uibutton(obj.ROIPanel,...
                'Text','Correlation plot',...
                'Position',[10 155 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.plotCorrelation());

            obj.ROIStatsMeanLabel = uilabel(obj.ROIPanel,...
                'Position',[10 120 160 22],...
                'Text','Mean: -');

            obj.ROIStatsStdLabel = uilabel(obj.ROIPanel,...
                'Position',[10 95 160 22],...
                'Text','Std: -');

            obj.ROIListBox = uilistbox(obj.ROIPanel,...
                'Position',[10 10 160 85],...
                'Items',{},...
                'Multiselect','on',...
                'ValueChangedFcn',@(src,event)obj.updateROIStats());

            % ---------------------------------------------------------
            % Axes
            % ---------------------------------------------------------

            obj.MRFAxes = uiaxes(obj.TabHandle,...
                'Position',[50 180 550 470]);

            title(obj.MRFAxes,'MRF')

            obj.GTAxes = uiaxes(obj.TabHandle,...
                'Position',[700 180 550 470]);

            title(obj.GTAxes,'Ground Truth')

            % ---------------------------------------------------------
            % Slice controls
            % ---------------------------------------------------------

            obj.SliceLabel = uilabel(obj.TabHandle,...
                'Position',[50 120 120 25],...
                'Text','Slice: 1');

            obj.SliceSlider = uislider(obj.TabHandle,...
                'Position',[180 135 1000 3],...
                'ValueChangedFcn',@(src,event)obj.changeSlice());

            % ---------------------------------------------------------
            % Info
            % ---------------------------------------------------------

            obj.InfoLabel = uilabel(obj.TabHandle,...
                'Position',[50 40 1200 40],...
                'Text','No data loaded');
        end

        function resizeUI(obj, figPos)
            % Update UI element positions based on figure size
            %   figPos: Figure position [x y width height]

            width = max(figPos(3) - 20, 400);
            height = max(figPos(4) - 20, 300);

            contentHeight = height - 90;
            contentHeight = max(contentHeight, 180);

            buttonY = contentHeight - 30;
            buttonY = max(buttonY, 520);

            obj.LoadMRFButton.Position = [20 buttonY 120 30];
            obj.LoadGTButton.Position = [160 buttonY 140 30];
            obj.MapLabel.Position = [340 buttonY+5 40 25];
            obj.MapDropdown.Position = [380 buttonY 150 30];
            obj.ColorScaleModeLabel.Position = [560 buttonY+5 80 25];
            obj.ColorScaleModeDropdown.Position = [640 buttonY 100 30];
            obj.ColorScaleMinLabel.Position = [760 buttonY+5 30 25];
            obj.ColorScaleMinField.Position = [795 buttonY 80 30];
            obj.ColorScaleMaxLabel.Position = [885 buttonY+5 35 25];
            obj.ColorScaleMaxField.Position = [925 buttonY 80 30];

            panelWidth = 220;
            mainWidth = max(width - panelWidth - 40, 420);
            axisWidth = max((mainWidth - 80) / 2, 200);
            axisHeight = max(contentHeight - 140, 200);

            obj.ROIPanel.Position = [width - panelWidth - 20 90 panelWidth contentHeight];

            obj.MRFAxes.Position = [50 90 axisWidth axisHeight];
            obj.GTAxes.Position = [60 + axisWidth 90 axisWidth axisHeight];

            obj.SliceLabel.Position = [50 40 120 25];
            obj.SliceSlider.Position = [180 65 max(width - 240, 200) 3];
            obj.InfoLabel.Position = [50 10 max(width - 100, 200) 25];
        end

        % ============================================================
        % Slice, Map and Display Controls
        % ============================================================

        function changeSlice(obj)

            if isempty(obj.Parent.MRFData)
                return
            end

            obj.Parent.CurrentSlice = round(obj.SliceSlider.Value);

            obj.SliceLabel.Text = sprintf('Slice: %d', obj.Parent.CurrentSlice);

            obj.updateDisplay();
        end

        function changeMap(obj)

            idx = find(strcmp( ...
                obj.MapDropdown.Value,...
                obj.MapDropdown.Items));

            if isempty(idx)
                idx = 1;
            end

            obj.Parent.CurrentMap = idx;

            obj.updateDisplay();
        end

        function changeColorScaleMode(obj)

            manual = strcmp(obj.ColorScaleModeDropdown.Value,'Manual');
            if manual
                obj.ColorScaleMinField.Enable = 'on';
                obj.ColorScaleMaxField.Enable = 'on';
            else
                obj.ColorScaleMinField.Enable = 'off';
                obj.ColorScaleMaxField.Enable = 'off';
            end

            if manual
                if ~isempty(obj.Parent.MRFData)
                    img = obj.Parent.extractImage(obj.Parent.MRFData);
                elseif ~isempty(obj.Parent.GTData)
                    img = obj.Parent.extractImage(obj.Parent.GTData);
                else
                    img = [];
                end

                if ~isempty(img)
                    obj.ColorScaleMinField.Value = double(min(img(:)));
                    obj.ColorScaleMaxField.Value = double(max(img(:)));
                end
            end

            obj.updateDisplay();
        end

        function applyColorScale(obj)

            if strcmp(obj.ColorScaleModeDropdown.Value,'Manual') && ...
                    obj.ColorScaleMinField.Value >= obj.ColorScaleMaxField.Value

                uialert(obj.Parent.Fig, ...
                    'Colorbar minimum must be less than maximum.', ...
                    'Invalid scale range', ...
                    'Icon','warning');
                return
            end

            obj.updateDisplay();
        end

        function scrollSlices(obj, event)

            if isempty(obj.Parent.MRFData)
                return
            end

            maxSlice = round(obj.SliceSlider.Limits(2));

            obj.Parent.CurrentSlice = ...
                obj.Parent.CurrentSlice - sign(event.VerticalScrollCount);

            obj.Parent.CurrentSlice = ...
                max(1,min(maxSlice,obj.Parent.CurrentSlice));

            obj.SliceSlider.Value = obj.Parent.CurrentSlice;

            obj.SliceLabel.Text = ...
                sprintf('Slice: %d',obj.Parent.CurrentSlice);

            obj.updateDisplay();
        end

        function updateDisplay(obj)

            cla(obj.MRFAxes)
            cla(obj.GTAxes)

            % ---------------------------------------------------------
            % MRF
            % ---------------------------------------------------------

            if ~isempty(obj.Parent.MRFData)

                img = obj.Parent.extractImage(obj.Parent.MRFData);

                imagesc(obj.MRFAxes,img);

                axis(obj.MRFAxes,'image');

                colormap(obj.MRFAxes,"turbo");

                if strcmp(obj.ColorScaleModeDropdown.Value,'Manual')
                    cmin = obj.ColorScaleMinField.Value;
                    cmax = obj.ColorScaleMaxField.Value;
                    if cmin < cmax
                        caxis(obj.MRFAxes,[cmin cmax]);
                    end
                end

                colorbar(obj.MRFAxes);

            end

            % ---------------------------------------------------------
            % Ground Truth
            % ---------------------------------------------------------

            if ~isempty(obj.Parent.GTData)

                gt = obj.Parent.extractImage(obj.Parent.GTData);

                imagesc(obj.GTAxes,gt);

                axis(obj.GTAxes,'image');

                colormap(obj.GTAxes,gray);

                if strcmp(obj.ColorScaleModeDropdown.Value,'Manual')
                    cmin = obj.ColorScaleMinField.Value;
                    cmax = obj.ColorScaleMaxField.Value;
                    if cmin < cmax
                        caxis(obj.GTAxes,[cmin cmax]);
                    end
                end

                colorbar(obj.GTAxes);

            end

            obj.Parent.drawROIs();
            obj.Parent.updateInfo();
            obj.updateROIStats();
        end

        function configureSliceSlider(obj)

            if isempty(obj.Parent.MRFData)
                obj.SliceSlider.Enable = 'off';
                return
            end

            sz = size(obj.Parent.MRFData);

            if numel(sz) < 3
                nSlices = 1;
            else
                nSlices = sz(3);
            end

            % IMPORTANT: ensure valid range
            nSlices = max(nSlices,1);

            obj.SliceSlider.Limits = [1 nSlices];
            obj.SliceSlider.Value  = 1;

            obj.SliceSlider.Enable = 'on';

        end

        function configureMapDropdown(obj)

            if isempty(obj.Parent.MRFData)
                return
            end

            sz = size(obj.Parent.MRFData);

            if numel(sz) < 4

                nMaps = 1;

            else

                nMaps = sz(4);

            end

            if ~isempty(obj.Parent.MapNames) && numel(obj.Parent.MapNames) == nMaps
                items = obj.Parent.MapNames;
            else
                items = cell(1,nMaps);
                for k = 1:nMaps
                    items{k} = sprintf('Map %d',k);
                end
            end

            obj.MapDropdown.Items = items;
            obj.MapDropdown.Value = items{1};

        end

        % ============================================================
        % ROI Management
        % ============================================================

        function startROIDraw(obj)

            if isempty(obj.Parent.MRFData)
                uialert(obj.Parent.Fig, ...
                    'Load MRF data before drawing ROIs.', ...
                    'Draw ROI', ...
                    'Icon','warning');
                return
            end

            drawMode = obj.ROIDrawModeDropdown.Value;

            switch drawMode
                case 'Rectangle'
                    roi = drawrectangle(obj.MRFAxes,'Color','r');
                case 'Freehand'
                    roi = drawfreehand(obj.MRFAxes,'Color','r');
                otherwise
                    return
            end

            wait(roi);

            if isempty(roi.Position)
                delete(roi);
                return
            end

            obj.Parent.ROIs(end+1).Slice = obj.Parent.CurrentSlice;
            obj.Parent.ROIs(end).Position = roi.Position;
            obj.Parent.ROIs(end).Type = drawMode;

            delete(roi);

            obj.updateROIList();
            obj.updateDisplay();
        end

        function deleteROI(obj)

            sel = obj.ROIListBox.Value;
            if isempty(sel)
                return
            end

            items = obj.ROIListBox.Items;
            if iscell(sel)
                idx = find(ismember(items,sel));
            else
                idx = find(strcmp(items,sel));
            end

            if isempty(idx)
                return
            end

            obj.Parent.ROIs(idx) = [];
            obj.updateROIList();
            obj.updateDisplay();
        end

        function updateROIList(obj)

            labels = cell(1,numel(obj.Parent.ROIs));
            for k = 1:numel(obj.Parent.ROIs)
                labels{k} = sprintf('ROI %d (slice %d)', k, obj.Parent.ROIs(k).Slice);
            end

            obj.ROIListBox.Items = labels;
            if ~isempty(labels)
                obj.ROIListBox.Value = labels{end};
            else
                obj.ROIListBox.Value = {};
            end

            obj.updateROIStats();
        end

        function updateROIStats(obj)

            if isempty(obj.Parent.ROIs) || isempty(obj.ROIListBox.Value)
                obj.ROIStatsMeanLabel.Text = sprintf('Mean (map %d): -', obj.Parent.CurrentMap);
                obj.ROIStatsStdLabel.Text  = sprintf('Std (map %d): -', obj.Parent.CurrentMap);
                return
            end

            sel = obj.ROIListBox.Value;
            if iscell(sel)
                sel = sel{1};
            end

            items = obj.ROIListBox.Items;
            idx = find(strcmp(items,sel),1);
            if isempty(idx) || idx > numel(obj.Parent.ROIs)
                obj.ROIStatsMeanLabel.Text = 'Mean: -';
                obj.ROIStatsStdLabel.Text  = 'Std: -';
                return
            end

            roi = obj.Parent.ROIs(idx);
            if isempty(obj.Parent.MRFData)
                obj.ROIStatsMeanLabel.Text = 'Mean: -';
                obj.ROIStatsStdLabel.Text  = 'Std: -';
                return
            end

            img = obj.Parent.extractImage(obj.Parent.MRFData);
            mask = false(size(img));

            switch roi.Type
                case 'Rectangle'
                    x = roi.Position(1);
                    y = roi.Position(2);
                    w = roi.Position(3);
                    h = roi.Position(4);

                    x1 = max(round(x),1);
                    x2 = min(round(x + w),size(img,2));
                    y1 = max(round(y),1);
                    y2 = min(round(y + h),size(img,1));

                    if x1 <= x2 && y1 <= y2
                        mask(y1:y2,x1:x2) = true;
                    end
                otherwise
                    pos = roi.Position;
                    if size(pos,2) == 2
                        mask = poly2mask(pos(:,1), pos(:,2), size(img,1), size(img,2));
                    end
            end

            values = img(mask);
            if isempty(values)
                obj.ROIStatsMeanLabel.Text = sprintf('Mean (map %d): -', obj.Parent.CurrentMap);
                obj.ROIStatsStdLabel.Text  = sprintf('Std (map %d): -', obj.Parent.CurrentMap);
                return
            end

            obj.ROIStatsMeanLabel.Text = sprintf('Mean (map %d): %.4g', obj.Parent.CurrentMap, mean(values(:),'omitnan'));
            obj.ROIStatsStdLabel.Text  = sprintf('Std (map %d): %.4g', obj.Parent.CurrentMap, std(values(:),'omitnan'));
        end

        function showAllMapStats(obj)

            if isempty(obj.Parent.ROIs) || isempty(obj.ROIListBox.Value)
                uialert(obj.Parent.Fig, ...
                    'Select an ROI first to compute statistics.', ...
                    'All map stats', ...
                    'Icon','warning');
                return
            end

            sel = obj.ROIListBox.Value;
            if iscell(sel)
                sel = sel{1};
            end

            items = obj.ROIListBox.Items;
            idx = find(strcmp(items,sel),1);
            if isempty(idx) || idx > numel(obj.Parent.ROIs)
                uialert(obj.Parent.Fig, ...
                    'Unable to locate the selected ROI.', ...
                    'All map stats', ...
                    'Icon','error');
                return
            end

            roi = obj.Parent.ROIs(idx);
            if isempty(obj.Parent.MRFData)
                uialert(obj.Parent.Fig, ...
                    'Load MRF data before computing statistics.', ...
                    'All map stats', ...
                    'Icon','warning');
                return
            end

            mrfSize = size(obj.Parent.MRFData);
            mrfMaps = 1;
            if numel(mrfSize) >= 4
                mrfMaps = mrfSize(4);
            end

            tableData = cell(0,3);
            for mapIdx = 1:mrfMaps
                if mrfMaps == 1
                    img = obj.Parent.extractImage(obj.Parent.MRFData);
                    rowName = obj.MapDropdown.Items{1};
                else
                    prevMap = obj.Parent.CurrentMap;
                    obj.Parent.CurrentMap = mapIdx;
                    img = obj.Parent.extractImage(obj.Parent.MRFData);
                    obj.Parent.CurrentMap = prevMap;
                    rowName = obj.MapDropdown.Items{mapIdx};
                end

                stats = obj.Parent.computeROIStats(img, roi);
                tableData(end+1,:) = {rowName, stats.Mean, stats.Std}; %#ok<AGROW>
            end

            if ~isempty(obj.Parent.GTData)
                gtSize = size(obj.Parent.GTData);
                gtMaps = 1;
                if numel(gtSize) >= 4
                    gtMaps = gtSize(4);
                end

                for gtIdx = 1:gtMaps
                    if gtMaps == 1
                        gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                        rowName = 'GT';
                    else
                        prevMap = obj.Parent.CurrentMap;
                        obj.Parent.CurrentMap = gtIdx;
                        gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                        obj.Parent.CurrentMap = prevMap;
                        rowName = sprintf('GT %d', gtIdx);
                    end

                    stats = obj.Parent.computeROIStats(gtImg, roi);
                    tableData(end+1,:) = {rowName, stats.Mean, stats.Std};
                end
            end

            statsFig = uifigure( ...
                'Name', sprintf('ROI %d stats', idx), ...
                'Position',[200 200 380 240], ...
                'Resize','off');

            uitable(statsFig, ...
                'Data', tableData, ...
                'ColumnName', {'Map','Mean','Std'}, ...
                'Position',[10 10 360 220], ...
                'ColumnWidth',{150,100,100});
        end

        function plotCorrelation(obj)

            if isempty(obj.Parent.ROIs) || isempty(obj.ROIListBox.Value)
                uialert(obj.Parent.Fig, ...
                    'Select an ROI first.', ...
                    'Correlation plot', ...
                    'Icon','warning');
                return
            end

            if isempty(obj.Parent.MRFData) || isempty(obj.Parent.GTData)
                uialert(obj.Parent.Fig, ...
                    'Load both MRF and GT data to compute correlation.', ...
                    'Correlation plot', ...
                    'Icon','warning');
                return
            end

            sel = obj.ROIListBox.Value;
            if iscell(sel)
                sel = sel{1};
            end

            items = obj.ROIListBox.Items;
            idx = find(strcmp(items,sel),1);
            if isempty(idx) || idx > numel(obj.Parent.ROIs)
                return
            end

            roi = obj.Parent.ROIs(idx);

            % Get the dimensions
            mrfSize = size(obj.Parent.MRFData);
            mrfMaps = 1;
            if numel(mrfSize) >= 4
                mrfMaps = mrfSize(4);
            end

            gtSize = size(obj.Parent.GTData);
            gtMaps = 1;
            if numel(gtSize) >= 4
                gtMaps = gtSize(4);
            end

            % Determine which maps to correlate
            mrfNames = obj.MapDropdown.Items;
            gtNames = {'GT'};
            if gtMaps > 1
                for i = 1:gtMaps
                    gtNames{i} = sprintf('GT %d', i);
                end
            end

            % Create list of matches
            mrfMeanList = [];
            mrfStdList = [];
            gtMeanList = [];
            gtStdList = [];
            matchNames = {};

            % Match by keyword (T1, T2, etc)
            for mrfIdx = 1:mrfMaps
                for gtIdx = 1:gtMaps
                    if obj.Parent.mapNamesMatch(mrfNames{mrfIdx}, gtNames{gtIdx})
                        % Extract MRF
                        prevMap = obj.Parent.CurrentMap;
                        obj.Parent.CurrentMap = mrfIdx;
                        mrfImg = obj.Parent.extractImage(obj.Parent.MRFData);
                        obj.Parent.CurrentMap = prevMap;

                        % Extract GT
                        prevMap = obj.Parent.CurrentMap;
                        obj.Parent.CurrentMap = gtIdx;
                        gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                        obj.Parent.CurrentMap = prevMap;

                        % Get mask and values
                        mrfVals = obj.Parent.extractROIMask(mrfImg, roi);
                        gtVals = obj.Parent.extractROIMask(gtImg, roi);

                        if ~isempty(mrfVals) && ~isempty(gtVals)
                            mrfMeanList(end+1) = mrfIdx;
                            gtMeanList(end+1) = gtIdx;
                            matchNames{end+1} = sprintf('%s vs %s', mrfNames{mrfIdx}, gtNames{gtIdx});
                        end
                    end
                end
            end

            % If no keyword matches, use index-based fallback
            if isempty(matchNames) && mrfMaps == gtMaps
                for mapIdx = 1:mrfMaps
                    mrfMeanList(end+1) = mapIdx;
                    gtMeanList(end+1) = mapIdx;
                    matchNames{end+1} = sprintf('%s vs %s', mrfNames{mapIdx}, gtNames{mapIdx});
                end
            end

            if isempty(matchNames)
                uialert(obj.Parent.Fig, ...
                    'No matching maps found between MRF and GT.', ...
                    'Correlation plot', ...
                    'Icon','warning');
                return
            end

            % Create figure with subplots
            fig = figure('Name','ROI Correlation Plot','NumberTitle','off');
            nPlots = numel(mrfMeanList);
            nCols = ceil(sqrt(nPlots));
            nRows = ceil(nPlots / nCols);

            for plotIdx = 1:nPlots
                ax = subplot(nRows, nCols, plotIdx);

                % Extract values for this map pair
                prevMap = obj.Parent.CurrentMap;
                obj.Parent.CurrentMap = mrfMeanList(plotIdx);
                mrfImg = obj.Parent.extractImage(obj.Parent.MRFData);
                obj.Parent.CurrentMap = prevMap;

                prevMap = obj.Parent.CurrentMap;
                obj.Parent.CurrentMap = gtMeanList(plotIdx);
                gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                obj.Parent.CurrentMap = prevMap;

                % Extract pixel values
                mrfVals = obj.Parent.extractROIMask(mrfImg, roi);
                gtVals = obj.Parent.extractROIMask(gtImg, roi);

                % Scatter plot
                scatter(ax, mrfVals, gtVals, 20, 'filled', 'MarkerFaceAlpha', 0.5);
                hold(ax, 'on')

                % Linear regression
                p_coeff = polyfit(mrfVals, gtVals, 1);
                slope = p_coeff(1);
                intercept = p_coeff(2);

                xRange = [min(mrfVals), max(mrfVals)];
                yFit = slope * xRange + intercept;
                plot(ax, xRange, yFit, 'r-', 'LineWidth', 2);

                % Calculate statistics
                corr_coeff = corrcoef(mrfVals, gtVals);
                r_squared = corr_coeff(1,2)^2;

                % Labels and title
                xlabel(ax, mrfNames{mrfMeanList(plotIdx)});
                ylabel(ax, gtNames{gtMeanList(plotIdx)});
                title(ax, matchNames{plotIdx});
                grid(ax, 'on');

                % Add equation text
                eq_text = sprintf('y=%.3fx+%.3f\nR²=%.3f', slope, intercept, r_squared);
                text(ax, 0.05, 0.95, eq_text, 'Units', 'normalized', ...
                    'VerticalAlignment', 'top', 'FontSize', 10, ...
                    'BackgroundColor', 'white', 'EdgeColor', 'black');
            end
        end
    end
end
