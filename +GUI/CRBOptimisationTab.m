classdef CRBOptimisationTab < handle
% CRBOptimisationTab  GUI tab for Cramér-Rao Bound MRF flip-angle optimisation.
%   Lets the user configure T1/T2 target grids, sequence timing, FA bounds
%   and optimiser settings, then runs OptimiseFAPatternCRB and displays
%   the converged FA pattern, cost history and final CRB maps.

    properties
        Parent
        TabHandle

        % ---- Parameter panels ----
        SeqPanel        % TR, TE, N, NIso
        FAPanel         % FA bounds, initial pattern, objective
        TissuePanel     % T1/T2 grid ranges
        OptPanel        % MaxIter, weights, normalise

        % ---- Sequence controls ----
        TREdit
        TEEdit
        NFramesEdit
        NIsochromatsEdit

        % ---- FA controls ----
        FAMinEdit
        FAMaxEdit
        InitPatternDropdown
        ObjectiveDropdown
        WeightT1Edit
        WeightT2Edit
        NormaliseCheckbox

        % ---- Tissue grid controls ----
        T1RangeEdit
        T2RangeEdit

        % ---- Optimiser controls ----
        MaxIterEdit

        % ---- Action buttons ----
        RunButton
        StopButton
        ExportButton

        % ---- Axes ----
        FAAxes          % Optimised FA pattern
        CostAxes        % Cost vs iteration
        CRBAxes         % CRB T1 vs T2 scatter

        % ---- Status ----
        StatusLabel

        % ---- Internal state ----
        OptResult = []
        StopRequested = false
        FigureResizeListener
    end

    methods

        function obj = CRBOptimisationTab(parentMRFViewer, parentTab)
            obj.Parent    = parentMRFViewer;
            obj.TabHandle = parentTab;
            obj.createUI();
        end

        % ------------------------------------------------------------------
        function createUI(obj)
            TAB = obj.TabHandle;
            margin = 10;

            % ---- Left-column panels (controls) ---------------------------

            % Sequence Timing
            obj.SeqPanel = uipanel(TAB, 'Title', 'Sequence Timing', ...
                'FontWeight', 'bold', 'Position', [margin 530 370 120]);
            P = obj.SeqPanel;

            uilabel(P, 'Text', 'TR (ms)',  'Position', [10 72 90 22], 'FontWeight', 'bold');
            obj.TREdit = uieditfield(P, 'numeric', 'Value', 10, ...
                'Limits', [0 Inf], 'LowerLimitInclusive', false, ...
                'Position', [110 72 80 22], 'Tooltip', 'Repetition time in ms');

            uilabel(P, 'Text', 'TE (ms)',  'Position', [210 72 90 22], 'FontWeight', 'bold');
            obj.TEEdit = uieditfield(P, 'numeric', 'Value', 2, ...
                'Limits', [0 Inf], 'LowerLimitInclusive', false, ...
                'Position', [305 72 55 22], 'Tooltip', 'Echo time in ms');

            uilabel(P, 'Text', 'N frames', 'Position', [10 46 90 22], 'FontWeight', 'bold');
            obj.NFramesEdit = uieditfield(P, 'numeric', 'Value', 500, ...
                'Limits', [1 Inf], 'RoundFractionalValues', true, ...
                'Position', [110 46 80 22], 'Tooltip', 'Number of FA frames');

            uilabel(P, 'Text', 'N isochromats', 'Position', [210 46 90 22], 'FontWeight', 'bold');
            obj.NIsochromatsEdit = uieditfield(P, 'numeric', 'Value', 1, ...
                'Limits', [1 Inf], 'RoundFractionalValues', true, ...
                'Position', [305 46 55 22], 'Tooltip', 'Isochromat count (1 = no slice profile)');

            % FA Bounds & Objective
            obj.FAPanel = uipanel(TAB, 'Title', 'Flip Angle Settings', ...
                'FontWeight', 'bold', 'Position', [margin 370 370 155]);
            P = obj.FAPanel;

            uilabel(P, 'Text', 'FA min (°)',  'Position', [10 100 90 22], 'FontWeight', 'bold');
            obj.FAMinEdit = uieditfield(P, 'numeric', 'Value', 1, ...
                'Limits', [0 180], 'Position', [110 100 80 22], 'Tooltip', 'Lower FA bound');

            uilabel(P, 'Text', 'FA max (°)',  'Position', [210 100 90 22], 'FontWeight', 'bold');
            obj.FAMaxEdit = uieditfield(P, 'numeric', 'Value', 90, ...
                'Limits', [0 180], 'Position', [305 100 55 22], 'Tooltip', 'Upper FA bound');

            uilabel(P, 'Text', 'Initial pattern', 'Position', [10 74 90 22], 'FontWeight', 'bold');
            obj.InitPatternDropdown = uidropdown(P, ...
                'Items', {'Sinusoidal', 'Random', 'Constant 10°', 'Constant 45°'}, ...
                'Value', 'Sinusoidal', ...
                'Position', [110 74 250 22], 'Tooltip', 'Starting FA pattern for optimiser');

            uilabel(P, 'Text', 'Objective', 'Position', [10 48 90 22], 'FontWeight', 'bold');
            obj.ObjectiveDropdown = uidropdown(P, ...
                'Items', {'Joint (T1 + T2)', 'T1 only', 'T2 only'}, ...
                'Value', 'Joint (T1 + T2)', ...
                'Position', [110 48 250 22], ...
                'ValueChangedFcn', @(~,~) obj.updateWeightVisibility(), ...
                'Tooltip', 'Quantity to minimise');

            uilabel(P, 'Text', 'Weight T1', 'Position', [10 22 90 22], 'FontWeight', 'bold');
            obj.WeightT1Edit = uieditfield(P, 'numeric', 'Value', 1, ...
                'Limits', [0 Inf], 'Position', [110 22 80 22], 'Tooltip', 'Relative weight on T1 CRB');

            uilabel(P, 'Text', 'Weight T2', 'Position', [210 22 90 22], 'FontWeight', 'bold');
            obj.WeightT2Edit = uieditfield(P, 'numeric', 'Value', 1, ...
                'Limits', [0 Inf], 'Position', [305 22 55 22], 'Tooltip', 'Relative weight on T2 CRB');

            % Tissue grid
            obj.TissuePanel = uipanel(TAB, 'Title', 'Tissue Parameter Grid', ...
                'FontWeight', 'bold', 'Position', [margin 250 370 115]);
            P = obj.TissuePanel;

            uilabel(P, 'Text', 'T1 values (ms)', 'Position', [10 66 115 22], 'FontWeight', 'bold');
            obj.T1RangeEdit = uieditfield(P, 'text', 'Value', '200:200:2000', ...
                'Position', [130 66 220 22], 'Tooltip', 'MATLAB range/vector in ms, e.g. 200:200:2000');

            uilabel(P, 'Text', 'T2 values (ms)', 'Position', [10 40 115 22], 'FontWeight', 'bold');
            obj.T2RangeEdit = uieditfield(P, 'text', 'Value', '20:20:200', ...
                'Position', [130 40 220 22], 'Tooltip', 'MATLAB range/vector in ms, e.g. 20:20:200');

            obj.NormaliseCheckbox = uicheckbox(P, ...
                'Text', 'Normalise CRBs by T1²/T2²', ...
                'Value', true, ...
                'Position', [10 10 340 22], ...
                'Tooltip', 'Scale CRBs by parameter magnitude for balanced joint objective');

            % Optimiser
            obj.OptPanel = uipanel(TAB, 'Title', 'Optimiser', ...
                'FontWeight', 'bold', 'Position', [margin 170 370 76]);
            P = obj.OptPanel;

            uilabel(P, 'Text', 'Max iterations', 'Position', [10 28 110 22], 'FontWeight', 'bold');
            obj.MaxIterEdit = uieditfield(P, 'numeric', 'Value', 200, ...
                'Limits', [1 Inf], 'RoundFractionalValues', true, ...
                'Position', [130 28 80 22], 'Tooltip', 'fmincon maximum iterations');

            % ---- Buttons -------------------------------------------------
            obj.RunButton = uibutton(TAB, 'Text', 'Run Optimisation', ...
                'Position', [margin 125 175 36], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(~,~) obj.runOptimisation());

            obj.StopButton = uibutton(TAB, 'Text', 'Stop', ...
                'Position', [margin + 185 125 80 36], ...
                'Enable', 'off', ...
                'Tooltip', 'Request early stop after current iteration', ...
                'ButtonPushedFcn', @(~,~) obj.requestStop());

            obj.ExportButton = uibutton(TAB, 'Text', 'Export FA (.mat)', ...
                'Position', [margin 82 370 36], ...
                'Enable', 'off', ...
                'Tooltip', 'Save optimised FA pattern and results to MAT file', ...
                'ButtonPushedFcn', @(~,~) obj.exportResult());

            obj.StatusLabel = uilabel(TAB, ...
                'Text', 'Ready.', ...
                'HorizontalAlignment', 'left', ...
                'Position', [margin 60 370 18]);

            % ---- Axes (right column) -------------------------------------
            obj.FAAxes = uiaxes(TAB, 'Position', [400 490 540 220]);
            title(obj.FAAxes,  'Optimised Flip Angle Pattern');
            xlabel(obj.FAAxes, 'Frame'); ylabel(obj.FAAxes, 'FA (°)');
            grid(obj.FAAxes, 'on');

            obj.CostAxes = uiaxes(TAB, 'Position', [400 260 540 220]);
            title(obj.CostAxes,  'Cost vs Iteration');
            xlabel(obj.CostAxes, 'Iteration'); ylabel(obj.CostAxes, 'Objective value');
            grid(obj.CostAxes, 'on');

            obj.CRBAxes = uiaxes(TAB, 'Position', [400 20 540 225]);
            title(obj.CRBAxes,  'CRB per Tissue Point');
            xlabel(obj.CRBAxes, 'σ(T1) / T1');
            ylabel(obj.CRBAxes, 'σ(T2) / T2');
            grid(obj.CRBAxes, 'on');

            % ---- Responsive resize ---------------------------------------
            fig = ancestor(TAB, 'figure');
            if ~isempty(fig)
                try
                    obj.FigureResizeListener = addlistener(fig, 'SizeChanged', ...
                        @(~,~) obj.updateLayout());
                catch
                end
            end

            obj.updateWeightVisibility();
            obj.updateLayout();
        end

        % ------------------------------------------------------------------
        function runOptimisation(obj)
            % Validate and parse inputs
            TR = obj.TREdit.Value / 1000;
            TE = obj.TEEdit.Value / 1000;
            N  = round(obj.NFramesEdit.Value);
            NIso = round(obj.NIsochromatsEdit.Value);
            faMin = obj.FAMinEdit.Value;
            faMax = obj.FAMaxEdit.Value;
            maxIter = round(obj.MaxIterEdit.Value);
            normalise = obj.NormaliseCheckbox.Value;

            if faMin >= faMax
                obj.safeAlert('FA min must be less than FA max.', 'Input Error', 'warning');
                return;
            end

            try
                T1_ms = eval(['[' obj.T1RangeEdit.Value ']']);
                T2_ms = eval(['[' obj.T2RangeEdit.Value ']']);
            catch
                obj.safeAlert('Invalid T1/T2 range expression.', 'Input Error', 'warning');
                return;
            end

            if isempty(T1_ms) || isempty(T2_ms)
                obj.safeAlert('T1/T2 grids must not be empty.', 'Input Error', 'warning');
                return;
            end

            T1_s = T1_ms / 1000;
            T2_s = T2_ms / 1000;

            % Build initial FA
            initFA = obj.buildInitialFA(N, faMin, faMax);

            % Objective string
            switch obj.ObjectiveDropdown.Value
                case 'T1 only',          objStr = 'T1';
                case 'T2 only',          objStr = 'T2';
                otherwise,               objStr = 'joint';
            end

            wT1 = obj.WeightT1Edit.Value;
            wT2 = obj.WeightT2Edit.Value;

            % Pack params
            params.N          = N;
            params.TR         = TR;
            params.TE         = TE;
            params.T1Grid     = T1_s;
            params.T2Grid     = T2_s;
            params.MaxIter    = maxIter;
            params.NIso       = NIso;
            params.FAMin_deg  = faMin;
            params.FAMax_deg  = faMax;
            params.InitFA     = initFA;
            params.Objective  = objStr;
            params.Weights    = [wT1, wT2];
            params.Normalise  = normalise;
            params.ProgressFcn = @(iter, total, fval, fa) obj.progressCallback(iter, total, fval, fa);

            % UI state
            obj.StopRequested = false;
            obj.OptResult = [];
            obj.RunButton.Enable = 'off';
            obj.StopButton.Enable = 'on';
            obj.ExportButton.Enable = 'off';
            obj.StatusLabel.Text = 'Optimisation running...';
            cla(obj.FAAxes); cla(obj.CostAxes); cla(obj.CRBAxes);
            drawnow;

            try
                result = OptimiseFAPatternCRB(params);
            catch ME
                obj.RunButton.Enable = 'on';
                obj.StopButton.Enable = 'off';
                obj.StatusLabel.Text = 'Error: see console.';
                obj.safeAlert(['Optimisation failed: ' ME.message], 'Optimisation Error', 'error');
                return;
            end

            obj.OptResult = result;
            obj.RunButton.Enable = 'on';
            obj.StopButton.Enable = 'off';
            obj.ExportButton.Enable = 'on';

            exitMsg = obj.exitFlagMessage(result.ExitFlag);
            obj.StatusLabel.Text = sprintf('Done — %d iters, cost=%.4g  [%s]', ...
                result.Iterations, result.CostFinal, exitMsg);

            obj.plotResults(result);
        end

        % ------------------------------------------------------------------
        function progressCallback(obj, iter, ~, fval, fa)
            if obj.StopRequested
                % fmincon cannot be stopped mid-run from outside; flag it
                % to at least update display and let the run finish naturally.
                obj.StatusLabel.Text = sprintf('Stop requested — finishing iter %d…', iter);
            else
                obj.StatusLabel.Text = sprintf('Iteration %d  cost=%.4g', iter, fval);
            end

            % Live FA plot update every 10 iterations
            if mod(iter, 10) == 0
                ax = obj.FAAxes;
                cla(ax);
                plot(ax, 1:numel(fa), fa, 'b-', 'LineWidth', 1.2);
                title(ax, sprintf('FA Pattern (iter %d)', iter));
                xlabel(ax, 'Frame'); ylabel(ax, 'FA (°)'); grid(ax, 'on');
                drawnow limitrate;
            end
        end

        % ------------------------------------------------------------------
        function requestStop(obj)
            obj.StopRequested = true;
            obj.StatusLabel.Text = 'Stop requested — will finish current iteration.';
            obj.StopButton.Enable = 'off';
        end

        % ------------------------------------------------------------------
        function exportResult(obj)
            if isempty(obj.OptResult)
                obj.safeAlert('No result to export. Run optimisation first.', ...
                    'Nothing To Export', 'warning');
                return;
            end

            [fName, fPath] = uiputfile({'*.mat','MAT-file (*.mat)'}, ...
                'Save optimisation result', 'CRB_OptimisedFA.mat');
            if isequal(fName, 0), return; end

            result = obj.OptResult; %#ok<NASGU>
            FA_deg = obj.OptResult.FA_deg; %#ok<NASGU>

            try
                save(fullfile(fPath, fName), 'result', 'FA_deg', '-v7.3');
            catch ME
                obj.safeAlert(['Save failed: ' ME.message], 'Save Error', 'error');
                return;
            end

            obj.safeAlert('Result saved successfully.', 'Export Complete', 'success');
        end

        % ------------------------------------------------------------------
        function plotResults(obj, result)
            % FA pattern
            ax = obj.FAAxes;
            cla(ax);
            plot(ax, 1:numel(result.FA_deg), result.FA_deg, 'b-', 'LineWidth', 1.5);
            title(ax, sprintf('Optimised FA Pattern  (cost=%.4g)', result.CostFinal));
            xlabel(ax, 'Frame'); ylabel(ax, 'FA (°)'); grid(ax, 'on');

            % Cost history
            ax = obj.CostAxes;
            cla(ax);
            if numel(result.CostHistory) > 1
                plot(ax, 1:numel(result.CostHistory), result.CostHistory, 'r-', 'LineWidth', 1.2);
                title(ax, 'Cost vs Iteration');
                xlabel(ax, 'Iteration'); ylabel(ax, 'Objective value'); grid(ax, 'on');
            end

            % CRB scatter: sqrt(CRB)/parameter (relative std)
            ax = obj.CRBAxes;
            cla(ax);
            relT1 = sqrt(max(0, result.CRB_T1)) ./ result.LUT(:,1);
            relT2 = sqrt(max(0, result.CRB_T2)) ./ result.LUT(:,2);
            scatter(ax, relT1 * 100, relT2 * 100, 30, 'filled');
            title(ax, 'CRB — Relative std per tissue point');
            xlabel(ax, 'σ(T1)/T1 (%)');
            ylabel(ax, 'σ(T2)/T2 (%)');
            grid(ax, 'on');
        end

    end % public methods

    % ----------------------------------------------------------------------
    methods (Access = private)

        function fa = buildInitialFA(obj, N, faMin, faMax)
            switch obj.InitPatternDropdown.Value
                case 'Random'
                    rng(0);
                    fa = faMin + (faMax - faMin) .* rand(1, N);
                case 'Constant 10°'
                    fa = repmat(10, 1, N);
                case 'Constant 45°'
                    fa = repmat(45, 1, N);
                otherwise  % Sinusoidal
                    fa = faMin + (faMax - faMin) .* abs(sin(pi .* (1:N) ./ N));
            end
        end

        function updateWeightVisibility(obj)
            isJoint = strcmp(obj.ObjectiveDropdown.Value, 'Joint (T1 + T2)');
            vis = 'off';
            if isJoint, vis = 'on'; end
            set(findobj(obj.FAPanel, 'Text', 'Weight T1'), 'Visible', vis);
            set(findobj(obj.FAPanel, 'Text', 'Weight T2'), 'Visible', vis);
            obj.WeightT1Edit.Visible = vis;
            obj.WeightT2Edit.Visible = vis;
        end

        function updateLayout(obj)
            if isempty(obj.TabHandle) || ~isvalid(obj.TabHandle)
                return;
            end

            tabPos = obj.TabHandle.Position;
            tabW   = max(tabPos(3), 500);
            tabH   = max(tabPos(4), 400);

            margin  = 10;
            colGap  = 10;
            leftW   = max(330, min(420, round(0.36 * tabW)));
            rightX  = margin + leftW + colGap;
            rightW  = max(180, tabW - rightX - margin);

            % Buttons at bottom of left column
            btnH  = 36;
            lbl18 = 18;
            yExport = margin;
            yRun    = yExport + btnH + 6;
            yStatus = yRun + btnH + 4;

            obj.ExportButton.Position = [margin yExport leftW btnH];
            obj.RunButton.Position    = [margin yRun leftW-90 btnH];
            obj.StopButton.Position   = [margin + leftW - 86 yRun 80 btnH];
            obj.StatusLabel.Position  = [margin yStatus leftW lbl18];

            % Stacked panels in left column
            stackBottom = yStatus + lbl18 + 8;
            stackTop    = tabH - margin;
            available   = max(80, stackTop - stackBottom);

            panelHs     = [120 155 115 76];   % Seq / FA / Tissue / Opt
            totalFixed  = sum(panelHs) + 3*6;

            if totalFixed > available
                scale = available / (totalFixed + 1);
                panelHs = max(50, round(panelHs .* scale));
            end

            y = stackTop;
            panels = {obj.SeqPanel, obj.FAPanel, obj.TissuePanel, obj.OptPanel};
            for k = 1:numel(panels)
                h = panelHs(k);
                y = y - h;
                panels{k}.Position = [margin y leftW h];
                y = y - 6;
            end

            % Right-side axes — three equal vertical bands
            axGap  = 10;
            totalAx = tabH - 2*margin;
            axH = max(80, floor((totalAx - 2*axGap) / 3));

            yFA   = margin + 2*(axH + axGap);
            yCost = margin + (axH + axGap);
            yCRB  = margin;

            obj.FAAxes.Position   = [rightX yFA   rightW axH];
            obj.CostAxes.Position = [rightX yCost rightW axH];
            obj.CRBAxes.Position  = [rightX yCRB  rightW axH];
        end

        function safeAlert(obj, msg, titleStr, icon)
            if nargin < 4, icon = 'info'; end
            fig = ancestor(obj.TabHandle, 'figure');
            if isempty(fig) || ~isvalid(fig)
                warning('%s: %s', titleStr, msg);
                return;
            end
            uialert(fig, msg, titleStr, 'Icon', icon);
        end

        function s = exitFlagMessage(~, flag)
            switch flag
                case  1,  s = 'converged';
                case  0,  s = 'max iters';
                case -1,  s = 'stopped';
                case -2,  s = 'infeasible';
                otherwise, s = sprintf('flag=%d', flag);
            end
        end

    end % private methods
end % classdef
