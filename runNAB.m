function y = runNAB (startFile, endFile, displayFlag, createModelFlag)
% This function through the entore NAB dataset

close all;
if displayFlag, 
    figure; h1 = gcf; 
end;

A_tp = 1;
A_fp = -0.1100; %(low_FP low_FN standard) = -0.22 -0.11 -0.11
A_fn = -1; %-1; %(low_FP low_FN standard) = -1 -2 -1

perfectScore = zeros (60, 30);
nullScore = zeros (60, 30);
S_A = zeros (60, 30);
randomScore = zeros (60, 30);
numenta_GT = zeros (60, 30);
numenta_Our = zeros (60, 30);


fid = fopen('fileList.txt', 'r');
i = 1;
while ~feof(fid)
    fileNames{i} = fscanf(fid, '%s ', 1);
    i = i+1;
end;
fclose (fid);
fprintf(1, '\n %d files to process in total', i);
close all;
for i=startFile:endFile
    clear global;
   
    [~, name, ~] = fileparts(fileNames{i})
    
    %% Create Model
    if createModelFlag
        main  (fileNames{i}, name, displayFlag);
    end;
    
    %% Read saved run data --
    % see data field record structure in main.m and other variables stored in the mat file
    
    load (sprintf('Output/HTM_SM_%s.mat', name));
    
    %% detect anomaly likelihood
    % shortW (one of the parameters) = 30, 20, 10, 5 -- 

    ourAnomalyLikelihoodNumenta = sequentialAnomalyDectection (data.numentaRawAnomalyScore, 20, displayFlag, find(data.labels, 1));
    anomalyLikelihoodNumenta = data.numentaAnomalyScore; 
    anomalyLikelihood = sequentialAnomalyDectection (anomalyScores, 17, displayFlag, find(data.labels, 1));

    %% iterate through thresholds
    for j = 1:19
        
        likelihoodThresh(j) = 1-j/20;
        
        %% Numenta HTM ground truth Scores
        detectionsNumenta = [0; diff(anomalyLikelihoodNumenta > likelihoodThresh(j))] > 0;
        [numenta_GT(i, j), ~, ~] = computeScore (anomalyLikelihoodNumenta > likelihoodThresh(j), data.labels, A_tp, A_fp, A_fn);
        
        %% Numenta HTM  Scores with our anomaly likelihood computation
        detectionsNumentaOur = [0; diff((ourAnomalyLikelihoodNumenta > likelihoodThresh(j)))] > 0;
        [numenta_Our(i, j), ~, ~] = computeScore (detectionsNumentaOur, data.labels, A_tp, A_fp, A_fn);
       
        %% Our implementation scores
        detections = [0; diff((anomalyLikelihood > likelihoodThresh(j)))] > 0;        
        [S_A(i, j), perfectScore(i, j), nullScore(i, j)] = computeScore (detections, data.labels, A_tp, A_fp, A_fn);
        
        %% Random detector and associated score
        N = length(data.labels);
        trN = round(0.15*N);
        randomDetector = (rand(N, 1) > 0.998449707031);
        randomDetector (1:trN) = 0;
        [randomScore(i, j) , ~, ~] = computeScore (randomDetector, data.labels, A_tp, A_fp, A_fn);
        
         %fprintf (1, '\n Likelihood thresh: %4.3f Score -Our: %4.3f  GT: %4.3f  Random: %4.3f Perfect %4.3f Null %4.3f', ...
         %                likelihoodThresh(j), S_A(i, j), numenta_GT(i, j), randomScore(i, j), perfectScore(i, j), nullScore(i, j));
        
    end;
    %% Plot
    if displayFlag

        subplot(6,1,1); plot(data.value{1}); title ('Raw Data'); axis('tight');
        subplot(6,1,2); plot(anomalyScores); title ('raw Anomaly Score');axis('tight');
        subplot(6,1,3); plot(data.numentaAnomalyScore, 'b'); title ('Numenta');axis('tight');
        subplot(6,1,3); hold on; plot(anomalyLikelihoodNumenta,'r'); title ('Numenta'); hold off; axis('tight');
        subplot(6,1,6); hold on; plot(data.labels,'g');  hold off; axis('tight');
        %subplot(6,1,6); hold on; plot(detections,'b'); title ('Detections'); hold off; axis('tight');
        %subplot(6,1,6); hold on; plot(detectionsNumenta,'r'); title ('Detections'); hold off; axis('tight');

        pause;
    end;
    
