function [fea,cat] = GetToyExampleDataset(visu)
if ~exist('visu','var'), visu=false; end
% reset(RandStream.getGlobalStream);    %set random number generator to reproduce results

nData = 500;						%number of data for each class
theta = [0, pi/4, pi/2];            %angles
nThetas = length(theta);			%number of angles
fea = zeros(nThetas*nData,2);
cat = zeros(nThetas*nData,1);
for iTheta=1:nThetas
    fea((iTheta-1)*nData+1:iTheta*nData,:) = randomsamp(nData,theta(iTheta));
    cat((iTheta-1)*nData+1:iTheta*nData) = iTheta*ones(nData,1);
end
if visu
    figure
    gscatter(fea(:,1),fea(:,2),cat,'krb','.',10);
    [a,b] = fileparts(which(mfilename));
    savegraph([a,filesep,b]);
end
end

function X = randomsamp(nData,theta)
eps = 1e-1;
R = [cos(theta), -sin(theta); sin(theta), cos(theta)]; %rotation matrix
v = [linspace(-1,1,nData); zeros(1,nData)];
X = R*v;
X = (X+eps*randn(size(X)))';
end