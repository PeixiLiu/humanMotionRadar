% Convert the original spectrograms to a smaller size 42*42 for CNN training

for ii = 1:1:3
    power_subfolder = sprintf('radar_%d', ii);
    power_rootfolder = '.\data\THREE_RADAR\';
    rootfolder = fullfile(power_rootfolder, power_subfolder);
    power_tranfloder = '.\data\THREE_RADAR\low_resolution\';
    tranfloder = fullfile(power_tranfloder, power_subfolder);
    for idx = 1:5
        % original
        subfolder = sprintf('%d',idx);
        classfolder = fullfile(rootfolder,subfolder);
    %     classfolder = fullfile(rootfolder,int2str(idx));
        cd(classfolder)
        files = dir('*.jpg');
        % trans
        if ~exist(tranfloder, 'dir')
           mkdir(tranfloder)
        end
        cd(tranfloder)
        mkdir(int2str(idx));
        % transform into low resolution
        classTranfloder = fullfile(tranfloder,int2str(idx));
        for ii = 1:length(files)
           imgName = files(ii).name;
           fullImgName = fullfile(classfolder,imgName);
           H = imread(fullImgName);
           K = imresize(H,0.1,'Antialiasing',false);
           targetSize = [42 42];
           r = centerCropWindow2d(size(K),targetSize);
           I = imcrop(K, r);
           fullImagName_trans = strcat(classTranfloder,'\',int2str(ii),'.jpg');
           imwrite(I,fullImagName_trans,'jpeg')
        end
    end
end