end;
nBoot = 200;

S_A (endFile+1,1:19) = sum(S_A(startFile:endFile,1:19), 1);
numenta_GT (endFile+1,1:19) = sum(numenta_GT(startFile:endFile,1:19), 1);
numenta_Our (endFile+1,1:19) = sum(numenta_Our(startFile:endFile,1:19), 1);

randomScore (endFile+1,1:19) = sum(randomScore(startFile:endFile,1:19), 1);
perfectScore (endFile+1,1:19) = sum(perfectScore(startFile:endFile,1:19), 1);
nullScore (endFile+1,1:19) = sum(nullScore(startFile:endFile,1:19), 1);

samples_S_A = bootstrp(nBoot,@sum,[S_A(startFile:endFile,1:19),...
    perfectScore(startFile:endFile,1:19), nullScore(startFile:endFile,1:19)]);
samples_numenta = bootstrp(nBoot,@sum, [numenta_GT(startFile:endFile,1:19),...
    perfectScore(startFile:endFile,1:19), nullScore(startFile:endFile,1:19)]);
samples_numenta_Our = bootstrp(nBoot,@sum, [numenta_Our(startFile:endFile,1:19),...
    perfectScore(startFile:endFile,1:19), nullScore(startFile:endFile,1:19)]);


S_A(endFile+1,1:19) = 100*(S_A(endFile+1,1:19) - nullScore(endFile+1,1:19))./...
    (perfectScore(endFile+1,1:19) - nullScore(endFile+1,1:19));
bootstrapScores_S_A = 100*(samples_S_A(:,1:19) - samples_S_A(:,39:57))./...
    (samples_S_A(:,20:38) - samples_S_A(:,39:57));

numenta_GT(endFile+1,1:19) = 100*(numenta_GT(endFile+1,1:19) - nullScore(endFile+1,1:19))./...
    (perfectScore(endFile+1,1:19) - nullScore(endFile+1,1:19));
bootstrapScores_numenta = 100*(samples_numenta(:,1:19) - samples_numenta(:,39:57))./...
    (samples_numenta(:,20:38) - samples_numenta(:,39:57));  

numenta_Our(endFile+1,1:19) = 100*(numenta_Our(endFile+1,1:19) - nullScore(endFile+1,1:19))./...
    (perfectScore(endFile+1,1:19) - nullScore(endFile+1,1:19));
bootstrapScores_numenta_Our = 100*(samples_numenta_Our(:,1:19) - samples_numenta_Our(:,39:57))./...
    (samples_numenta_Our(:,20:38) - samples_numenta_Our(:,39:57));  


randomScore(endFile+1,1:19) = 100*(randomScore(endFile+1,1:19) - nullScore(endFile+1,1:19))./...
    (perfectScore(endFile+1,1:19) - nullScore(endFile+1,1:19));


[sa_max, sa_i] = max(S_A(endFile+1,1:19));
[gt_max, gt_i] = max(numenta_GT(endFile+1,1:19));
[our_max, our_i] = max(numenta_Our(endFile+1,1:19));

fprintf (1, '\n Our Raw Scores + Our Anomaly Likelihood: %4.3f (Bootstrap estimate: %4.3f +- %4.3f) \n NUPIC Scores + NAB Anomaly Likelihood: %4.3f (Bootstrap estimate: %4.3f +- %4.3f) \n NUPIC Raw Scores + Our Anomaly Likelihood: %4.3f (Bootstrap estimate: %4.3f +- %4.3f) \n Random: %4.3f', ...
    sa_max, mean (bootstrapScores_S_A(:,sa_i)), std (bootstrapScores_S_A(:,sa_i)), ...
    gt_max, mean (bootstrapScores_numenta(:,gt_i)), std (bootstrapScores_numenta(:,gt_i)), ...
    our_max, mean (bootstrapScores_numenta_Our(:,our_i)), std (bootstrapScores_numenta_Our(:,our_i)), ...
    mean(randomScore(endFile+1,1:19)));


figure; plot(S_A(startFile:endFile,sa_i) - numenta_GT(startFile:endFile,gt_i), 'r-o');
