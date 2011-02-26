% hrfDoubleGamma.m
%
%        $Id: hrfDoubleGamma.m 1950 2010-12-18 10:12:48Z julien $
%      usage: [params,hrf] = hrfDoubleGamma(params, tr, stimDuration )
%         by: farshad moradi, modified by julien besle
%       date: 14/06/07, 09/02/2010
%    purpose: reads a basis set from a flobs file
%
function [params, hrf] = hrfFslFlobs(params, tr, justGetParams, defaultParams )

if ~any(nargin == [1 2 3 4])
  help hrfDoubleGamma
  return
end

fslPath = mrGetPref('fslPath');
if strcmp(mrGetPref('fslPath'),'FSL not installed')
  mrErrorDlg('(applyFslTFCE) No path was provided for FSL. Please set MR preference ''fslPath'' by running mrSetPref(''fslPath'',''yourpath'')')
end


threshold = 1e-3; %threshold for removing trailing zeros at the end of the model

if ieNotDefined('justGetParams'),justGetParams = 0;end
if ieNotDefined('defaultParams'),defaultParams = 0;end

if ieNotDefined('params')
  params = struct;
end
if ~isfield(params,'description')
  params.description = 'Flobs basis set';
end
if ~isfield(params,'flobsBasisSetFile')
  params.flobsBasisSetFile = [fslPath(1:end-4) '/etc/default_flobs.flobs/hrfbasisfns.txt'];
end
  
paramsInfo = {...
    {'description', params.description, 'Comment describing the HRF model'},...
    {'flobsBasisSetFile', params.flobsBasisSetFile, 'callback',@testFileExists},...
    {'chooseFile', 0, 'type=pushbutton','callback',{@getBasisSetFile,fslPath},'buttonString=Choose File...'},...
    {'makeFlobs', 0, 'type=pushbutton','callback',{@launchMakeFlobs,fslPath},'buttonString=Launch Make_flobs'},...
};
      
if defaultParams
  params = mrParamsDefault(paramsInfo);
else
  params = mrParamsDialog(paramsInfo, 'Set model HRF parameters');
end

if justGetParams
   return
end

modelHrf = dlmread(params.flobsBasisSetFile);
%the sampling rate of Flobs basis sets is 20Hz
dt = 0.05;

t = (0:size(modelHrf,1)-1)*dt;

%figure;plot(t,modelHrf);

%remove trailing zeros
modelHrf = modelHrf(1:end-find(flipud(max(abs(modelHrf),[],2))>threshold,1,'first')+1,:);
%normalise so that integral of sum = 1
modelHrf = modelHrf./sum(modelHrf(:));
    
%downsample with constant integral
hrf = downsample(modelHrf, round(tr/dt));


params.maxModelHrf = tr/dt * max(modelHrf); %output the max amplitude of the actual model HRF


function launchMakeFlobs(fslPath)

try
  [s,w] = unix(sprintf('%s/Make_flobs',fslPath));
  if s ~=- 0 % unix error
    disp('UNIX error message:')
    disp(w)
    disp('-------------------')
    return
  end
catch 
  disp('(applyFslTFCE) There was a problem running the TFCE unix command')
  disp(sprintf('unix error code: %d; %s', s, w))
  return
end

function testFileExists(params)

if ~exist(params.flobsBasisSetFile,'file')
  mrWarnDlg([params.flobsBasisSetFile ' does not exist']);
end


function getBasisSetFile(fslPath)

[basisSetFilename pathname] = uigetfile('*.*','FLOBS Basis Set Text File');
if isnumeric(basisSetFilename)
   return
end

params.flobsBasisSetFile = [pathname basisSetFilename]

mrParamsSet(params);