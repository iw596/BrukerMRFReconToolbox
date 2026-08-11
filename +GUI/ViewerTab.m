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
        ClearGTButton
        ClearMRFButton
        LoadReferenceMaskButton
        ReferenceMaskInfoLabel
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

        MaskSectionLabel
        ApplyMRFMaskCheckbox
        ApplyGTMaskCheckbox

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
        AdvancedAnalysisButton
        ROIListBox
        ROIStatsMeanLabel
        ROIStatsStdLabel

        % Advanced analysis popup
        AdvancedAnalysisFig
        AdvancedTabGroup
        AdvancedStatsTab
        AdvancedCorrelationTab
        AdvancedBlandAltmanTab
        AdvancedExportTab
        AdvancedStatsButton
        AdvancedCorrelationButton
        AdvancedBlandAltmanButton
        AdvancedExportButton

        % Per-map-type manual scaling memory
        ManualScaleByMapType = struct('T1', [], 'T2', [], 'Default', [])
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

            obj.ClearGTButton = uibutton(obj.TabHandle,...
                'Text','Clear GT',...
                'Position',[320 620 100 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.clearGT(),...
                'Tooltip','Clear all loaded ground truth maps');

            obj.ClearMRFButton = uibutton(obj.TabHandle,...
                'Text','Clear MRF',...
                'Position',[440 620 100 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.clearMRF(),...
                'Tooltip','Clear all loaded MRF maps');

            obj.LoadReferenceMaskButton = uibutton(obj.TabHandle,...
                'Text','Load Ref Mask',...
                'Position',[560 620 120 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.Parent.loadReferenceMask(),...
                'Tooltip','Load a reference mask to apply to both MRF and GT');

            obj.ReferenceMaskInfoLabel = uilabel(obj.TabHandle,...
                'Position',[20 588 300 22],...
                'Text','Ref mask: none');

            % ---------------------------------------------------------
            % Map selector
            % ---------------------------------------------------------

            obj.MapLabel = uilabel(obj.TabHandle,...
                'Position',[560 620 40 25],...
                'Text','Map');

            obj.MapDropdown = uidropdown(obj.TabHandle,...
                'Position',[600 620 130 30],...
                'Items',{'Map 1'},...
                'ValueChangedFcn',...
                @(src,event)obj.changeMap());

            obj.ColorScaleModeLabel = uilabel(obj.TabHandle,...
                'Position',[740 620 80 25],...
                'Text','Scale mode');

            obj.ColorScaleModeDropdown = uidropdown(obj.TabHandle,...
                'Position',[820 620 90 30],...
                'Items',{'Auto','Manual'},...
                'Value','Auto',...
                'ValueChangedFcn',...
                @(src,event)obj.changeColorScaleMode());

            obj.ColorScaleMinLabel = uilabel(obj.TabHandle,...
                'Position',[920 620 30 25],...
                'Text','Min');

            obj.ColorScaleMinField = uieditfield(obj.TabHandle,'numeric',...
                'Position',[955 620 70 30],...
                'Value',0,...
                'Enable','off',...
                'ValueChangedFcn',...
                @(src,event)obj.applyColorScale());

            obj.ColorScaleMaxLabel = uilabel(obj.TabHandle,...
                'Position',[1035 620 35 25],...
                'Text','Max');

            obj.ColorScaleMaxField = uieditfield(obj.TabHandle,'numeric',...
                'Position',[1075 620 70 30],...
                'Value',1,...
                'Enable','off',...
                'ValueChangedFcn',...
                @(src,event)obj.applyColorScale());

            obj.ApplyMRFMaskCheckbox = uicheckbox(obj.TabHandle,...
                'Text','Apply MRF Mask',...
                'Position',[380 588 120 22],...
                'Value',false,...
                'Enable','off',...
                'ValueChangedFcn',...
                @(src,event)obj.updateDisplay());

            obj.MaskSectionLabel = uilabel(obj.TabHandle,...
                'Position',[340 588 35 22],...
                'Text','Mask');

            obj.ApplyGTMaskCheckbox = uicheckbox(obj.TabHandle,...
                'Text','Apply GT Mask',...
                'Position',[520 588 110 22],...
                'Value',false,...
                'Enable','off',...
                'ValueChangedFcn',...
                @(src,event)obj.updateDisplay());

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

            obj.AdvancedAnalysisButton = uibutton(obj.ROIPanel,...
                'Text','Advanced Analysis...',...
                'Position',[10 180 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.openAdvancedAnalysisWindow());

            obj.ROIStatsMeanLabel = uilabel(obj.ROIPanel,...
                'Position',[10 142 160 22],...
                'Text','Mean: -');

            obj.ROIStatsStdLabel = uilabel(obj.ROIPanel,...
                'Position',[10 122 160 22],...
                'Text','Std: -');

            obj.ROIListBox = uilistbox(obj.ROIPanel,...
                'Position',[10 10 160 108],...
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

            obj.refreshReferenceMaskStatus();
        end

        function resizeUI(obj, figPos)
            % Update UI element positions based on figure size
            %   figPos: Figure position [x y width height]

            width = max(figPos(3) - 20, 400);
            height = max(figPos(4) - 20, 300);

            topControlsY = height - 70;
            topControlsY = max(topControlsY, 520);

            isWideTop = width >= 1420;
            isMediumTop = width >= 1240 && width < 1420;

            primaryRowY = topControlsY;
            secondaryRowY = primaryRowY - 35;
            tertiaryRowY = secondaryRowY - 35;

            if isWideTop
                % Single-row map/scale controls with dedicated mask row.
                maskRowY = secondaryRowY;

                obj.LoadMRFButton.Position = [20 primaryRowY 120 30];
                obj.LoadGTButton.Position = [150 primaryRowY 140 30];
                obj.ClearGTButton.Position = [300 primaryRowY 95 30];
                obj.ClearMRFButton.Position = [405 primaryRowY 95 30];
                obj.LoadReferenceMaskButton.Position = [510 primaryRowY 130 30];
                obj.ReferenceMaskInfoLabel.Position = [20 maskRowY+3 300 22];

                obj.MapLabel.Position = [665 primaryRowY+5 40 25];
                obj.MapDropdown.Position = [705 primaryRowY 130 30];
                obj.ColorScaleModeLabel.Position = [845 primaryRowY+5 75 25];
                obj.ColorScaleModeDropdown.Position = [920 primaryRowY 90 30];
                obj.ColorScaleMinLabel.Position = [1020 primaryRowY+5 30 25];
                obj.ColorScaleMinField.Position = [1055 primaryRowY 75 30];
                obj.ColorScaleMaxLabel.Position = [1140 primaryRowY+5 35 25];
                obj.ColorScaleMaxField.Position = [1178 primaryRowY 75 30];
            elseif isMediumTop
                % Two-row controls: data actions on row 1, map/scale on row 2.
                maskRowY = tertiaryRowY;

                obj.LoadMRFButton.Position = [20 primaryRowY 120 30];
                obj.LoadGTButton.Position = [150 primaryRowY 140 30];
                obj.ClearGTButton.Position = [300 primaryRowY 95 30];
                obj.ClearMRFButton.Position = [405 primaryRowY 95 30];
                obj.LoadReferenceMaskButton.Position = [510 primaryRowY 130 30];
                obj.ReferenceMaskInfoLabel.Position = [20 maskRowY+3 300 22];

                obj.MapLabel.Position = [520 secondaryRowY+5 40 25];
                obj.MapDropdown.Position = [560 secondaryRowY 120 30];
                obj.ColorScaleModeLabel.Position = [690 secondaryRowY+5 75 25];
                obj.ColorScaleModeDropdown.Position = [765 secondaryRowY 90 30];
                obj.ColorScaleMinLabel.Position = [865 secondaryRowY+5 30 25];
                obj.ColorScaleMinField.Position = [900 secondaryRowY 75 30];
                obj.ColorScaleMaxLabel.Position = [985 secondaryRowY+5 35 25];
                obj.ColorScaleMaxField.Position = [1025 secondaryRowY 75 30];
            else
                % Narrow windows: stack into three rows to avoid overlap.
                maskRowY = tertiaryRowY - 35;

                obj.LoadMRFButton.Position = [20 primaryRowY 110 30];
                obj.LoadGTButton.Position = [140 primaryRowY 130 30];
                obj.ClearGTButton.Position = [280 primaryRowY 90 30];

                obj.ClearMRFButton.Position = [20 secondaryRowY 110 30];
                obj.LoadReferenceMaskButton.Position = [140 secondaryRowY 130 30];
                obj.ReferenceMaskInfoLabel.Position = [20 maskRowY+3 300 22];

                obj.MapLabel.Position = [300 secondaryRowY+5 35 25];
                obj.MapDropdown.Position = [335 secondaryRowY 115 30];
                obj.ColorScaleModeLabel.Position = [460 tertiaryRowY+5 75 25];
                obj.ColorScaleModeDropdown.Position = [535 tertiaryRowY 90 30];
                obj.ColorScaleMinLabel.Position = [635 tertiaryRowY+5 30 25];
                obj.ColorScaleMinField.Position = [670 tertiaryRowY 70 30];
                obj.ColorScaleMaxLabel.Position = [750 tertiaryRowY+5 35 25];
                obj.ColorScaleMaxField.Position = [790 tertiaryRowY 70 30];
            end

            contentTopY = maskRowY - 10;
            contentBottomY = 90;
            contentHeight = max(contentTopY - contentBottomY, 180);

            maskControlY = maskRowY + 3;
            obj.MaskSectionLabel.Position = [340 maskControlY 35 22];
            obj.ApplyMRFMaskCheckbox.Position = [380 maskControlY 120 22];
            obj.ApplyGTMaskCheckbox.Position = [520 maskControlY 110 22];

            panelWidth = 220;
            if width < 1180
                panelWidth = 200;
            end
            mainWidth = max(width - panelWidth - 40, 420);
            axisWidth = max((mainWidth - 80) / 2, 200);
            axisHeight = max(contentHeight - 20, 200);

            obj.ROIPanel.Position = [width - panelWidth - 20 90 panelWidth contentHeight];

            obj.MRFAxes.Position = [50 90 axisWidth axisHeight];
            obj.GTAxes.Position = [60 + axisWidth 90 axisWidth axisHeight];

            mainContentRight = obj.GTAxes.Position(1) + obj.GTAxes.Position(3);
            obj.SliceLabel.Position = [50 40 120 25];
            obj.SliceSlider.Position = [180 65 max(mainContentRight - 180, 220) 3];
            obj.InfoLabel.Position = [50 10 max(mainContentRight - 50, 220) 25];
        end

        % ============================================================
        % Slice, Map and Display Controls
        % ============================================================

        function changeSlice(obj)

            if isempty(obj.Parent.MRFData) && isempty(obj.Parent.GTData)
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

            if strcmp(obj.ColorScaleModeDropdown.Value,'Manual')
                obj.restoreManualScaleForCurrentMap();
            end

            obj.updateDisplay();
        end

        function changeColorScaleMode(obj)

            manual = strcmp(obj.ColorScaleModeDropdown.Value,'Manual');
            if manual
                obj.ColorScaleMinField.Enable = 'off';
                obj.ColorScaleMaxField.Enable = 'on';
                obj.ColorScaleMinField.Value = 0;
            else
                obj.ColorScaleMinField.Enable = 'off';
                obj.ColorScaleMaxField.Enable = 'off';
            end

            if manual
                obj.restoreManualScaleForCurrentMap();
            end

            obj.updateDisplay();
        end

        function applyColorScale(obj)

            if strcmp(obj.ColorScaleModeDropdown.Value,'Manual')
                obj.ColorScaleMinField.Value = 0;
                if ~isfinite(obj.ColorScaleMaxField.Value) || obj.ColorScaleMaxField.Value <= 0
                    uialert(obj.Parent.Fig, ...
                        'Colorbar maximum must be a positive finite value.', ...
                        'Invalid scale range', ...
                        'Icon','warning');
                    return
                end
                obj.storeManualScaleForCurrentMap(obj.ColorScaleMaxField.Value);
            end

            obj.updateDisplay();
        end

        function scrollSlices(obj, event)

            if isempty(obj.Parent.MRFData) && isempty(obj.Parent.GTData)
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

            mrfImg = [];
            gtImg = [];

            if ~isempty(obj.Parent.MRFData)
                mrfImg = obj.Parent.extractImage(obj.Parent.MRFData);
                if obj.ApplyMRFMaskCheckbox.Value && ~isempty(obj.Parent.MRFMask)
                    mrfImg = obj.Parent.applyMaskToImage(mrfImg, obj.getMaskSlice(obj.Parent.MRFMask));
                end
            end

            if ~isempty(obj.Parent.GTData)
                prevMap = obj.Parent.CurrentMap;
                gtMapIdx = obj.getEquivalentGTMapIndex(prevMap);
                if ~isnan(gtMapIdx)
                    obj.Parent.CurrentMap = gtMapIdx;
                    gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                    obj.Parent.CurrentMap = prevMap;
                    if obj.ApplyGTMaskCheckbox.Value && ~isempty(obj.Parent.GTMask)
                        gtImg = obj.Parent.applyMaskToImage(gtImg, obj.getMaskSlice(obj.Parent.GTMask));
                    end
                else
                    obj.Parent.CurrentMap = prevMap;
                end
            else
                gtMapIdx = NaN;
            end

            mrfMapName = obj.getMRFMapName(obj.Parent.CurrentMap);
            gtMapName = obj.getGTMapName(gtMapIdx);

            if isempty(mrfMapName)
                title(obj.MRFAxes,'MRF');
            else
                title(obj.MRFAxes,sprintf('MRF - %s (Map %d)', mrfMapName, obj.Parent.CurrentMap));
            end

            if isnan(gtMapIdx)
                title(obj.GTAxes, sprintf('Ground Truth - No matched map for %s', mrfMapName));
            elseif isempty(gtMapName)
                title(obj.GTAxes,'Ground Truth');
            else
                title(obj.GTAxes,sprintf('Ground Truth - %s (Map %d)', gtMapName, gtMapIdx));
            end

            if strcmp(obj.ColorScaleModeDropdown.Value,'Manual')
                cmin = 0;
                obj.ColorScaleMinField.Value = 0;
                cmax = obj.ColorScaleMaxField.Value;
                if ~isfinite(cmax) || cmax <= 0
                    [~, cmax] = obj.computeSharedColorLimits(mrfImg, gtImg);
                    cmin = 0;
                    obj.ColorScaleMaxField.Value = cmax;
                    obj.storeManualScaleForCurrentMap(cmax);
                end
            else
                [cmin, cmax] = obj.computeSharedColorLimits(mrfImg, gtImg);
                if cmin < cmax
                    obj.ColorScaleMinField.Value = cmin;
                    obj.ColorScaleMaxField.Value = cmax;
                end
            end

            sharedMap = obj.selectRecommendedColormap(mrfMapName, gtMapName);

            % ---------------------------------------------------------
            % MRF
            % ---------------------------------------------------------

            if ~isempty(mrfImg)

                imagesc(obj.MRFAxes,mrfImg);

                axis(obj.MRFAxes,'image');

                colormap(obj.MRFAxes,sharedMap);

                if cmin < cmax
                    caxis(obj.MRFAxes,[cmin cmax]);
                end

                colorbar(obj.MRFAxes);

            end

            % ---------------------------------------------------------
            % Ground Truth
            % ---------------------------------------------------------

            if ~isempty(gtImg)

                imagesc(obj.GTAxes,gtImg);

                axis(obj.GTAxes,'image');

                colormap(obj.GTAxes,sharedMap);

                if cmin < cmax
                    caxis(obj.GTAxes,[cmin cmax]);
                end

                colorbar(obj.GTAxes);

            end

            obj.Parent.drawROIs();
            obj.Parent.updateInfo();
            obj.updateROIStats();
        end

        function msk = getMaskSlice(obj, mask)
            % Extract the 2D mask slice matching the current slice index

            msk = [];

            if isempty(mask)
                return
            end

            sz = size(mask);

            if numel(sz) >= 3
                sliceIdx = min(max(round(obj.Parent.CurrentSlice),1), sz(3));
                msk = logical(mask(:,:,sliceIdx));
            else
                msk = logical(mask);
            end
        end

        function gtMapIdx = getEquivalentGTMapIndex(obj, mrfMapIdx)

            gtMapIdx = NaN;

            if isempty(obj.Parent.GTData)
                return
            end

            gtSz = size(obj.Parent.GTData);
            if numel(gtSz) < 4
                gtMaps = 1;
            else
                gtMaps = gtSz(4);
            end

            if gtMaps <= 1
                gtMapIdx = 1;
                return
            end

            fallbackIdx = min(max(round(mrfMapIdx),1),gtMaps);

            if isempty(obj.Parent.MapNames) || mrfMapIdx > numel(obj.Parent.MapNames)
                gtMapIdx = fallbackIdx;
                return
            end

            mrfName = obj.Parent.MapNames{mrfMapIdx};

            if ~isprop(obj.Parent,'GTMapNames') || isempty(obj.Parent.GTMapNames)
                gtMapIdx = fallbackIdx;
                return
            end

            gtNames = obj.Parent.GTMapNames;
            matchIdx = [];
            for k = 1:min(numel(gtNames),gtMaps)
                if obj.Parent.mapNamesMatch(mrfName, gtNames{k})
                    matchIdx = k;
                    break
                end
            end

            if ~isempty(matchIdx)
                gtMapIdx = matchIdx;
                return
            end

            % Explicitly mark unmatched map names (e.g., M0 with no GT M0)
            % so the GT panel can be blanked instead of showing wrong maps.
            gtMapIdx = NaN;
        end

        function mapName = getMRFMapName(obj, mapIdx)

            mapName = '';

            if isempty(obj.Parent.MRFData)
                return
            end

            idx = max(1,round(mapIdx));

            if ~isempty(obj.Parent.MapNames) && idx <= numel(obj.Parent.MapNames)
                mapName = obj.Parent.MapNames{idx};
                return
            end

            if ~isempty(obj.MapDropdown) && ~isempty(obj.MapDropdown.Items) && idx <= numel(obj.MapDropdown.Items)
                mapName = obj.MapDropdown.Items{idx};
                return
            end

            mapName = sprintf('Map %d', idx);
        end

        function mapName = getGTMapName(obj, mapIdx)

            mapName = '';

            if isempty(obj.Parent.GTData)
                return
            end

            if isnan(mapIdx)
                return
            end

            idx = max(1,round(mapIdx));

            if isprop(obj.Parent,'GTMapNames') && ~isempty(obj.Parent.GTMapNames) && idx <= numel(obj.Parent.GTMapNames)
                mapName = obj.Parent.GTMapNames{idx};
                return
            end

            gtSz = size(obj.Parent.GTData);
            if numel(gtSz) < 4 || gtSz(4) <= 1
                mapName = 'GT';
            else
                mapName = sprintf('GT %d', idx);
            end
        end

        function cmap = selectRecommendedColormap(obj, mrfMapName, gtMapName)
            % Use MRM-recommended colormaps for relaxometry map display.

            mapName = '';
            if ~isempty(mrfMapName)
                mapName = mrfMapName;
            elseif ~isempty(gtMapName)
                mapName = gtMapName;
            end

            mapNameLower = lower(string(mapName));

            if contains(mapNameLower, "t1")
                cmap = obj.safeGetCmp('T1', 256, 1);
                return
            end

            if contains(mapNameLower, "t2")
                cmap = obj.safeGetCmp('T2', 256, 1);
                return
            end

            if contains(mapNameLower, "b1")
                cmap = obj.safeGetCmp('blue_red', 256, 0);
                return
            end

            cmap = parula(256);
        end

        function cmap = safeGetCmp(~, cmpName, nColors, useLogRemap)
            % Resolve custom colormap helper and fallback safely if missing.
            try
                if isempty(which('get_cmp'))
                    error('get_cmp is not on MATLAB path.');
                end
                cmap = get_cmp(cmpName, nColors, useLogRemap);
            catch
                cmap = parula(nColors);
            end
        end

        function [cmin, cmax] = computeSharedColorLimits(~, mrfImg, gtImg)

            combinedVals = [];

            if ~isempty(mrfImg)
                mVals = mrfImg(isfinite(mrfImg));
                if ~isempty(mVals)
                    combinedVals = [combinedVals; mVals(:)]; %#ok<AGROW>
                end
            end

            if ~isempty(gtImg)
                gVals = gtImg(isfinite(gtImg));
                if ~isempty(gVals)
                    combinedVals = [combinedVals; gVals(:)]; %#ok<AGROW>
                end
            end

            if isempty(combinedVals)
                cmin = 0;
                cmax = 1;
                return
            end

            cmin = 0;
            cmax = double(max(combinedVals));

            if ~isfinite(cmax) || cmax <= 0
                cmax = 1;
            end

            if ~(cmin < cmax)
                cmax = cmin + 1;
            end
        end

        function restoreManualScaleForCurrentMap(obj)
            key = obj.getCurrentMapScaleKey();
            if isfield(obj.ManualScaleByMapType, key)
                storedMax = obj.ManualScaleByMapType.(key);
            else
                storedMax = [];
            end

            if isempty(storedMax) || ~isfinite(storedMax) || storedMax <= 0
                [~, autoMax] = obj.computeAutoScaleFromCurrentSelection();
                if ~isfinite(autoMax) || autoMax <= 0
                    autoMax = 1;
                end
                storedMax = autoMax;
                obj.ManualScaleByMapType.(key) = storedMax;
            end

            obj.ColorScaleMinField.Value = 0;
            obj.ColorScaleMaxField.Value = storedMax;
        end

        function storeManualScaleForCurrentMap(obj, maxVal)
            if ~isfinite(maxVal) || maxVal <= 0
                return
            end
            key = obj.getCurrentMapScaleKey();
            obj.ManualScaleByMapType.(key) = double(maxVal);
        end

        function key = getCurrentMapScaleKey(obj)
            mapName = obj.getMRFMapName(obj.Parent.CurrentMap);
            if isempty(mapName) && ~isempty(obj.Parent.GTData)
                gtMapIdx = obj.getEquivalentGTMapIndex(obj.Parent.CurrentMap);
                if ~isnan(gtMapIdx)
                    mapName = obj.getGTMapName(gtMapIdx);
                end
            end

            mapNameLower = lower(string(mapName));
            if contains(mapNameLower, "t1")
                key = 'T1';
            elseif contains(mapNameLower, "t2")
                key = 'T2';
            else
                key = 'Default';
            end
        end

        function [cmin, cmax] = computeAutoScaleFromCurrentSelection(obj)
            mrfImg = [];
            gtImg = [];

            if ~isempty(obj.Parent.MRFData)
                mrfImg = obj.Parent.extractImage(obj.Parent.MRFData);
                if obj.ApplyMRFMaskCheckbox.Value && ~isempty(obj.Parent.MRFMask)
                    mrfImg = obj.Parent.applyMaskToImage(mrfImg, obj.getMaskSlice(obj.Parent.MRFMask));
                end
            end

            if ~isempty(obj.Parent.GTData)
                prevMap = obj.Parent.CurrentMap;
                gtMapIdx = obj.getEquivalentGTMapIndex(prevMap);
                if ~isnan(gtMapIdx)
                    obj.Parent.CurrentMap = gtMapIdx;
                    gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                    obj.Parent.CurrentMap = prevMap;
                    if obj.ApplyGTMaskCheckbox.Value && ~isempty(obj.Parent.GTMask)
                        gtImg = obj.Parent.applyMaskToImage(gtImg, obj.getMaskSlice(obj.Parent.GTMask));
                    end
                else
                    obj.Parent.CurrentMap = prevMap;
                end
            end

            [cmin, cmax] = obj.computeSharedColorLimits(mrfImg, gtImg);
        end

        function configureSliceSlider(obj)

            activeData = [];
            if ~isempty(obj.Parent.MRFData)
                activeData = obj.Parent.MRFData;
            elseif ~isempty(obj.Parent.GTData)
                activeData = obj.Parent.GTData;
            end

            if isempty(activeData)
                obj.SliceSlider.Limits = [1 2];
                obj.SliceSlider.Value = 1;
                obj.SliceSlider.Enable = 'off';
                obj.SliceLabel.Text = 'Slice: 1';
                return
            end

            sz = size(activeData);

            if numel(sz) < 3
                nSlices = 1;
            else
                nSlices = sz(3);
            end

            % IMPORTANT: ensure valid range
            if ~isfinite(nSlices) || isempty(nSlices)
                nSlices = 1;
            end
            nSlices = max(round(double(nSlices)),1);

            if nSlices <= 1
                obj.SliceSlider.Limits = [1 2];
                obj.SliceSlider.Value = 1;
                obj.SliceSlider.Enable = 'off';
                obj.Parent.CurrentSlice = 1;
            else
                obj.SliceSlider.Limits = [1 nSlices];
                centerSlice = ceil(nSlices / 2);
                obj.Parent.CurrentSlice = centerSlice;
                obj.SliceSlider.Value = centerSlice;
                obj.SliceSlider.Enable = 'on';
            end
            obj.SliceLabel.Text = sprintf('Slice: %d', obj.Parent.CurrentSlice);

            % Enable mask checkboxes if masks are present
            if ~isempty(obj.Parent.MRFMask)
                obj.ApplyMRFMaskCheckbox.Enable = 'on';
            else
                obj.ApplyMRFMaskCheckbox.Enable = 'off';
                obj.ApplyMRFMaskCheckbox.Value = false;
            end

            if ~isempty(obj.Parent.GTMask)
                obj.ApplyGTMaskCheckbox.Enable = 'on';
            else
                obj.ApplyGTMaskCheckbox.Enable = 'off';
                obj.ApplyGTMaskCheckbox.Value = false;
            end

        end

        function configureMapDropdown(obj)

            useMRFNames = ~isempty(obj.Parent.MRFData);

            if useMRFNames
                dataForMaps = obj.Parent.MRFData;
                preferredNames = obj.Parent.MapNames;
            elseif ~isempty(obj.Parent.GTData)
                dataForMaps = obj.Parent.GTData;
                preferredNames = obj.Parent.GTMapNames;
            else
                obj.MapDropdown.Items = {'Map 1'};
                obj.MapDropdown.Value = 'Map 1';
                obj.Parent.CurrentMap = 1;
                return
            end

            sz = size(dataForMaps);
            if numel(sz) < 4
                nMaps = 1;
            else
                nMaps = sz(4);
            end

            if ~isempty(preferredNames) && numel(preferredNames) >= nMaps
                items = preferredNames(1:nMaps);
            else
                items = cell(1,nMaps);
                for k = 1:nMaps
                    items{k} = sprintf('Map %d',k);
                end
            end

            obj.MapDropdown.Items = items;

            currentIdx = min(max(round(obj.Parent.CurrentMap),1), nMaps);
            obj.Parent.CurrentMap = currentIdx;
            obj.MapDropdown.Value = items{currentIdx};

        end

        function refreshReferenceMaskStatus(obj)
            if isempty(obj.Parent) || ~isvalid(obj.Parent)
                return
            end

            if isempty(obj.Parent.ReferenceMask)
                obj.ReferenceMaskInfoLabel.Text = 'Ref mask: none';
                return
            end

            sz = size(obj.Parent.ReferenceMask);
            szText = strjoin(arrayfun(@num2str, sz, 'UniformOutput', false), ' x ');

            labelText = ['Ref mask: loaded (' szText ')'];
            if isprop(obj.Parent, 'ReferenceMaskPath') && ~isempty(obj.Parent.ReferenceMaskPath)
                [~,name,ext] = fileparts(obj.Parent.ReferenceMaskPath);
                labelText = ['Ref mask: ' name ext ' (' szText ')'];
            end
            obj.ReferenceMaskInfoLabel.Text = labelText;
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

        function openAdvancedAnalysisWindow(obj, targetTab)
            if nargin < 2 || isempty(targetTab)
                targetTab = 'ROI Stats';
            end

            createNew = isempty(obj.AdvancedAnalysisFig) || ~isvalid(obj.AdvancedAnalysisFig);

            if createNew
                obj.AdvancedAnalysisFig = uifigure( ...
                    'Name', 'Advanced ROI Analysis', ...
                    'Position', [220 180 540 360]);

                obj.AdvancedAnalysisFig.CloseRequestFcn = ...
                    @(src,event)obj.closeAdvancedAnalysisWindow(src);

                obj.AdvancedAnalysisFig.SizeChangedFcn = ...
                    @(src,event)obj.layoutAdvancedAnalysisWindow();

                obj.AdvancedTabGroup = uitabgroup(obj.AdvancedAnalysisFig, ...
                    'Position', [10 10 520 340]);

                obj.AdvancedStatsTab = uitab(obj.AdvancedTabGroup, 'Title', 'ROI Stats');
                obj.AdvancedCorrelationTab = uitab(obj.AdvancedTabGroup, 'Title', 'Correlation');
                obj.AdvancedBlandAltmanTab = uitab(obj.AdvancedTabGroup, 'Title', 'Bland-Altman');
                obj.AdvancedExportTab = uitab(obj.AdvancedTabGroup, 'Title', 'Export');

                obj.AdvancedStatsButton = uibutton(obj.AdvancedStatsTab, ...
                    'Text', 'Show All Map Stats', ...
                    'ButtonPushedFcn', @(src,event)obj.showAllMapStats());

                obj.AdvancedCorrelationButton = uibutton(obj.AdvancedCorrelationTab, ...
                    'Text', 'Open Correlation Plot', ...
                    'ButtonPushedFcn', @(src,event)obj.plotCorrelation());

                obj.AdvancedBlandAltmanButton = uibutton(obj.AdvancedBlandAltmanTab, ...
                    'Text', 'Open Bland-Altman Plot', ...
                    'ButtonPushedFcn', @(src,event)obj.plotBlandAltman());

                obj.AdvancedExportButton = uibutton(obj.AdvancedExportTab, ...
                    'Text', 'Export ROI CSV', ...
                    'ButtonPushedFcn', @(src,event)obj.Parent.exportROIsCSV());

                obj.layoutAdvancedAnalysisWindow();
            end

            tabTitles = { ...
                obj.AdvancedStatsTab.Title, ...
                obj.AdvancedCorrelationTab.Title, ...
                obj.AdvancedBlandAltmanTab.Title, ...
                obj.AdvancedExportTab.Title};
            tabHandles = { ...
                obj.AdvancedStatsTab, ...
                obj.AdvancedCorrelationTab, ...
                obj.AdvancedBlandAltmanTab, ...
                obj.AdvancedExportTab};

            tabIdx = find(strcmpi(tabTitles, targetTab), 1);
            if isempty(tabIdx)
                tabIdx = 1;
            end
            obj.AdvancedTabGroup.SelectedTab = tabHandles{tabIdx};

            obj.Parent.restoreFigureFocus();
            try
                figure(obj.AdvancedAnalysisFig);
            catch
            end
        end

        function layoutAdvancedAnalysisWindow(obj)
            if isempty(obj.AdvancedAnalysisFig) || ~isvalid(obj.AdvancedAnalysisFig)
                return
            end

            figPos = obj.AdvancedAnalysisFig.Position;
            panelW = max(figPos(3) - 20, 280);
            panelH = max(figPos(4) - 20, 180);
            obj.AdvancedTabGroup.Position = [10 10 panelW panelH];

            btnW = 220;
            btnH = 34;
            btnX = max((panelW - btnW) / 2, 20);
            btnY = max((panelH - btnH) / 2, 40);

            if ~isempty(obj.AdvancedStatsButton) && isvalid(obj.AdvancedStatsButton)
                obj.AdvancedStatsButton.Position = [btnX btnY btnW btnH];
            end

            if ~isempty(obj.AdvancedCorrelationButton) && isvalid(obj.AdvancedCorrelationButton)
                obj.AdvancedCorrelationButton.Position = [btnX btnY btnW btnH];
            end

            if ~isempty(obj.AdvancedBlandAltmanButton) && isvalid(obj.AdvancedBlandAltmanButton)
                obj.AdvancedBlandAltmanButton.Position = [btnX btnY btnW btnH];
            end

            if ~isempty(obj.AdvancedExportButton) && isvalid(obj.AdvancedExportButton)
                obj.AdvancedExportButton.Position = [btnX btnY btnW btnH];
            end
        end

        function closeAdvancedAnalysisWindow(obj, figHandle)
            if nargin < 2 || isempty(figHandle)
                figHandle = obj.AdvancedAnalysisFig;
            end

            if ~isempty(figHandle) && isvalid(figHandle)
                delete(figHandle);
            end

            obj.AdvancedAnalysisFig = [];
            obj.AdvancedTabGroup = [];
            obj.AdvancedStatsTab = [];
            obj.AdvancedCorrelationTab = [];
            obj.AdvancedBlandAltmanTab = [];
            obj.AdvancedExportTab = [];
            obj.AdvancedStatsButton = [];
            obj.AdvancedCorrelationButton = [];
            obj.AdvancedBlandAltmanButton = [];
            obj.AdvancedExportButton = [];
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
            if isempty(obj.Parent.ROIs)
                uialert(obj.Parent.Fig, ...
                    'Draw at least one ROI before running correlation.', ...
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

            modeChoice = questdlg( ...
                ['Choose correlation mode:' newline ...
                 '• ROI means: one point per ROI, with MRF std error bars' newline ...
                 '• Pooled pixels: all pixels from all ROIs'], ...
                'Correlation mode', ...
                'ROI means', 'Pooled pixels', 'Cancel', ...
                'ROI means');

            if isempty(modeChoice) || strcmpi(modeChoice, 'Cancel')
                return
            end

            useROIMeans = strcmpi(modeChoice, 'ROI means');

            mrfT1Idx = obj.findMapIndexForMetric('mrf', 't1');
            gtT1Idx  = obj.findMapIndexForMetric('gt',  't1', mrfT1Idx);
            mrfT2Idx = obj.findMapIndexForMetric('mrf', 't2');
            gtT2Idx  = obj.findMapIndexForMetric('gt',  't2', mrfT2Idx);

            hasT1 = ~isnan(mrfT1Idx) && ~isnan(gtT1Idx);
            hasT2 = ~isnan(mrfT2Idx) && ~isnan(gtT2Idx);

            if ~hasT1 && ~hasT2
                uialert(obj.Parent.Fig, ...
                    'Could not find matching T1/T2 maps in both MRF and GT data.', ...
                    'Correlation plot', ...
                    'Icon','warning');
                return
            end

            if hasT1
                if useROIMeans
                    [xT1, yT1, yErrT1] = obj.collectROIMeanPairs(mrfT1Idx, gtT1Idx);
                else
                    [xT1, yT1] = obj.collectROIPixelPairs(mrfT1Idx, gtT1Idx);
                    yErrT1 = [];
                end
            else
                xT1 = [];
                yT1 = [];
                yErrT1 = [];
            end

            if hasT2
                if useROIMeans
                    [xT2, yT2, yErrT2] = obj.collectROIMeanPairs(mrfT2Idx, gtT2Idx);
                else
                    [xT2, yT2] = obj.collectROIPixelPairs(mrfT2Idx, gtT2Idx);
                    yErrT2 = [];
                end
            else
                xT2 = [];
                yT2 = [];
                yErrT2 = [];
            end

            validT1 = numel(xT1) >= 2;
            validT2 = numel(xT2) >= 2;

            if ~validT1 && ~validT2
                uialert(obj.Parent.Fig, ...
                    'Need at least 2 ROI mean pairs for regression (after NaN filtering).', ...
                    'Correlation plot', ...
                    'Icon','warning');
                return
            end
            if validT1
                obj.plotRegressionFigure(xT1, yT1, yErrT1, 'T1', modeChoice);
            end

            if validT2
                obj.plotRegressionFigure(xT2, yT2, yErrT2, 'T2', modeChoice);
            end
        end

        function plotBlandAltman(obj)
            if isempty(obj.Parent.ROIs)
                uialert(obj.Parent.Fig, ...
                    'Draw at least one ROI before running Bland-Altman analysis.', ...
                    'Bland-Altman plot', ...
                    'Icon','warning');
                return
            end

            if isempty(obj.Parent.MRFData) || isempty(obj.Parent.GTData)
                uialert(obj.Parent.Fig, ...
                    'Load both MRF and GT data to compute Bland-Altman plots.', ...
                    'Bland-Altman plot', ...
                    'Icon','warning');
                return
            end

            modeChoice = questdlg( ...
                ['Choose Bland-Altman mode:' newline ...
                 '• ROI means: one point per ROI' newline ...
                 '• Pooled pixels: all pixels from all ROIs'], ...
                'Bland-Altman mode', ...
                'ROI means', 'Pooled pixels', 'Cancel', ...
                'ROI means');

            if isempty(modeChoice) || strcmpi(modeChoice, 'Cancel')
                return
            end

            useROIMeans = strcmpi(modeChoice, 'ROI means');

            mrfT1Idx = obj.findMapIndexForMetric('mrf', 't1');
            gtT1Idx  = obj.findMapIndexForMetric('gt',  't1', mrfT1Idx);
            mrfT2Idx = obj.findMapIndexForMetric('mrf', 't2');
            gtT2Idx  = obj.findMapIndexForMetric('gt',  't2', mrfT2Idx);

            hasT1 = ~isnan(mrfT1Idx) && ~isnan(gtT1Idx);
            hasT2 = ~isnan(mrfT2Idx) && ~isnan(gtT2Idx);

            if ~hasT1 && ~hasT2
                uialert(obj.Parent.Fig, ...
                    'Could not find matching T1/T2 maps in both MRF and GT data.', ...
                    'Bland-Altman plot', ...
                    'Icon','warning');
                return
            end

            if hasT1
                if useROIMeans
                    [gtT1, mrfT1] = obj.collectROIMeanPairs(mrfT1Idx, gtT1Idx);
                else
                    [gtT1, mrfT1] = obj.collectROIPixelPairs(mrfT1Idx, gtT1Idx);
                end
            else
                gtT1 = [];
                mrfT1 = [];
            end

            if hasT2
                if useROIMeans
                    [gtT2, mrfT2] = obj.collectROIMeanPairs(mrfT2Idx, gtT2Idx);
                else
                    [gtT2, mrfT2] = obj.collectROIPixelPairs(mrfT2Idx, gtT2Idx);
                end
            else
                gtT2 = [];
                mrfT2 = [];
            end

            validT1 = numel(gtT1) >= 2 && numel(mrfT1) >= 2;
            validT2 = numel(gtT2) >= 2 && numel(mrfT2) >= 2;

            if ~validT1 && ~validT2
                uialert(obj.Parent.Fig, ...
                    'Need at least 2 valid paired points for Bland-Altman analysis.', ...
                    'Bland-Altman plot', ...
                    'Icon','warning');
                return
            end

            if validT1
                obj.plotBlandAltmanFigure(gtT1, mrfT1, 'T1', modeChoice);
            end

            if validT2
                obj.plotBlandAltmanFigure(gtT2, mrfT2, 'T2', modeChoice);
            end
        end

        function mapIdx = findMapIndexForMetric(obj, datasetType, metric, mrfFallbackIdx)
            if nargin < 4
                mrfFallbackIdx = NaN;
            end

            mapIdx = NaN;

            switch lower(datasetType)
                case 'mrf'
                    if isempty(obj.Parent.MRFData)
                        return
                    end
                    names = obj.Parent.MapNames;
                    nMaps = size(obj.Parent.MRFData, 4);
                    if ndims(obj.Parent.MRFData) < 4
                        nMaps = 1;
                    end
                case 'gt'
                    if isempty(obj.Parent.GTData)
                        return
                    end
                    names = obj.Parent.GTMapNames;
                    nMaps = size(obj.Parent.GTData, 4);
                    if ndims(obj.Parent.GTData) < 4
                        nMaps = 1;
                    end
                otherwise
                    return
            end

            if isempty(names)
                names = cell(1, nMaps);
                for k = 1:nMaps
                    names{k} = sprintf('Map %d', k);
                end
            end

            names = names(:)';

            for k = 1:min(numel(names), nMaps)
                n = lower(string(names{k}));
                switch lower(metric)
                    case 't1'
                        if contains(n, "t1") && ~contains(n, "t1rho")
                            mapIdx = k;
                            return
                        end
                    case 't2'
                        if contains(n, "t2")
                            mapIdx = k;
                            return
                        end
                end
            end

            if strcmpi(datasetType, 'gt') && ~isnan(mrfFallbackIdx)
                mapIdx = obj.getEquivalentGTMapIndex(mrfFallbackIdx);
            end
        end

        function [gtMeans, mrfMeans, mrfStds] = collectROIMeanPairs(obj, mrfMapIdx, gtMapIdx)
            gtMeans = [];
            mrfMeans = [];
            mrfStds = [];

            prevSlice = obj.Parent.CurrentSlice;
            prevMap = obj.Parent.CurrentMap;
            cleanupState = onCleanup(@()obj.restoreSliceMapState(prevSlice, prevMap)); %#ok<NASGU>

            for roiIdx = 1:numel(obj.Parent.ROIs)
                roi = obj.Parent.ROIs(roiIdx);

                obj.Parent.CurrentSlice = roi.Slice;

                obj.Parent.CurrentMap = mrfMapIdx;
                mrfImg = obj.Parent.extractImage(obj.Parent.MRFData);
                mrfVals = obj.Parent.extractROIMask(mrfImg, roi);
                mrfMean = mean(mrfVals(:), 'omitnan');
                mrfStd = std(mrfVals(:), 'omitnan');

                obj.Parent.CurrentMap = gtMapIdx;
                gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                gtVals = obj.Parent.extractROIMask(gtImg, roi);
                gtMean = mean(gtVals(:), 'omitnan');

                if ~isnan(mrfMean) && ~isnan(gtMean)
                    gtMeans(end+1,1) = gtMean; %#ok<AGROW>
                    mrfMeans(end+1,1) = mrfMean; %#ok<AGROW>
                    if isnan(mrfStd)
                        mrfStd = 0;
                    end
                    mrfStds(end+1,1) = mrfStd; %#ok<AGROW>
                end
            end
        end

        function [gtPixels, mrfPixels] = collectROIPixelPairs(obj, mrfMapIdx, gtMapIdx)
            gtPixels = [];
            mrfPixels = [];

            prevSlice = obj.Parent.CurrentSlice;
            prevMap = obj.Parent.CurrentMap;
            cleanupState = onCleanup(@()obj.restoreSliceMapState(prevSlice, prevMap)); %#ok<NASGU>

            for roiIdx = 1:numel(obj.Parent.ROIs)
                roi = obj.Parent.ROIs(roiIdx);

                obj.Parent.CurrentSlice = roi.Slice;

                obj.Parent.CurrentMap = mrfMapIdx;
                mrfImg = obj.Parent.extractImage(obj.Parent.MRFData);
                mrfVals = obj.Parent.extractROIMask(mrfImg, roi);

                obj.Parent.CurrentMap = gtMapIdx;
                gtImg = obj.Parent.extractImage(obj.Parent.GTData);
                gtVals = obj.Parent.extractROIMask(gtImg, roi);

                pairCount = min(numel(mrfVals), numel(gtVals));
                if pairCount <= 0
                    continue
                end

                mrfVals = mrfVals(1:pairCount);
                gtVals = gtVals(1:pairCount);
                validMask = ~(isnan(mrfVals) | isnan(gtVals));

                if any(validMask)
                    gtPixels = [gtPixels; gtVals(validMask)]; %#ok<AGROW>
                    mrfPixels = [mrfPixels; mrfVals(validMask)]; %#ok<AGROW>
                end
            end
        end

        function restoreSliceMapState(obj, sliceIdx, mapIdx)
            obj.Parent.CurrentSlice = sliceIdx;
            obj.Parent.CurrentMap = mapIdx;
        end

        function plotBlandAltmanFigure(~, gtVals, mrfVals, metricName, modeLabel)
            avgVals = (gtVals + mrfVals) / 2;
            diffVals = mrfVals - gtVals;

            bias = mean(diffVals, 'omitnan');
            sdDiff = std(diffVals, 'omitnan');
            loaUpper = bias + 1.96 * sdDiff;
            loaLower = bias - 1.96 * sdDiff;

            fig = figure( ...
                'Name', sprintf('%s Bland-Altman: MRF - GT', upper(metricName)), ...
                'NumberTitle', 'off', ...
                'Color', 'w', ...
                'Units', 'pixels', ...
                'Position', [200 140 760 640]);

            ax = axes('Parent', fig);
            hold(ax, 'on');
            box(ax, 'on');
            grid(ax, 'on');
            ax.LineWidth = 1.2;
            ax.FontSize = 12;
            ax.FontName = 'Arial';

            scatter(ax, avgVals, diffVals, 32, ...
                'MarkerFaceColor', [0.2 0.45 0.85], ...
                'MarkerEdgeColor', [0.05 0.2 0.45], ...
                'MarkerFaceAlpha', 0.5, ...
                'MarkerEdgeAlpha', 0.6);

            xMin = min(avgVals);
            xMax = max(avgVals);
            if xMin == xMax
                xMin = xMin - 0.5;
                xMax = xMax + 0.5;
            end

            plot(ax, [xMin xMax], [bias bias], '-', 'Color', [0.75 0.1 0.1], 'LineWidth', 2.0);
            plot(ax, [xMin xMax], [loaUpper loaUpper], '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.5);
            plot(ax, [xMin xMax], [loaLower loaLower], '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.5);

            xlabel(ax, sprintf('Mean of GT and MRF %s', upper(metricName)), 'FontWeight', 'bold');
            ylabel(ax, sprintf('Difference (MRF - GT) %s', upper(metricName)), 'FontWeight', 'bold');
            title(ax, sprintf('%s Bland-Altman (%s)', upper(metricName), modeLabel), ...
                'FontWeight', 'bold', 'FontSize', 14);

            annotationText = sprintf(['Bias = %.4g' newline ...
                'Upper LoA = %.4g' newline ...
                'Lower LoA = %.4g' newline ...
                'N = %d'], bias, loaUpper, loaLower, numel(diffVals));
            text(ax, 0.04, 0.96, annotationText, ...
                'Units', 'normalized', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 11, ...
                'BackgroundColor', 'white', ...
                'EdgeColor', [0.7 0.7 0.7], ...
                'Margin', 6);

            axis(ax, 'tight');
        end

        function plotRegressionFigure(~, xVals, yVals, yErrVals, metricName, modeLabel)
            fig = figure( ...
                'Name', sprintf('%s Correlation: GT vs MRF', upper(metricName)), ...
                'NumberTitle', 'off', ...
                'Color', 'w', ...
                'Units', 'pixels', ...
                'Position', [160 120 760 640]);

            ax = axes('Parent', fig);
            hold(ax, 'on');
            box(ax, 'on');
            grid(ax, 'on');
            ax.LineWidth = 1.2;
            ax.FontSize = 12;
            ax.FontName = 'Arial';

            if ~isempty(yErrVals)
                errorbar(ax, xVals, yVals, yErrVals, ...
                    'o', ...
                    'MarkerSize', 6, ...
                    'LineWidth', 1.1, ...
                    'CapSize', 8, ...
                    'Color', [0.1 0.35 0.7], ...
                    'MarkerEdgeColor', [0.1 0.35 0.7], ...
                    'MarkerFaceColor', [0.45 0.67 0.95]);
            else
                scatter(ax, xVals, yVals, 26, ...
                    'MarkerFaceColor', [0.2 0.45 0.85], ...
                    'MarkerEdgeColor', [0.05 0.2 0.45], ...
                    'MarkerFaceAlpha', 0.45, ...
                    'MarkerEdgeAlpha', 0.6);
            end

            hold(ax, 'on');

            fitCoeffs = polyfit(xVals, yVals, 1);
            slope = fitCoeffs(1);
            intercept = fitCoeffs(2);

            xMin = min(xVals);
            xMax = max(xVals);
            if xMin == xMax
                xFit = [xMin - 0.5, xMax + 0.5];
            else
                xFit = linspace(xMin, xMax, 100);
            end
            yFit = slope * xFit + intercept;
            plot(ax, xFit, yFit, '-', 'Color', [0.8 0.1 0.1], 'LineWidth', 2.2);

            minVal = min([xVals(:); yVals(:)]);
            maxVal = max([xVals(:); yVals(:)]);
            if minVal < maxVal
                plot(ax, [minVal maxVal], [minVal maxVal], '--', ...
                    'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
            end

            rMat = corrcoef(xVals, yVals);
            r2 = rMat(1,2)^2;

            xlabel(ax, sprintf('Ground Truth %s', upper(metricName)), 'FontWeight', 'bold');
            ylabel(ax, sprintf('MRF %s', upper(metricName)), 'FontWeight', 'bold');
            title(ax, sprintf('%s correlation (%s)', upper(metricName), modeLabel), ...
                'FontWeight', 'bold', 'FontSize', 14);

            annotationText = sprintf('MRF = %.4g · GT + %.4g\nR^2 = %.4f\nN = %d', ...
                slope, intercept, r2, numel(xVals));
            text(ax, 0.04, 0.96, annotationText, ...
                'Units', 'normalized', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 11, ...
                'BackgroundColor', 'white', ...
                'EdgeColor', [0.7 0.7 0.7], ...
                'Margin', 6);

            axis(ax, 'tight');
        end
    end
end
