startFile = 1;
endFile = 1;
fid = fopen('fileList.txt', 'r');
i = 1;
while ~feof(fid)
    fscanf(fid, '%d ', 1); % skip the line count in the first column
    fileNames{i} = fscanf(fid, '%s ', 1);
    i = i+1;
end
fclose (fid);
fprintf(1, '\n %d files to process in total', i);
close all;



for i=startFile:endFile

    [~, name, ~] = fileparts(fileNames{i});

    load (sprintf('Output/HTM_SM_%s.mat', name));

   
end