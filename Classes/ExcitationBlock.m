classdef ExcitationBlock
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        dt % Raster time
        B1 % RF Waveform scaled to nominal FA (FANom) 
        FANom % Reference FA
        Grad_SS; % Slice selection gradient
        Grad_SR; % Slice rephasing gradient
        
    end

    methods
        %% Class constructor, it takes the B1 shape at ref angle FANom, GA_ss is the gradient amplitude of the 
        %% slice selection gradient (of duration T_Ss). GA_Rphs is the rephasing gradient ampltitude of duration T_SR
        %% T_Rise is the gradient rise time. All times are in second, all gradient ampltidues are in Hz/cm, B1 amplitude is in Hz
        function obj = ExcitationBlock(B1,FANom,GA_SS,T_SS,GA_Rphs,T_SR,T_Rise,dt)
            % Set-up slice selection gradient
            nr = round(T_Rise/dt);
            nf_SS = round(T_SS/dt);
        end
    
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end

        function M = RunRFSimulation(obj,M,FA,plotFlag)
            if (nargin < 4)
                plotFlag = false;
            end

            % Scale RF pulse to desired FA, assuming simple pulse where we
            % can linearly scale the amplitude

            % Run the RF simulation

            % Run the rephasing gradient

            % Store the result

            % Plot if desired 
            if (plotFlag == true)
            end
        end
    end
end