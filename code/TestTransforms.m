function res = TestTransforms(fea,cat,par)

addpath(genpath(pwd)); %add path to matlab search path

%% Parameters and defaults
if ~exist('fea','var') || isempty(fea) || ~exist('cat','var') || isempty(cat)
    [fea,cat] = GetFisherIrisDataset;
    if isnumeric(cat), cat = cellstr(num2str(cat)); end
    nDim = 3; %data has 4 dimensions
    fea = fea(:,1:nDim);
end

if ~exist('par','var') || isempty(par), par = struct; end

options = statset('UseParallel',false); %set option to use parallel computing

def.nAto = 2*size(fea,2); %number of atoms (twice overcomplete dictionary)
def.subSpaRan = 2; %subspace range
def.perActAto = 50; %percentage of active atoms
def.nKNNs = 1; %number of nearest neighbours for classification
def.visu = true;

par = setdefaultoptions(par,def);



% Divide observations in training and test sets (for visualization)
[nObs,nDim] = size(fea);
v = randperm(nObs); %select random permutation of observations
perTraObs = 70; %percentage of observations used for training
nTraObs = floor(nObs*perTraObs/100); %number of training observations

traFea = fea(v(1:nTraObs),1:nDim); %training data
tesFea = fea(v(nTraObs+1:end),1:nDim); %test data
traCat = cat(v(1:nTraObs)); %training categories
tesCat = cat(v(nTraObs+1:end)); %test categories

% normalize features
feaMea = mean(traFea); %mean of training categories
feaStd = std(traFea); %standard deviation of training categories
traFea = (traFea-repmat(feaMea,nTraObs,1))./repmat(feaStd,nTraObs,1); %normalize training data
tesFea = (tesFea-repmat(feaMea,nObs-nTraObs,1))./repmat(feaStd,nObs-nTraObs,1); %normalize test data

%% Classify using original features
cvPar = cvpartition([traCat;tesCat],'kfold',5);                 %create 5fold partition

conMatFun = @(traFea,traCat,tesFea,tesCat)TransformAndClassify(traFea,traCat,tesFea,tesCat,par);
conMat = crossval(conMatFun,[traFea;tesFea],nominal([traCat;tesCat]),'partition',cvPar,'options',options); %compute crossvalidation results on original features

nCat = length(unique(nominal([traCat;tesCat]))); %number of categories
conMat = reshape(sum(conMat),nCat,nCat); %confusion matrix
mcr = sum(sum(conMat-diag(diag(conMat))))/sum(sum(conMat)); %misclassification ratio

%% Test PCA feature transform
[pcaTraFea, pcaTesFea] = PCAFeaturesTransform(traFea,tesFea,par); %compute PCA feature transform
conMatFun = @(traFea,traCat,tesFea,tesCat)PCATransformAndClassify(traFea,traCat,tesFea,tesCat,par);
pcaConMat = crossval(conMatFun,[traFea;tesFea],nominal([traCat;tesCat]),'partition',cvPar,'options',options);
pcaConMat = reshape(sum(pcaConMat),nCat,nCat);
pcaMcr = sum(sum(pcaConMat-diag(diag(pcaConMat))))/sum(sum(pcaConMat));

%% Test SPCA feature transform
[spcaTraFea, spcaTesFea] = SPCAFeaturesTransform(traFea,tesFea,traCat,par);
conMatFun = @(traFea,traCat,tesFea,tesCat)SPCATransformAndClassify(traFea,traCat,tesFea,tesCat,par);
spcaConMat = crossval(conMatFun,[traFea;tesFea],nominal([traCat;tesCat]),'partition',cvPar,'options',options);
spcaConMat = reshape(sum(spcaConMat),nCat,nCat);
spcaMcr = sum(sum(spcaConMat-diag(diag(spcaConMat))))/sum(sum(spcaConMat));

