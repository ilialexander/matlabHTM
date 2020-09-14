clear all; clc;

filename = 'datasets/value1_vix_close.csv';
width = 21;

data.buckets = 120;
data.width = width; %[width, width, width, width, width];
data.shift = 1; %[1 1 1 1 width];

%% Read data
rawData = importdata (filename);

%% Decide on bits of representation 
data.nBits = data.shift*data.buckets + data.width - 1;

%quantize data
dataRange = (max(rawData(:, 1)) - min(rawData(:, 1)));
if (dataRange)
    data.value{1} = floor((data.buckets(1) - 1)* (rawData(:, 1) - min (rawData(:, 1)))./...
    dataRange +1);
else
    data.value{1} = ones(size(rawData(:, 1)));
end

data.code{1} = encoderScalar (data.nBits, data.buckets(1), data.width, data.shift (1));

function [SDR] = encoderScalar (n, buckets, width, shift)
% used for 

SDR = [];
sdr = [ones(1, width) zeros(1, n - width)]';
for i = 1:buckets
    SDR = [SDR sdr];
    sdr = circshift(sdr, [shift 0]);
end

SDR = SDR';
end