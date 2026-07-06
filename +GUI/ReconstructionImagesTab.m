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
        InfoLabel
        CloseButton
        ModeLabel

        Images = []
        Dimensionality = '2D'
        CurrentSlice = 1
        CurrentTime = 1
        SliceCount = 1
        TimeCount = 1
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
                'Position', [320 10 880 140]);

            obj.ImageAxes = uiaxes(obj.TabHandle, ...
                'Position', [320 160 880 430]);
            title(obj.ImageAxes, 'Reconstruction Images');
            axis(obj.ImageAxes, 'image');

            obj.SliceLabel = uilabel(obj.ControlPanel, ...
                'Position', [10 92 260 22], ...
                'Text', 'Slice: 1 / 1');

            obj.SliceSlider = uislider(obj.ControlPanel, ...
                'Position', [10 82 850 3], ...
                'Limits', [1 2], ...
                'Value', 1, ...
                'Enable', 'off', ...
                'ValueChangedFcn', @(~,~) obj.changeSlice());

            obj.TimeLabel = uilabel(obj.ControlPanel, ...
                'Position', [10 52 260 22], ...
                'Text', 'Time: 1 / 1');

            obj.TimeSlider = uislider(obj.ControlPanel, ...
                'Position', [10 42 850 3], ...
                'Limits', [1 2], ...
                'Value', 1, ...
                'Enable', 'off', ...
                'ValueChangedFcn', @(~,~) obj.changeTime());

            obj.InfoLabel = uilabel(obj.SidePanel, ...
                'Position', [10 10 250 570], ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top', ...
                'Text', 'No reconstruction images loaded.');
        end

        function loadImages(obj, images, dimensionality)
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

            footerH = 140;
            footerY = 10;
            headerH = 35;

            obj.ModeLabel.Position = [10 max(leftH - 35, 10) max(leftW - 20, 120) 22];
            obj.InfoLabel.Position = [10 10 max(leftW - 20, 120) max(leftH - 55, 40)];

            obj.CloseButton.Position = [max(width - 190, rightX) max(height - 42, 10) 160 26];
            obj.ControlPanel.Position = [rightX footerY rightW footerH];

            panelW = obj.ControlPanel.Position(3);
            obj.SliceLabel.Position = [10 92 min(320, panelW - 20) 22];
            obj.SliceSlider.Position = [10 82 max(panelW - 20, 200) 3];
            obj.TimeLabel.Position = [10 52 min(320, panelW - 20) 22];
            obj.TimeSlider.Position = [10 42 max(panelW - 20, 200) 3];

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

            sliceCount = max(1, size(obj.Images, 3));
            timeCount = max(1, size(obj.Images, 4));
            title(obj.ImageAxes, sprintf('Abs Reconstruction Image - Slice %d/%d, Time %d/%d', ...
                obj.CurrentSlice, sliceCount, obj.CurrentTime, timeCount));

            obj.InfoLabel.Text = sprintf('Absolute magnitude view | Volume size: %s', obj.formatSize(size(obj.Images)));
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
    end
end