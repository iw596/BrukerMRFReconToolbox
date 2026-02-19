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
            nr = round(T_Rise/dt); % Number of points for gradient rise time
            nf_SS = round(T_SS/dt); % Number of flat-top points on  slice selection gradient
            nf_SR = round(T_SR/dt); % Number of flat-top points of slice rephasing gradient
           
            % Create slice selection gradient shape
            ru = (round(1:1:nr(ii))-0.5) / nr;
            ft = ones(1, nf_SS);
            rd = (round(nr:-1:1)-0.5) /nr;
            Grad_SS  = GA_SS * [ru, ft, rd];
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