%% Test LDA feature transform
[ldaTraFea,ldaTesFea] = LDAFeaturesTransform(traFea,tesFea,traCat);
conMatFun = @(traFea,traCat,tesFea,tesCat)LDATransformAndClassify(traFea,traCat,tesFea,tesCat,par);
ldaConMat = crossval(conMatFun,[traFea;tesFea],nominal([traCat;tesCat]),'partition',cvPar,'options',options);
ldaConMat = reshape(sum(ldaConMat),nCat,nCat);
ldaMcr = sum(sum(ldaConMat-diag(diag(ldaConMat))))/sum(sum(ldaConMat));

%% Test IPR feature transform
[subs, iprTraFea, iprTesFea] = IPRLearnDisSub(traFea,tesFea,traCat,par);
conMatFun = @(traFea,traCat,tesFea,tesCat)IPRTransformAndClassify(traFea,traCat,tesFea,tesCat,par);
iprConMat = crossval(conMatFun,[traFea;tesFea],nominal([traCat;tesCat]),'partition',cvPar,'options',options);
iprConMat = reshape(sum(iprConMat),nCat,nCat);
iprMcr = sum(sum(iprConMat-diag(diag(iprConMat))))/sum(sum(iprConMat));


%% Plots
% J1 = @(fea,cat) trace(pinv(ClassificationDiscriminant.fit(fea,cat).Sigma)*ClassificationDiscriminant.fit(fea,cat).BetweenSigma);
% J2 = @(fea,cat) trace(ClassificationDiscriminant.fit(fea,cat).BetweenSigma)/trace(ClassificationDiscriminant.fit(fea,cat).Sigma);
% J3 = @(fea,cat) log(abs(det(ClassificationDiscriminant.fit(fea,cat).BetweenSigma))) - ClassificationDiscriminant.fit(fea,cat).LogDetSigma;
mets = {'PCA','S-PCA','LDA','S-IPR'};
if par.visu
    nMet = length(mets);
    sqrNMet = ceil(sqrt(nMet-1));

    close all
    for iMet=1:nMet
        switch mets{iMet}
            case 'none'
                figure(2)
                traFea = traFea;
                mat = conMat;
                err = mcr;
            case 'PCA'
                figure(2)
                if size(pcaTraFea,2)~=3
                    traFea = [pcaTraFea zeros(size(pcaTraFea,3-size(pcaTraFea,2)),1)];
                    tesFea = [pcaTesFea zeros(size(pcaTesFea,3-size(pcaTraFea,2)),1)];
                else
                    traFea = pcaTraFea;
                    tesFea = pcaTesFea;
                end
                mat = pcaConMat;
                err = pcaMcr;
            case 'S-PCA'
                figure(2)
                if size(spcaTraFea,2)~=3
                    traFea = [spcaTraFea zeros(size(spcaTraFea,1),3-size(spcaTraFea,2))];
                    tesFea = [spcaTesFea zeros(size(spcaTesFea,1),3-size(spcaTraFea,2))];
                end
                mat = spcaConMat;
                err = spcaMcr;
            case 'LDA'
                figure(2)
                traFea = ldaTraFea;
                tesFea = ldaTesFea;
                mat = ldaConMat;
                err = ldaMcr;
            case 'S-IPR'
                figure(2)
                traFea = iprTraFea;
                tesFea = iprTesFea;
                mat = iprConMat;
                err = iprMcr;
        end
        subplot(sqrNMet,sqrNMet,iMet)
        if size(fea,2) == 3
            ScatterFeatures(traFea,tesFea,traCat,tesCat,mets{iMet},subs);
        elseif size(fea,2) == 2
            ScatterFeatures2D(traFea,tesFea,traCat,tesCat,mets{iMet},subs);
        end
        %     figure(2), subplot(sqrNMet,sqrNMet,iMet)
        %     DispConfMat(mat,unique([traCat;tesCat])), colormap jet;
        %     title([mets{iMet} ' features transforms. MCR: ' num2str(err)])
    end
end

res.mcr = [mcr pcaMcr spcaMcr ldaMcr iprMcr]';
res.mets = mets;
res.traFea = {traFea,pcaTraFea,spcaTraFea,ldaTraFea,iprTraFea};
res.tesFea = {tesFea,pcaTesFea,spcaTesFea,ldaTesFea,iprTesFea};
end

