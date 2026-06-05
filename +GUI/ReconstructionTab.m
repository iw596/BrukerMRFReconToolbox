classdef ReconstructionTab < handle
    % ReconstructionTab - Handles the Reconstruction tab UI and functionality
    %   This class manages reconstruction operations and related controls

    properties
        Parent          % Reference to main MRFViewer instance
        TabHandle       % Handle to the tab itself

        % Controls
        RunReconButton

        LoadFileButton


    end
    methods
        function obj = ReconstructionTab(parentMRFViewer, parentTab)
            % Initialize ReconstructionTab
            %   parentMRFViewer: Reference to the MRFViewer instance
            %   parentTab: The uitab container for this tab

            obj.Parent = parentMRFViewer;
            obj.TabHandle = parentTab;

            obj.createUI();
        end

        function createUI(obj)
            % Create all UI elements for the Reconstruction tab

            obj.RunReconButton = uibutton(obj.TabHandle,...
                'Text','Run Reconstruction',...
                'Position',[20 620 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.runReconstruction());

            obj.LoadFileButton = uibutton(obj.TabHandle,...
                'Text','Load File',...
                'Position',[20 580 160 30],...
                'ButtonPushedFcn',...
                @(src,event)obj.loadFile());
        end

        function runReconstruction(obj)
            % Placeholder for the reconstruction action.
            % The button is present, but no behavior is implemented yet.
            disp("Reconstruction initated")
        end

        function loadFile(obj)
            disp("Load File")
            % Open a directory selection dialog and store the selected path
            % Uses uigetdir for directory selection; if cancelled, do nothing
            startDir = pwd;
            selectedDir = uigetdir(startDir, 'Select directory containing files');
            if isequal(selectedDir, 0)
                % User cancelled
                return;
            end
            % Store selected directory in Parent if available, otherwise in this object
            if isprop(obj.Parent, 'LastLoadDir')
                obj.Parent.LastLoadDir = selectedDir;
            else
                obj.LastLoadDir = selectedDir;
            end
            % Optionally display the chosen directory
            disp(['Selected directory: ', selectedDir])
        end
        
        function resizeUI(obj, figPos)
            % Update UI element positions based on figure size
            %   figPos: Figure position [x y width height]

            % Currently no resize logic needed for minimal Reconstruction tab
            % Add position updates here as new controls are added
        end

        
    end
end
