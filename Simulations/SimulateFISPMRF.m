function [dict, LUT] = SimulateFISPMRF(MRFParams, prepList, T1Array, T2Array, B1Array, dt, NIso, instantInversionFlag)
% SimulateFISPMRF Generate FISP-MRF dictionary for requested T1/T2/B1 ranges.
arguments (Input)
    MRFParams
    prepList
    T1Array
    T2Array
    B1Array
    dt % Time step in us
    NIso
    instantInversionFlag = true
end

arguments (Output)
    dict
    LUT
end

gyro = 42.577e6; % Hz/T
riseT = MRFParams.RiseTime; % s
nPointsPerPrep = MRFParams.NPointsPerPrep;
TR = MRFParams.TR;
TE = MRFParams.TE;
nSpin = round(NIso);
df = 0;
dv = 0;
inversionB1 = zeros(0,1);

if isfield(MRFParams, 'PVM_GradCalConst') && ~isempty(MRFParams.PVM_GradCalConst)
    gradCalConst = MRFParams.PVM_GradCalConst;
else
    gradCalConst = 1;
end

if isfield(MRFParams, 'sliceSpoiler') && isfield(MRFParams.sliceSpoiler, 'duration')
    sliceSpoilerDuration = MRFParams.sliceSpoiler.duration;
elseif isfield(MRFParams, 'MRFSpoiler') && isfield(MRFParams.MRFSpoiler, 'duration')
    sliceSpoilerDuration = MRFParams.MRFSpoiler.duration;
else
    sliceSpoilerDuration = 0;
end

if isfield(MRFParams, 'SliceThickness_mm') && ~isempty(MRFParams.SliceThickness_mm)
    thickness = MRFParams.SliceThickness_mm / 1000;
elseif isfield(MRFParams, 'Thickness') && ~isempty(MRFParams.Thickness)
    thickness = MRFParams.Thickness;
else
    thickness = 0.002;
end

dp = zeros([nSpin, 3]);
dp(:,3) = linspace(-thickness, thickness, nSpin) * 100; % m -> cm

dt = dt / 1e6; % us -> s

disp("Starting MRF Simulation")

% Prepare look-up table containing all physically valid T1/T2/B1 tuples.
LUT = zeros(0, 3);
nDictionaryEntries = 0;
for kk = 1:length(B1Array)
    for ii = 1:length(T1Array)
        for jj = 1:length(T2Array)
            if T1Array(ii) >= T2Array(jj)
                LUT(nDictionaryEntries + 1, 1:3) = [T1Array(ii), T2Array(jj), B1Array(kk)]; %#ok<AGROW>
                nDictionaryEntries = nDictionaryEntries + 1;
            end
        end
    end
end
fprintf('DictionaryGeneration: prepared LUT with %d entries.\n', nDictionaryEntries);

% Inversion spoiler
flatTime = MRFParams.T1PrepSpoiler.duration - riseT;
amplitude = gradCalConst * (MRFParams.T1PrepSpoiler.amplitude / 100); % Hz/mm
amplitude = amplitude * 1000; % Hz/m
amplitude = amplitude / gyro; % T/m
spoilerInv = GenSliceSpoiler(amplitude, flatTime, riseT, dt);
spoilerInv = spoilerInv * gyro / 100; % Hz/cm
gInvSpoiler = zeros(length(spoilerInv), 3);
gInvSpoiler(:,3) = spoilerInv;

% Acquisition spoiler
if isfield(MRFParams, 'sliceSpoiler') && isfield(MRFParams.sliceSpoiler, 'duration')
    acqSpoiler = MRFParams.sliceSpoiler;
elseif isfield(MRFParams, 'MRFSpoiler') && isfield(MRFParams.MRFSpoiler, 'duration')
    acqSpoiler = MRFParams.MRFSpoiler;
else
    acqSpoiler = struct('duration', 0, 'amplitude', 0);
end

flatTime = max(0, acqSpoiler.duration - riseT);
amplitude = gradCalConst * (acqSpoiler.amplitude / 100); % Hz/mm
amplitude = amplitude * 1000; % Hz/m
amplitude = amplitude / gyro; % T/m
spoilerAcq = GenSliceSpoiler(amplitude, flatTime, riseT, dt);
spoilerAcq = spoilerAcq * gyro / 100; % Hz/cm
gSliSpoiler = zeros(length(spoilerAcq), 3);
gSliSpoiler(:,3) = spoilerAcq;

% Prepare inversion pulse if required.
if ~instantInversionFlag
    disp("Preparing Inversion Pulse")
    refPower = MRFParams.RefPow;
    refVol = sqrt(refPower * 50);
    refB1 = (pi / 2) / (2 * pi * 42.57 * 10^6 * 1e-3); % T
    pulsePeakVoltage = sqrt(MRFParams.MRFInversionPulse.power * 50);
    peakB1 = (refB1 / refVol) * pulsePeakVoltage;
    [mag, phs] = ReadRFPulseFile("BrukerRFFiles/sech.inv");
    inversionRF = peakB1 .* mag ./ max(mag) .* exp(1j .* deg2rad(phs));
    inversionRF = InterpolateRFWaveform(inversionRF, ...
        MRFParams.MRFInversionPulse.duration, ...
        MRFParams.MRFInversionPulse.duration / length(mag), dt);
    inversionB1 = inversionRF * gyro;
end

