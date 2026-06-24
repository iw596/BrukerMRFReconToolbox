classdef MRFViewer < handle
    % MRFViewer - Main MRF/GT image viewer with ROI analysis
    %   Manages tab-based UI, data loading, ROI analysis, and display
    %
    %   This class is refactored to use separate tab classes:
    %   - ViewerTab: Handles the Viewer tab UI and display
    %   - ReconstructionTab: Handles the Reconstruction tab UI
    %   - FlipAngleGenerationTab: Handles flip angle generation/loading
    %
    %   MRFViewer retains shared data, ROI file I/O, and helper methods

    properties

        % GUI
        Fig
        TabGroup
        ViewerTabObj    % ViewerTab instance
        ReconTabObj     % ReconstructionTab instance
        FlipAngleGenTabObj % FlipAngleGenerationTab instance
        DictionaryTabObj % DictionaryTab instance
        CRBOptTabObj    % CRBOptimisationTab instance

        % Data
        MRFData = []
        GTData = []
        GTMapNames = {}
        MRFMask = []
        GTMask = []
        FlipAngles = []
        LastLoadDir = ''

        CurrentSlice = 1
        CurrentMap = 1

        MapNames = {}

        % ROI
        ROIs = []

        % Colormaps
        t1cmp = [];
        t2cmp = [];

    end

    methods

        function app = MRFViewer()
            % Initialize MRFViewer application
            app.createUI();
        end

        %% ============================================================
        % UI Creation and Layout
        %% ============================================================

        function createUI(app)
            % Create main figure and tabs, initialize tab objects

            app.Fig = uifigure( ...
                'Name','MRF Viewer', ...
                'Position',[100 100 1300 750]);

            app.Fig.WindowScrollWheelFcn = ...
                @(src,event)app.scrollSlices(event);

            app.Fig.SizeChangedFcn = ...
                @(src,event)app.resizeUI();

            app.TabGroup = uitabgroup(app.Fig, ...
                'Position',[10 10 1280 700]);

            % Create tab handles
            viewerTabHandle = uitab(app.TabGroup, 'Title','Viewer');
            reconTabHandle = uitab(app.TabGroup, 'Title','Reconstruction');
            faGenTabHandle = uitab(app.TabGroup, 'Title','Flip Angle Generation');
            dictionaryTabHandle = uitab(app.TabGroup,"Title","Dictionary");
            crbTabHandle = uitab(app.TabGroup, 'Title', 'CRB Optimisation');
            % Initialize tab objects which create their own UI
            app.ViewerTabObj = GUI.ViewerTab(app, viewerTabHandle);
            app.ReconTabObj = GUI.ReconstructionTab(app, reconTabHandle);
            app.FlipAngleGenTabObj = GUI.FlipAngleGenerationTab(app, faGenTabHandle);
            app.DictionaryTabObj = GUI.DictionaryTab(app, dictionaryTabHandle);
            app.CRBOptTabObj = GUI.CRBOptimisationTab(app, crbTabHandle);

            % Initialize colormaps
            %initalizeColourMaps(app);

            app.resizeUI();
        end

        function resizeUI(app)
            % Update UI element positions based on figure size

            if isempty(app.Fig) || ~isvalid(app.Fig)
                return
            end

            figPos = app.Fig.Position;

            app.TabGroup.Position = [10 10 figPos(3)-20 figPos(4)-20];

            % Delegate resize to tabs
            if ~isempty(app.ViewerTabObj)
                app.ViewerTabObj.resizeUI(figPos);
            end

            if ~isempty(app.ReconTabObj)
                app.ReconTabObj.resizeUI(figPos);
            end

            if ~isempty(app.FlipAngleGenTabObj)
                app.FlipAngleGenTabObj.updateResponsiveLayout();
            end
        end

        %% ============================================================
        % Data Loading
        %% ============================================================

        function loadMRF(app)
            % Load MRF data from file

            [file,path] = uigetfile( ...
                {'*.mat;*.nii','MAT/NIFTI Files'}, ...
                'Select MRF Dataset');

            if isequal(file,0)
                return
            end

            filename = fullfile(path,file);

            [app.MRFData,app.MapNames,app.MRFMask] = app.readVolume(filename);

            if isempty(app.MRFData)
                return
            end

            app.CurrentSlice = 1;
            app.CurrentMap = 1;

            app.ViewerTabObj.configureSliceSlider();
            app.ViewerTabObj.configureMapDropdown();

            app.ViewerTabObj.updateDisplay();
        end

        function loadGT(app)
            % Load Ground Truth data from file

            [file,path] = uigetfile( ...
                {'*.mat;*.nii','MAT/NIFTI Files'}, ...
                'Select Ground Truth Dataset');

            if isequal(file,0)
                return
            end

            filename = fullfile(path,file);

            [app.GTData,app.GTMapNames,app.GTMask] = app.readVolume(filename);

            if isempty(app.GTData)
                return
            end

            % Enable GT mask checkbox if a mask was found
            if ~isempty(app.ViewerTabObj)
                if ~isempty(app.GTMask)
                    app.ViewerTabObj.ApplyGTMaskCheckbox.Enable = 'on';
                else
                    app.ViewerTabObj.ApplyGTMaskCheckbox.Enable = 'off';
                    app.ViewerTabObj.ApplyGTMaskCheckbox.Value = false;
                end
            end

            app.ViewerTabObj.updateDisplay();
        end

        function [data,mapNames,mask] = readVolume(app,filename)
            % Read volume data from file
            %   Supports .mat and .nii files

            [~,~,ext] = fileparts(filename);

            mapNames = {};
            mask = [];

            switch lower(ext)

                case '.mat'

                    S = load(filename);
                    [data,mapNames,mask] = app.parseMRFMat(S);

                case '.nii'

                    data = niftiread(filename);

                otherwise

                    error('Unsupported file format');

            end
        end

        function [data,mapNames,mask] = parseMRFMat(app,S)
            % Parse MAT file to extract MRF data and optional binary mask
            %   Looks for T1, T2 fields; combines into 4D array
            %   Extracts 'mask' field if present (case-insensitive)

            mapNames = {};
            mask = [];
            fn = fieldnames(S);

            % Extract mask from top-level fields (case-insensitive)
            topMaskField = fn(strcmpi(fn,'mask'));
            if ~isempty(topMaskField)
                mask = logical(S.(topMaskField{1}));
            end

            % If the MAT file contains top-level T1 and T2 variables,
            % combine them into a 4D MRF volume.
            if ismember('T1',fn) && ismember('T2',fn)

                t1 = S.T1;
                t2 = S.T2;

                if ~isequal(size(t1),size(t2))
                    uialert(app.Fig, ...
                        'T1 and T2 maps must have the same dimensions.', ...
                        'Invalid MRF file', ...
                        'Icon','error');
                    data = [];
                    return
                end

                data = cat(4,t1,t2);
                mapNames = {'T1','T2'};
                return
            end

            % If the MAT file contains exactly one variable that is a struct,
            % look inside it for T1, T2, and mask fields.
            if numel(fn) == 1 && isstruct(S.(fn{1}))

                st = S.(fn{1});

                % Extract mask from nested struct if not already found
                if isempty(mask)
                    stFields = fieldnames(st);
                    nestedMaskField = stFields(strcmpi(stFields,'mask'));
                    if ~isempty(nestedMaskField)
                        mask = logical(st.(nestedMaskField{1}));
                    end
                end

                if isfield(st,'T1') && isfield(st,'T2')

                    t1 = st.T1;
                    t2 = st.T2;

                    if ~isequal(size(t1),size(t2))
                        uialert(app.Fig, ...
                            'T1 and T2 maps must have the same dimensions.', ...
                            'Invalid MRF file', ...
                            'Icon','error');
                        data = [];
                        return
                    end

                    data = cat(4,t1,t2);
                    mapNames = {'T1','T2'};
                    return
                end
            end

            % Fall back to the first variable if the file is not a structured MRF file.
            if isempty(fn)
                uialert(app.Fig, ...
                    'MAT file contains no variables.', ...
                    'Invalid MRF file', ...
                    'Icon','error');
                data = [];
                return
            end

            data = S.(fn{1});

            if isempty(data)
                uialert(app.Fig, ...
                    'Unable to read MRF data from MAT file.', ...
                    'Invalid MRF file', ...
                    'Icon','error');
            end
        end

        %% ============================================================
        % Mouse Wheel Scrolling
        %% ============================================================

        function scrollSlices(app,event)
            % Handle mouse wheel scrolling for slice navigation

            if isempty(app.ViewerTabObj) || isempty(app.MRFData)
                return
            end

            app.ViewerTabObj.scrollSlices(event);
        end

        %% ============================================================
        % ROI File I/O
        %% ============================================================

        function saveROIs(app)
            % Save ROI data to file

            if isempty(app.ROIs)
                uialert(app.Fig, ...
                    'No ROIs to save.', ...
                    'Save ROIs', ...
                    'Icon','warning');
                return
            end

            [file,path] = uiputfile('*.mat','Save ROIs');
            if isequal(file,0)
                return
            end

            roisToSave = app.ROIs;
            save(fullfile(path,file),'roisToSave');
        end

        function loadROIs(app)
            % Load ROI data from file

            [file,path] = uigetfile('*.mat','Load ROIs');
            if isequal(file,0)
                return
            end

            loaded = load(fullfile(path,file));
            if isfield(loaded,'ROIs')
                app.ROIs = loaded.ROIs;
            elseif isfield(loaded,'roisToSave')
                app.ROIs = loaded.roisToSave;
            elseif isfield(loaded,'ROIsData')
                app.ROIs = loaded.ROIsData;
                if ~isempty(app.ViewerTabObj)
                    app.ViewerTabObj.updateROIList();
                end
            end
        end

        function exportROIsCSV(app)
            % Export ROI definitions and basic statistics to CSV for all maps.

            if isempty(app.ROIs)
                uialert(app.Fig, ...
                    'No ROIs to export.', ...
                    'Export ROIs', ...
                    'Icon','warning');
                return
            end

            [file,path] = uiputfile('*.csv','Export ROIs to CSV');
            if isequal(file,0)
                return
            end

            prevSlice = app.CurrentSlice;
            prevMap = app.CurrentMap;
            stateGuard = onCleanup(@()app.restoreSliceMap(prevSlice, prevMap));

            csvRows = {'ROIIndex','Slice','Dataset','MapIndex','MapName','Type','Position','Mean','Std','AreaPx'};

            for k = 1:numel(app.ROIs)
                roi = app.ROIs(k);
                posStr = app.roiPositionToString(roi.Position);

                % --- MRF maps ---
                if ~isempty(app.MRFData)
                    mrfSize = size(app.MRFData);
                    if numel(mrfSize) < 4
                        nMaps = 1;
                    else
                        nMaps = mrfSize(4);
                    end

                    if ~isempty(app.ViewerTabObj) && ~isempty(app.ViewerTabObj.MapDropdown)
                        mapItems = app.ViewerTabObj.MapDropdown.Items;
                    else
                        mapItems = {};
                    end

                    for mapIdx = 1:nMaps
                        app.CurrentSlice = roi.Slice;
                        app.CurrentMap = mapIdx;
                        img = app.extractImage(app.MRFData);
                        vals = app.extractROIMask(img, roi);
                        [meanVal, stdVal, areaPx] = app.roiStatsFromValues(vals);

                        if ~isempty(mapItems) && numel(mapItems) >= mapIdx
                            mapName = mapItems{mapIdx};
                        else
                            mapName = sprintf('Map %d', mapIdx);
                        end

                        csvRows(end+1,:) = {k, roi.Slice, 'MRF', mapIdx, mapName, roi.Type, posStr, meanVal, stdVal, areaPx}; %#ok<AGROW>
                    end
                end

                % --- Ground truth maps ---
                if ~isempty(app.GTData)
                    gtSize = size(app.GTData);
                    if numel(gtSize) < 4
                        nGtMaps = 1;
                    else
                        nGtMaps = gtSize(4);
                    end

                    for mapIdx = 1:nGtMaps
                        app.CurrentSlice = roi.Slice;
                        app.CurrentMap = mapIdx;
                        img = app.extractImage(app.GTData);
                        vals = app.extractROIMask(img, roi);
                        [meanVal, stdVal, areaPx] = app.roiStatsFromValues(vals);

                        if nGtMaps == 1
                            mapName = 'GT';
                        else
                            mapName = sprintf('GT %d', mapIdx);
                        end

                        csvRows(end+1,:) = {k, roi.Slice, 'GT', mapIdx, mapName, roi.Type, posStr, meanVal, stdVal, areaPx}; %#ok<AGROW>
                    end
                end
            end

            try
                writecell(csvRows, fullfile(path,file));
            catch ME
                uialert(app.Fig, ...
                    ['Unable to export CSV: ' ME.message], ...
                    'Export ROIs', ...
                    'Icon','error');
            end
        end

        %% ============================================================
        % Helper Methods for Display
        %% ============================================================

        function img = extractImage(app,data)
            % Extract 2D image from data volume
            %   Handles 2D, 3D, and 4D data arrays

            sz = size(data);

            if numel(sz) < 3
                img = data;
            else
                sliceIdx = min(max(round(app.CurrentSlice),1), sz(3));

                if numel(sz) == 3
                    img = data(:,:,sliceIdx);
                else
                    mapIdx = min(max(round(app.CurrentMap),1), sz(4));
                    img = data(:,:,sliceIdx,mapIdx);
                end
            end
        end

        function drawROIs(app)
            % Draw all ROIs on the axes

            if isempty(app.ROIs) || isempty(app.ViewerTabObj)
                return
            end

            for k = 1:numel(app.ROIs)
                roi = app.ROIs(k);

                if roi.Slice == app.CurrentSlice

                    switch roi.Type
                        case 'Rectangle'
                            rectangle(app.ViewerTabObj.MRFAxes, ...
                                'Position',roi.Position, ...
                                'EdgeColor','r', ...
                                'LineWidth',1);
                            rectangle(app.ViewerTabObj.GTAxes, ...
                                'Position',roi.Position, ...
                                'EdgeColor','r', ...
                                'LineWidth',1);
                        case 'Freehand'
                            if size(roi.Position,2) == 2
                                plot(app.ViewerTabObj.MRFAxes, ...
                                    roi.Position(:,1), ...
                                    roi.Position(:,2), ...
                                    'r-','LineWidth',1);
                                plot(app.ViewerTabObj.GTAxes, ...
                                    roi.Position(:,1), ...
                                    roi.Position(:,2), ...
                                    'r-','LineWidth',1);
                            end
                    end
                end
            end
        end

        function img = applyMaskToImage(~, img, mask)
            % Apply a binary mask to a 2D image, setting masked-out pixels to NaN
            %   mask: logical 2D array matching img spatial dimensions

            if isempty(mask) || isempty(img)
                return
            end

            if ~isequal(size(mask,1), size(img,1)) || ~isequal(size(mask,2), size(img,2))
                return
            end

            img = double(img);
            img(~mask) = NaN;
        end

        function updateInfo(app)
            % Update info label with data statistics

            if isempty(app.ViewerTabObj)
                return
            end

            infoStr = sprintf('Slice: %d | Map: %d', ...
                app.CurrentSlice, app.CurrentMap);

            if ~isempty(app.MapNames) && app.CurrentMap <= numel(app.MapNames)
                infoStr = sprintf('%s (%s)', infoStr, app.MapNames{app.CurrentMap});
            end

            if ~isempty(app.GTData)
                gtMapIdx = app.CurrentMap;

                gtSz = size(app.GTData);
                if numel(gtSz) < 4
                    nGtMaps = 1;
                else
                    nGtMaps = gtSz(4);
                end
                gtMapIdx = min(max(round(gtMapIdx),1),nGtMaps);

                if ~isempty(app.ViewerTabObj) && ismethod(app.ViewerTabObj,'getEquivalentGTMapIndex')
                    gtMapIdx = app.ViewerTabObj.getEquivalentGTMapIndex(app.CurrentMap);
                end

                if ~isempty(app.GTMapNames) && gtMapIdx <= numel(app.GTMapNames)
                    gtName = app.GTMapNames{gtMapIdx};
                elseif nGtMaps <= 1
                    gtName = 'GT';
                else
                    gtName = sprintf('GT %d', gtMapIdx);
                end

                infoStr = sprintf('%s | GT Pair: %d (%s)', infoStr, gtMapIdx, gtName);
            end

            if ~isempty(app.MRFData)
                sz = size(app.MRFData);
                infoStr = sprintf('%s | MRF size: %dx%dx%d', ...
                    infoStr, sz(1), sz(2), sz(3));
            end

            if ~isempty(app.GTData)
                szGt = size(app.GTData);
                if numel(szGt) < 3
                    szGt(3) = 1;
                end
                infoStr = sprintf('%s | GT size: %dx%dx%d', ...
                    infoStr, szGt(1), szGt(2), szGt(3));
            end

            app.ViewerTabObj.InfoLabel.Text = infoStr;
        end

        %% ============================================================
        % ROI Analysis Helpers
        %% ============================================================

        function vals = extractROIMask(~, img, roi)
            % Extract pixel values from ROI region

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

            vals = img(mask);
            if isempty(vals)
                vals = [];
            end
        end

        function restoreSliceMap(app, sliceIdx, mapIdx)
            % Restore viewer state after temporary slice/map changes.
            app.CurrentSlice = sliceIdx;
            app.CurrentMap = mapIdx;
        end

        function [meanVal, stdVal, areaPx] = roiStatsFromValues(~, vals)
            % Compute summary stats for a set of ROI values.
            if isempty(vals)
                meanVal = NaN;
                stdVal = NaN;
                areaPx = NaN;
            else
                meanVal = mean(vals(:),'omitnan');
                stdVal = std(vals(:),'omitnan');
                areaPx = numel(vals);
            end
        end

        function stats = computeROIStats(~, img, roi)
            % Compute mean and std of ROI
            %   Returns struct with .Mean and .Std fields

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
                stats.Mean = NaN;
                stats.Std = NaN;
                return
            end

            stats.Mean = mean(values(:),'omitnan');
            stats.Std  = std(values(:),'omitnan');
        end

        function match = mapNamesMatch(~, mrfName, gtName)
            % Check if two map names match by keyword
            %   Checks for T1, T2, T1rho, MTR, M0

            mrfLower = lower(mrfName);
            gtLower = lower(gtName);

            patterns = {'t1', 't2', 't1rho', 'mtr', 'm0'};

            match = false;
            for p = patterns
                pattern = p{1};
                if contains(mrfLower, pattern) && contains(gtLower, pattern)
                    match = true;
                    return
                end
            end
        end

        function posStr = roiPositionToString(~, pos)
            % Convert an ROI position array to a compact CSV-friendly string.
            if isempty(pos)
                posStr = '';
            elseif isvector(pos)
                posStr = sprintf('[%s]', strtrim(sprintf(' %.3f', pos)));
            else
                rows = cell(1,size(pos,1));
                for ii = 1:size(pos,1)
                    rows{ii} = sprintf('%.3f %.3f', pos(ii,1), pos(ii,2));
                end
                posStr = ['[' strjoin(rows,'; ') ']'];
            end
        end

    end
end
