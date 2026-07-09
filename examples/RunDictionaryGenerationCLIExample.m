% RunDictionaryGenerationCLIExample
% Example script for non-GUI dictionary generation.

addpath('api');

% Example 1: load sequence parameters from a Bruker scan folder.
scanPath = "datasets/20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63";
prepListPath = scanPath + "/MRFPrepList.txt";

opts = struct();
opts.PrepListPath = prepListPath;
opts.T1Values = 200:50:3000;
opts.T2Values = [5:5:120 140:20:500];
opts.B1Values = 0.8:0.05:1.2;
opts.RasterTime_us = 10;
opts.NIsochromats = 200;
opts.InstantInversion = true;
opts.ParallelSimulation = true;
opts.ShowProgress = true;
opts.SavePath = "Dictionaries/dict_cli_example.mat";

result = runDictionaryGenerationCLI(scanPath, opts);

fprintf('Dictionary size: %d x %d\n', size(result.Dict,1), size(result.Dict,2));
fprintf('LUT entries: %d\n', size(result.LUT,1));

% Example 2: use an already loaded params struct and explicit prep matrix.
% params = LoadBrukerData(scanPath, false);
% prepList = [
%     0  15  0;   % T1Prep, 15 ms, no wait
%     1  40  0;   % T2Prep, 40 ms, no wait
%     2   0  0;   % no prep
% ];
% opts2 = struct('PrepList', prepList, 'T1Values', 300:100:2500, ...
%                'T2Values', 10:10:250, 'B1Values', 1, ...
%                'ParallelSimulation', false, 'ShowProgress', true);
% result2 = runDictionaryGenerationCLI(params, opts2);