% Adjust prep timings.
if ~instantInversionFlag
    for p = 1:size(prepList,1)
        if prepList(p,1) == 0
            prepList(p,2) = prepList(p,2) * 1000 - ...
                (MRFParams.MRFInversionPulse.duration / 2 * 1000) - ...
                riseT * 1000 - MRFParams.T1PrepSpoiler.duration * 1000;
        end
    end
else
    for p = 1:size(prepList,1)
        if prepList(p,1) == 0
            prepList(p,2) = prepList(p,2) * 1000 - ...
                riseT * 1000 - MRFParams.T1PrepSpoiler.duration * 1000;
        end
    end
end

% Flip angle train
if isfield(MRFParams, 'FA') && ~isempty(MRFParams.FA)
    sourceFA = MRFParams.FA(:).';
elseif isfield(MRFParams, 'MRFFA') && ~isempty(MRFParams.MRFFA)
    sourceFA = MRFParams.MRFFA(:).';
else
    error('SimulateFISPMRF:MissingFA', 'No flip-angle train found in parameters (FA/MRFFA).');
end

nFrames = nPointsPerPrep * size(prepList,1);
if isempty(sourceFA)
    error('SimulateFISPMRF:MissingFA', 'Flip-angle train is empty.');
end
faList = repmat(sourceFA, 1, ceil(nFrames / numel(sourceFA)));
faList = deg2rad(faList(1:nFrames));

% Wait times
if size(prepList,2) >= 3
    waitTimes = prepList(:,3) / 1000; % ms -> s
elseif isfield(MRFParams, 'MRFWaitingTimes') && ~isempty(MRFParams.MRFWaitingTimes)
    waitTimes = MRFParams.MRFWaitingTimes(:);
else
    waitTimes = zeros(size(prepList,1), 1);
end

% Allocate dictionary
nSignals = size(prepList,1) * nPointsPerPrep;
dict = zeros(nSignals, size(LUT,1));

% Parallel setup with worker file/path propagation.
pool = [];
if isfield(MRFParams, 'UseParallel')
    useParallel = logical(MRFParams.UseParallel);
else
    useParallel = true;
end

if useParallel && license('test', 'Distrib_Computing_Toolbox')
    pool = gcp('nocreate');
    if ~isempty(pool)
        delete(pool);
    end
    try
        pool = parpool('local');
        fprintf('DictionaryGeneration: parallel pool started with %d workers.\n', pool.NumWorkers);
    catch ME
        warning('SimulateFISPMRF:PoolStartFailed', ...
            'Unable to start parallel pool (%s). Falling back to serial mode.', ME.message);
        useParallel = false;
    end
else
    useParallel = false;
end

toolboxRoot = fileparts(fileparts(mfilename('fullpath')));
if isfolder(toolboxRoot)
    addpath(genpath(toolboxRoot));
end

if useParallel && ~isempty(pool)
    try
        [requiredFiles, ~] = matlab.codetools.requiredFilesAndProducts(mfilename('fullpath'));
        helperPath = which('simulateSingleLUTEntryFISP');
        if ~isempty(helperPath)
            requiredFiles{end+1} = helperPath;
        end
        requiredFiles = unique(requiredFiles);
        requiredFiles = requiredFiles(cellfun(@(f) ~isempty(f) && isfile(f), requiredFiles));
        if ~isempty(requiredFiles)
            addAttachedFiles(pool, requiredFiles);
        end
    catch ME
        warning('SimulateFISPMRF:AttachFilesFailed', ...
            'Could not attach all required files to workers (%s).', ME.message);
    end

    if isfolder(toolboxRoot)
        try
            pctRunOnAll(sprintf('addpath(genpath(''%s''));', toolboxRoot));
        catch ME
            warning('SimulateFISPMRF:WorkerPathFailed', ...
                'Could not broadcast toolbox path to workers (%s).', ME.message);
        end
    end
end

% Run simulation
fprintf('DictionaryGeneration: starting simulation over %d LUT entries.\n', size(LUT,1));
tic;
if useParallel
    try
        parfor i = 1:size(LUT,1)
            dict(:,i) = simulateSingleLUTEntryFISP(i, LUT, prepList, nPointsPerPrep, ...
                instantInversionFlag, inversionB1, gInvSpoiler, gSliSpoiler, ...
                dt, df, dp, dv, faList, TR, TE, riseT, sliceSpoilerDuration, ...
                waitTimes, nSpin);
        end
    catch ME
        lowerMsg = lower(ME.message);
        if contains(lowerMsg, 'source code') || contains(lowerMsg, 'could not be found')
            warning('SimulateFISPMRF:ParforSourceUnavailable', ...
                'Parallel source lookup failed (%s). Retrying in serial mode.', ME.message);
            useParallel = false;
        else
            rethrow(ME);
        end
    end
end

if ~useParallel
    for i = 1:size(LUT,1)
        dict(:,i) = simulateSingleLUTEntryFISP(i, LUT, prepList, nPointsPerPrep, ...
            instantInversionFlag, inversionB1, gInvSpoiler, gSliSpoiler, ...
            dt, df, dp, dv, faList, TR, TE, riseT, sliceSpoilerDuration, ...
            waitTimes, nSpin);
    end
end

elapsedSec = toc;
fprintf('DictionaryGeneration: completed in %.2f s.\n', elapsedSec);
disp("MRF Simulation Finished")
end