function ScatterFeatures2D(traFea,tesFea,traCat,tesCat,method,subs)
uniCat = unique(traCat);
col = {'k','r','b','y','k','c'};
mar = {'o','o','o','x','^','>'};
size = 10;
for iCat=1:length(uniCat) %for every category
    ind = strcmp(uniCat(iCat),traCat); %find indexes of data in the trainig set belonging to iCat category
    scatter(traFea(ind,1),traFea(ind,2),size,col{iCat},'Marker','+'); %scatter data
    hold on
    if strcmp(method,'IPR')
        scale = 3;
        quiver(0,0,scale*subs{iCat}(1),scale*subs{iCat}(2));
        quiver(0,0,-scale*subs{iCat}(1),-scale*subs{iCat}(2));
    end
    ind = strcmp(uniCat(iCat),tesCat); %find indexes of data in the test set belonging to iCat category
    scatter(tesFea(ind,1),tesFea(ind,2),size,col{iCat},'Marker','o'); %scatter data
end
title(['feature transform: ' method]);
% xlabel('Sepal length')
% ylabel('Sepal width')
end

function ScatterFeatures(traFea,tesFea,traCat,tesCat,method,subs)
uniCat = unique(traCat);
col = {'k','r','b','y','k','c'};
mar = {'o','o','o','x','^','>'};
size = 30;
for iCat=1:length(uniCat) %for every category
    ind = strcmp(uniCat(iCat),traCat); %find indexes of data in the trainig set belonging to iCat category
    scatter3(traFea(ind,1),traFea(ind,2),traFea(ind,3),size,col{iCat},'Marker','+'); %scatter data
    hold on
%     if strcmp(method,'IPR')
%         scale = 3;
%         quiver3(0,0,0,scale*subs{iCat}(1),scale*subs{iCat}(2),scale*subs{iCat}(3));
%         quiver3(0,0,0,-scale*subs{iCat}(1),-scale*subs{iCat}(2),-scale*subs{iCat}(3));
%     end
    ind = strcmp(uniCat(iCat),tesCat); %find indexes of data in the test set belonging to iCat category
    scatter3(tesFea(ind,1),tesFea(ind,2),tesFea(ind,3),size,col{iCat},'Marker','o'); %scatter data
    if strcmp(method,'S-IPR')
        drawplane(traFea(ind,:)',col{iCat});
    end
end
if ~strcmp(method,'S-IPR')
    drawplane(traFea');
end
title(['feature transform: ' method]);
% xlabel('Sepal length')
% ylabel('Sepal width')
end

function cMat = TransformAndClassify(traFea,traCat,tesFea,tesCat,par)
cMat = confusionmat(nominal(tesCat),nominal(knnclassify(tesFea,traFea,traCat,par.nKNNs)));
end

function cMat = PCATransformAndClassify(traFea,traCat,tesFea,tesCat,par)
[traFeaNew,tesFeaNew] = PCAFeaturesTransform(traFea,tesFea,par);
cMat = confusionmat(nominal(tesCat),nominal(knnclassify(tesFeaNew,traFeaNew,traCat,par.nKNNs)));
end

function cMat = SPCATransformAndClassify(traFea,traCat,tesFea,tesCat,par)
[traFeaNew,tesFeaNew] = SPCAFeaturesTransform(traFea,tesFea,traCat,par);
cMat = confusionmat(nominal(tesCat),nominal(knnclassify(tesFeaNew,traFeaNew,traCat,par.nKNNs)));
end

function cMat = LDATransformAndClassify(traFea,traCat,tesFea,tesCat,par)
[traFeaNew,tesFeaNew] = LDAFeaturesTransform(traFea,tesFea,traCat);
cMat = confusionmat(nominal(tesCat),nominal(knnclassify(tesFeaNew,traFeaNew,traCat,par.nKNNs)));
end

function cMat = IPRTransformAndClassify(traFea,traCat,tesFea,tesCat,par)
[~,traFeaNew,tesFeaNew] = IPRLearnDisSub(traFea,tesFea,cellstr(traCat),par);
cMat = confusionmat(nominal(tesCat),nominal(knnclassify(tesFeaNew,traFeaNew,traCat,par.nKNNs)));
end