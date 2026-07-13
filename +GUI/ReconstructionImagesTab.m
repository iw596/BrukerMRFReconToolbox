classdef ReconstructionImagesTab < handle
    % ReconstructionImagesTab - Browser for reconstructed complex image volumes.

    properties
        Parent
        TabHandle

        SidePanel
        ImageAxes
        ControlPanel
        SliceLabel
        SliceSlider
        TimeLabel
        TimeSlider
        ThresholdLabel
        ThresholdSlider
        ThresholdValueLabel
        AutoThresholdButton
        ApplyMaskButton
        PreviewMaskCheckbox
        InfoLabel
        CloseButton
        ModeLabel

        Images = []
        Dimensionality = '2D'
        CurrentSlice = 1
        CurrentTime = 1
        SliceCount = 1
        TimeCount = 1
        ReferenceImage = []
        ExternalReferenceImage = []
        GeneratedMask = []
        CurrentThreshold = 0.05
    end

    methods
        function obj = ReconstructionImagesTab(parentMRFViewer, parentTab)
            obj.Parent = parentMRFViewer;
            obj.TabHandle = parentTab;
            obj.createUI();
        end

        function createUI(obj)
            obj.SidePanel = uipanel(obj.TabHandle, ...
                'Title', 'Info', ...
                'Position', [20 10 280 640]);

            obj.ModeLabel = uilabel(obj.SidePanel, ...
                'Position', [10 600 250 22], ...
                'Text', 'Reconstruction Images');

            obj.CloseButton = uibutton(obj.TabHandle, ...
                'Text', 'Close Tab', ...
                'Position', [1040 620 160 26], ...
                'ButtonPushedFcn', @(~,~) obj.closeTab(), ...
                'Tooltip', 'Close the reconstruction image browser');

            obj.ControlPanel = uipanel(obj.TabHandle, ...
                'Position', [320 10 880 185]);

            obj.ImageAxes = uiaxes(obj.TabHandle, ...
                'Position', [320 160 880 430]);
            title(obj.ImageAxes, 'Reconstruction Images');
            axis(obj.ImageAxes, 'image');

            obj.SliceLabel = uilabel(obj.ControlPanel, ...
                'Position', [10 140 260 22], ...
                'Text', 'Slice: 1 / 1');

            obj.SliceSlider = uislider(obj.ControlPanel, ...
                'Position', [10 132 850 3], ...
                'Limits', [1 2], ...
                'Value', 1, ...
                'Enable', 'off', ...
                'ValueChangedFcn', @(~,~) obj.changeSlice());
            obj.applyCompactSliderStyle(obj.SliceSlider);

            obj.TimeLabel = uilabel(obj.ControlPanel, ...
                'Position', [10 98 260 22], ...
                'Text', 'Time: 1 / 1');

            obj.TimeSlider = uislider(obj.ControlPanel, ...
                'Position', [10 90 850 3], ...
                'Limits', [1 2], ...
                'Value', 1, ...
                'Enable', 'off', ...
                'ValueChangedFcn', @(~,~) obj.changeTime());
            obj.applyCompactSliderStyle(obj.TimeSlider);

            obj.ThresholdLabel = uilabel(obj.ControlPanel, ...
                'Position', [10 56 140 22], ...
                'Text', 'Mask threshold');

            obj.ThresholdSlider = uislider(obj.ControlPanel, ...
                'Position', [150 50 360 3], ...
                'Limits', [0 1], ...
                'Value', obj.CurrentThreshold, ...
                'ValueChangedFcn', @(~,~) obj.changeThreshold());
            obj.applyCompactSliderStyle(obj.ThresholdSlider);

            obj.ThresholdValueLabel = uilabel(obj.ControlPanel, ...
                'Position', [525 56 95 22], ...
                'Text', sprintf('%.3f', obj.CurrentThreshold));

            obj.AutoThresholdButton = uibutton(obj.ControlPanel, ...
                'Text', 'Auto (Otsu)', ...
                'Position', [10 18 110 24], ...
                'ButtonPushedFcn', @(~,~) obj.autoThresholdMask(), ...
                'Tooltip', 'Set threshold using Otsu method on the mean magnitude image');

            obj.ApplyMaskButton = uibutton(obj.ControlPanel, ...
                'Text', 'Apply Mask', ...
                'Position', [130 18 110 24], ...
                'ButtonPushedFcn', @(~,~) obj.applyMaskToResult(), ...
                'Tooltip', 'Write generated mask into reconstruction result for saving');

            obj.PreviewMaskCheckbox = uicheckbox(obj.ControlPanel, ...
                'Text', 'Preview overlay', ...
                'Value', true, ...
                'Position', [250 20 140 22], ...
                'ValueChangedFcn', @(~,~) obj.updateDisplay());

            obj.InfoLabel = uilabel(obj.SidePanel, ...
                'Position', [10 10 250 570], ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top', ...
                'Text', 'No reconstruction images loaded.');
        end

        function loadImages(obj, images, dimensionality, maskReferenceImage)
            if isempty(images)
                return
            end

            obj.Images = abs(images);
            if nargin >= 3 && ~isempty(dimensionality)
                obj.Dimensionality = char(lower(string(dimensionality)));
            else
                obj.Dimensionality = '2d';
            end
            obj.CurrentSlice = 1;
            obj.CurrentTime = 1;
            obj.CurrentThreshold = 0.05;

            obj.ExternalReferenceImage = [];
            if nargin >= 4 && ~isempty(maskReferenceImage)
                obj.ExternalReferenceImage = obj.prepareReferenceImage(maskReferenceImage);
            end

            sz = size(obj.Images);
            if numel(sz) < 3
                sz(3) = 1;
            end
            if numel(sz) < 4
                sz(4) = 1;
            end

            if strcmp(obj.Dimensionality, '3d')
                obj.SliceCount = double(max(1, sz(3)));
                obj.TimeCount = double(max(1, sz(4)));
            else
                obj.SliceCount = 1;
                if numel(sz) >= 4 && sz(3) == 1 && sz(4) > 1
                    obj.TimeCount = double(sz(4));
                else
                    obj.TimeCount = double(max(1, sz(3)));
                end
            end

            obj.SliceSlider.Limits = obj.makeSliderLimits(obj.SliceCount);
            obj.SliceSlider.Value = 1;
            obj.SliceLabel.Text = sprintf('Slice: %d / %d', 1, obj.SliceCount);

            obj.TimeSlider.Limits = obj.makeSliderLimits(obj.TimeCount);
            obj.TimeSlider.Value = 1;
            obj.TimeLabel.Text = sprintf('Time: %d / %d', 1, obj.TimeCount);

            if obj.SliceCount > 1
                obj.SliceSlider.Enable = 'on';
            else
                obj.SliceSlider.Enable = 'off';
            end

            if obj.TimeCount > 1
                obj.TimeSlider.Enable = 'on';
                obj.TimeSlider.Visible = 'on';
                obj.TimeLabel.Visible = 'on';
            else
                obj.TimeSlider.Enable = 'off';
                obj.TimeSlider.Visible = 'off';
                obj.TimeLabel.Visible = 'off';
            end

            obj.initializeMaskState();

            obj.updateDisplay();
        end

        function resizeUI(obj, figPos)
            if isempty(obj.TabHandle) || ~isvalid(obj.TabHandle)
                return
            end

            width = max(figPos(3) - 20, 400);
            height = max(figPos(4) - 20, 300);

            leftW = min(320, max(220, floor(0.24 * width)));
            leftX = 20;
            leftY = 10;
            leftH = max(height - 20, 220);

            obj.SidePanel.Position = [leftX leftY leftW leftH];

            rightX = leftX + leftW + 20;
            rightW = max(width - rightX - 20, 220);

            footerH = 185;
            footerY = 10;
            headerH = 35;

            obj.ModeLabel.Position = [10 max(leftH - 35, 10) max(leftW - 20, 120) 22];
            obj.InfoLabel.Position = [10 10 max(leftW - 20, 120) max(leftH - 55, 40)];

            obj.CloseButton.Position = [max(width - 190, rightX) max(height - 42, 10) 160 26];
            obj.ControlPanel.Position = [rightX footerY rightW footerH];

            panelW = obj.ControlPanel.Position(3);
            contentW = max(panelW - 20, 120);

            obj.SliceLabel.Position = [10 140 min(320, contentW) 22];
            obj.SliceSlider.Position = [10 132 contentW 3];
            obj.TimeLabel.Position = [10 98 min(320, contentW) 22];
            obj.TimeSlider.Position = [10 90 contentW 3];

            thresholdLabelW = 125;
            thresholdValueW = 70;
            thresholdGap = 10;
            thresholdSliderX = 10 + thresholdLabelW + thresholdGap;
            thresholdSliderW = max(contentW - thresholdLabelW - thresholdValueW - 2 * thresholdGap, 120);
            thresholdValueX = thresholdSliderX + thresholdSliderW + thresholdGap;

            obj.ThresholdLabel.Position = [10 56 thresholdLabelW 22];
            obj.ThresholdSlider.Position = [thresholdSliderX 50 thresholdSliderW 3];
            obj.ThresholdValueLabel.Position = [thresholdValueX 56 thresholdValueW 22];

            btnY = 18;
            btnGap = 10;
            autoW = 110;
            applyW = 110;
            autoX = 10;
            applyX = autoX + autoW + btnGap;
            previewX = applyX + applyW + 2 * btnGap;
            previewW = panelW - previewX - 10;

            obj.AutoThresholdButton.Position = [autoX btnY autoW 24];
            obj.ApplyMaskButton.Position = [applyX btnY applyW 24];

            if previewW >= 120
                obj.PreviewMaskCheckbox.Position = [previewX btnY + 2 previewW 22];
            else
                obj.PreviewMaskCheckbox.Position = [10 34 max(contentW, 120) 22];
            end

            axesBottom = footerY + footerH + 10;
            axesTopMargin = headerH + 10;
            obj.ImageAxes.Position = [rightX axesBottom rightW max(height - axesBottom - axesTopMargin, 140)];

            if strcmp(obj.Dimensionality, '3d')
                obj.ModeLabel.Text = sprintf('Reconstruction Images - 3D volume (%d slices, %d time points)', obj.SliceCount, obj.TimeCount);
                title(obj.ImageAxes, 'Reconstruction Images - 3D');
            else
                obj.ModeLabel.Text = sprintf('Reconstruction Images - 2D time series (%d frames)', obj.TimeCount);
                title(obj.ImageAxes, 'Reconstruction Images - 2D');
            end

            obj.updateDisplay();
        end

        function scrollSlices(obj, event)
            if isempty(obj.Images)
                return
            end

            step = sign(event.VerticalScrollCount);
            if step == 0
                return
            end

            if obj.SliceCount > 1
                maxSlice = max(1, round(obj.SliceCount));
                obj.CurrentSlice = max(1, min(maxSlice, obj.CurrentSlice - step));
                obj.SliceSlider.Value = obj.CurrentSlice;
                obj.SliceLabel.Text = sprintf('Slice: %d / %d', obj.CurrentSlice, maxSlice);
            else
                maxTime = max(1, round(obj.TimeCount));
                obj.CurrentTime = max(1, min(maxTime, obj.CurrentTime - step));
                obj.TimeSlider.Value = obj.CurrentTime;
                obj.TimeLabel.Text = sprintf('Time: %d / %d', obj.CurrentTime, maxTime);
            end

            obj.updateDisplay();
        end

        function handleKeyPress(obj, event)
            if isempty(obj.Images)
                return
            end

            key = lower(string(event.Key));

            switch key
                case {"uparrow", "pageup"}
                    if obj.SliceCount > 1
                        obj.stepSlice(-1);
                    else
                        obj.stepTime(-1);
                    end
                case {"downarrow", "pagedown"}
                    if obj.SliceCount > 1
                        obj.stepSlice(1);
                    else
                        obj.stepTime(1);
                    end
                case {"leftarrow"}
                    obj.stepTime(-1);
                case {"rightarrow"}
                    obj.stepTime(1);
                case "home"
                    if obj.SliceCount > 1
                        obj.setSlice(1);
                    else
                        obj.setTime(1);
                    end
                case "end"
                    if obj.SliceCount > 1
                        obj.setSlice(max(1, round(obj.SliceCount)));
                    else
                        obj.setTime(max(1, round(obj.TimeCount)));
                    end
            end
        end

        function changeSlice(obj)
            if isempty(obj.Images)
                return
            end

            if obj.SliceCount <= 1
                return
            end

            obj.CurrentSlice = round(obj.SliceSlider.Value);
            obj.CurrentSlice = max(1, min(obj.CurrentSlice, round(obj.SliceCount)));
            obj.SliceSlider.Value = obj.CurrentSlice;
            obj.SliceLabel.Text = sprintf('Slice: %d / %d', obj.CurrentSlice, obj.SliceCount);
            obj.updateDisplay();
        end

        function changeTime(obj)
            if isempty(obj.Images)
                return
            end

            obj.CurrentTime = round(obj.TimeSlider.Value);
            obj.CurrentTime = max(1, min(obj.CurrentTime, round(obj.TimeCount)));
            obj.TimeSlider.Value = obj.CurrentTime;
            obj.TimeLabel.Text = sprintf('Time: %d / %d', obj.CurrentTime, obj.TimeCount);
            obj.updateDisplay();
        end

        function stepSlice(obj, delta)
            maxSlice = max(1, round(obj.SliceCount));
            obj.setSlice(max(1, min(maxSlice, obj.CurrentSlice + delta)));
        end

        function stepTime(obj, delta)
            maxTime = max(1, round(obj.TimeCount));
            obj.setTime(max(1, min(maxTime, obj.CurrentTime + delta)));
        end

        function setSlice(obj, value)
            if isempty(obj.Images)
                return
            end

            obj.CurrentSlice = value;
            obj.SliceSlider.Value = obj.CurrentSlice;
            obj.SliceLabel.Text = sprintf('Slice: %d / %d', obj.CurrentSlice, obj.SliceCount);
            obj.updateDisplay();
        end

        function setTime(obj, value)
            if isempty(obj.Images)
                return
            end

            obj.CurrentTime = value;
            obj.TimeSlider.Value = obj.CurrentTime;
            obj.TimeLabel.Text = sprintf('Time: %d / %d', obj.CurrentTime, obj.TimeCount);
            obj.updateDisplay();
        end

        function limits = makeSliderLimits(~, count)
            upper = double(max(2, round(count)));
            if ~isfinite(upper) || upper <= 1
                upper = 2;
            end
            limits = [1 upper];
        end

        function closeTab(obj)
            if ~isempty(obj.Parent) && isvalid(obj.Parent)
                obj.Parent.ReconImagesTabObj = [];
            end

            if ~isempty(obj.TabHandle) && isvalid(obj.TabHandle)
                delete(obj.TabHandle);
            end
        end

        function updateDisplay(obj)
            cla(obj.ImageAxes);

            if isempty(obj.Images)
                obj.InfoLabel.Text = 'No reconstruction images loaded.';
                return
            end

            img = obj.getCurrentImage();
            imagesc(obj.ImageAxes, abs(img));
            axis(obj.ImageAxes, 'image');
            colormap(obj.ImageAxes, gray(256));
            colorbar(obj.ImageAxes);

            if obj.PreviewMaskCheckbox.Value && ~isempty(obj.GeneratedMask)
                hold(obj.ImageAxes, 'on');
                maskSlice = obj.getCurrentMaskSlice();
                if ~isempty(maskSlice)
                    overlay = cat(3, ones(size(maskSlice)), zeros(size(maskSlice)), zeros(size(maskSlice)));
                    image(obj.ImageAxes, overlay, 'AlphaData', 0.22 * double(maskSlice));
                end
                hold(obj.ImageAxes, 'off');
            end

            sliceCount = max(1, size(obj.Images, 3));
            timeCount = max(1, size(obj.Images, 4));
            title(obj.ImageAxes, sprintf('Abs Reconstruction Image - Slice %d/%d, Time %d/%d', ...
                obj.CurrentSlice, sliceCount, obj.CurrentTime, timeCount));

            coveragePct = NaN;
            if ~isempty(obj.GeneratedMask)
                coveragePct = 100 * mean(obj.GeneratedMask(:));
            end
            if isnan(coveragePct)
                obj.InfoLabel.Text = sprintf('Absolute magnitude view | Volume size: %s', obj.formatSize(size(obj.Images)));
            else
                obj.InfoLabel.Text = sprintf(['Absolute magnitude view | Volume size: %s\n' ...
                    'Mask threshold: %.3f | Coverage: %.1f%%%%'], ...
                    obj.formatSize(size(obj.Images)), obj.CurrentThreshold, coveragePct);
            end
        end

        function initializeMaskState(obj)
            if ~isempty(obj.ExternalReferenceImage)
                obj.ReferenceImage = obj.ExternalReferenceImage;
            else
                obj.ReferenceImage = obj.computeReferenceImage();
            end
            if isempty(obj.ReferenceImage)
                obj.GeneratedMask = [];
                return
            end

            maxVal = max(obj.ReferenceImage(:));
            if isfinite(maxVal) && maxVal > 0
                obj.ReferenceImage = obj.ReferenceImage ./ maxVal;
            end

            obj.CurrentThreshold = obj.computeOtsuThreshold(obj.ReferenceImage);

            obj.ThresholdSlider.Value = obj.CurrentThreshold;
            obj.ThresholdValueLabel.Text = sprintf('%.3f', obj.CurrentThreshold);
            obj.GeneratedMask = obj.ReferenceImage > obj.CurrentThreshold;
            obj.GeneratedMask = logical(obj.GeneratedMask);
        end

        function refImg = computeReferenceImage(obj)
            refImg = [];
            if isempty(obj.Images)
                return
            end

            imgAbs = abs(double(obj.Images));
            dims = ndims(imgAbs);

            if strcmp(obj.Dimensionality, '3d')
                if dims >= 4
                    refImg = mean(imgAbs, 4);
                else
                    refImg = imgAbs;
                end
            else
                if dims >= 4 && size(imgAbs, 3) == 1 && size(imgAbs, 4) > 1
                    refImg = mean(imgAbs, 4);
                elseif dims >= 3
                    refImg = mean(imgAbs, 3);
                else
                    refImg = imgAbs;
                end
            end

            refImg(~isfinite(refImg)) = 0;
            if ~strcmp(obj.Dimensionality, '3d')
                refImg = squeeze(refImg);
                if ndims(refImg) > 2
                    refImg = refImg(:, :, 1);
                end
            end

            refImg = obj.prepareReferenceImage(refImg);
        end

        function refImg = prepareReferenceImage(~, refImg)
            if isempty(refImg)
                return
            end

            refImg = abs(double(refImg));
            refImg(~isfinite(refImg)) = 0;

            if ndims(refImg) > 3
                refImg = squeeze(refImg);
            end
        end

        function changeThreshold(obj)
            if isempty(obj.ReferenceImage)
                return
            end

            obj.CurrentThreshold = max(0, min(1, double(obj.ThresholdSlider.Value)));
            obj.ThresholdSlider.Value = obj.CurrentThreshold;
            obj.ThresholdValueLabel.Text = sprintf('%.3f', obj.CurrentThreshold);
            obj.GeneratedMask = obj.ReferenceImage > obj.CurrentThreshold;
            obj.GeneratedMask = logical(obj.GeneratedMask);
            obj.updateDisplay();
        end

        function autoThresholdMask(obj)
            if isempty(obj.ReferenceImage)
                return
            end

            obj.CurrentThreshold = obj.computeOtsuThreshold(obj.ReferenceImage);
            obj.ThresholdSlider.Value = obj.CurrentThreshold;
            obj.ThresholdValueLabel.Text = sprintf('%.3f', obj.CurrentThreshold);
            obj.GeneratedMask = obj.ReferenceImage > obj.CurrentThreshold;
            obj.GeneratedMask = logical(obj.GeneratedMask);
            obj.updateDisplay();
        end

        function threshold = computeOtsuThreshold(~, refImg)
            threshold = 0.05;
            if isempty(refImg)
                return
            end

            values = refImg(:);
            values = values(isfinite(values));
            if isempty(values)
                return
            end

            if exist('graythresh', 'file') == 2
                threshold = double(graythresh(values));
            end

            threshold = max(0, min(1, threshold));
        end

        function maskSlice = getCurrentMaskSlice(obj)
            maskSlice = [];
            if isempty(obj.GeneratedMask)
                return
            end

            if strcmp(obj.Dimensionality, '3d')
                szMask = size(obj.GeneratedMask);
                if numel(szMask) < 3
                    maskSlice = obj.GeneratedMask;
                else
                    sliceIdx = min(max(round(obj.CurrentSlice), 1), szMask(3));
                    maskSlice = obj.GeneratedMask(:, :, sliceIdx);
                end
            else
                maskSlice = squeeze(obj.GeneratedMask);
                if ndims(maskSlice) > 2
                    maskSlice = maskSlice(:, :, 1);
                end
            end
        end

        function applyMaskToResult(obj)
            if isempty(obj.GeneratedMask)
                uialert(obj.TabHandle, 'No generated mask available. Load reconstruction images first.', ...
                    'No Mask', 'Icon', 'warning');
                return
            end

            if isempty(obj.Parent) || ~isvalid(obj.Parent)
                return
            end

            if isempty(obj.Parent.ReconResult) || ~isstruct(obj.Parent.ReconResult)
                obj.Parent.ReconResult = struct();
            end

            obj.Parent.ReconResult.mask = logical(obj.GeneratedMask);
            if ~isfield(obj.Parent.ReconResult, 'Log') || isempty(obj.Parent.ReconResult.Log)
                obj.Parent.ReconResult.Log = {};
            end
            obj.Parent.ReconResult.Log{end+1} = sprintf('User-generated mask applied in Recon Images tab (threshold %.3f).', obj.CurrentThreshold);

            if isfield(obj.Parent.ReconResult, 'ParameterMaps') && isstruct(obj.Parent.ReconResult.ParameterMaps)
                obj.Parent.ReconResult.ParameterMaps.mask = logical(obj.GeneratedMask);
            end

            if ~isempty(obj.Parent.ReconTabObj) && isvalid(obj.Parent.ReconTabObj)
                if isfield(obj.Parent.ReconTabObj.ReconSettings, 'LastResult') && isstruct(obj.Parent.ReconTabObj.ReconSettings.LastResult)
                    obj.Parent.ReconTabObj.ReconSettings.LastResult.mask = logical(obj.GeneratedMask);
                    if isfield(obj.Parent.ReconTabObj.ReconSettings.LastResult, 'ParameterMaps') && ...
                            isstruct(obj.Parent.ReconTabObj.ReconSettings.LastResult.ParameterMaps)
                        obj.Parent.ReconTabObj.ReconSettings.LastResult.ParameterMaps.mask = logical(obj.GeneratedMask);
                    end
                    if ~isfield(obj.Parent.ReconTabObj.ReconSettings.LastResult, 'Log') || ...
                            isempty(obj.Parent.ReconTabObj.ReconSettings.LastResult.Log)
                        obj.Parent.ReconTabObj.ReconSettings.LastResult.Log = {};
                    end
                    obj.Parent.ReconTabObj.ReconSettings.LastResult.Log{end+1} = ...
                        sprintf('User-generated mask applied in Recon Images tab (threshold %.3f).', obj.CurrentThreshold);
                end
            end

            coveragePct = 100 * mean(obj.GeneratedMask(:));
            fig = ancestor(obj.TabHandle, 'figure');
            if isempty(fig) || ~isvalid(fig)
                fig = obj.Parent.Fig;
            end
            uialert(fig, ...
                sprintf('Mask applied to reconstruction result. Coverage: %.1f%%%%', coveragePct), ...
                'Mask Applied', 'Icon', 'success');
            obj.updateDisplay();
        end

        function img = getCurrentImage(obj)
            sz = size(obj.Images);

            if numel(sz) < 3
                img = obj.Images;
                return
            end

            if strcmp(obj.Dimensionality, '3d')
                sliceIdx = min(max(round(obj.CurrentSlice), 1), sz(3));
                if numel(sz) < 4
                    img = obj.Images(:,:,sliceIdx);
                    return
                end

                timeIdx = min(max(round(obj.CurrentTime), 1), sz(4));
                img = obj.Images(:,:,sliceIdx,timeIdx);
            else
                timeIdx = min(max(round(obj.CurrentTime), 1), obj.TimeCount);
                if numel(sz) >= 4 && sz(3) == 1 && sz(4) > 1
                    img = obj.Images(:,:,1,timeIdx);
                else
                    img = obj.Images(:,:,timeIdx);
                end
            end
        end

        function sizeText = formatSize(~, sz)
            sizeText = strjoin(arrayfun(@num2str, sz, 'UniformOutput', false), ' x ');
        end

        function applyCompactSliderStyle(~, sliderHandle)
            if isempty(sliderHandle) || ~isvalid(sliderHandle)
                return
            end

            if isprop(sliderHandle, 'MajorTicks')
                sliderHandle.MajorTicks = [];
            end
            if isprop(sliderHandle, 'MajorTickLabels')
                sliderHandle.MajorTickLabels = {};
            end
            if isprop(sliderHandle, 'MinorTicks')
                sliderHandle.MinorTicks = [];
            end
        end
    end
end