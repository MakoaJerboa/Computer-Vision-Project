% This section ensures all variables are reset on startup
clear all;

% This section loads the data
cam1 = load('./Data/cam1.mat');
cam2 = load('./Data/cam2.mat');
cam3 = load('./Data/cam3.mat');

% This section extracts the image sequence from the data to be used later
cam1fields = fieldnames(cam1);
cam1frames = cam1.(cam1fields{1});
cam2fields = fieldnames(cam2);
cam2frames = cam2.(cam2fields{1});
cam3fields = fieldnames(cam3);
cam3frames = cam3.(cam3fields{1});

% This section gets the number of frames in the video so loops can be run over every frame
cam1numberofframes = size(cam1frames, 4);
cam2numberofframes = size(cam2frames, 4);
cam3numberofframes = size(cam3frames, 4);

% The view from the third camera is sideways, so this section rotates the vieo frame by frame to be upright
rotated_frames = zeros(size(cam3frames, 2), size(cam3frames, 1), size(cam3frames, 3), size(cam3frames, 4), 'uint8');
for i = 1:cam3numberofframes
    rotated_frames(:,:,:,i) = imrotate(cam3frames(:,:,:,i), -90);
end
cam3frames = rotated_frames;

% When tracking the third camera, the tracking algorithm had a tendency to track the top half of the background
% instead of the paint can, so this section covers the top half of the video frame by frame with a black box to prevent this
for i = 1:cam3numberofframes
    cam3frames(1:floor(end/2), :, :, i) = 0;
end

% This section takes the average of all frames to estimate the background
background1 = mean(cam1frames, 4);
background2 = mean(cam2frames, 4);
background3 = mean(cam3frames, 4);

% This section attempts to remove the background from each frame to allow for easier tracking
for i = 1:cam1numberofframes
    cam1frames(:,:,:,i) = imsubtract(cam1frames(:,:,:,i), uint8(background1));
end

for i = 1:cam2numberofframes
    cam2frames(:,:,:,i) = imsubtract(cam2frames(:,:,:,i), uint8(background2));
end

for i = 1:cam3numberofframes
    cam3frames(:,:,:,i) = imsubtract(cam3frames(:,:,:,i), uint8(background3));
end

% This section initialises the tracking variable
centroids1 = zeros(cam1numberofframes, 2);
centroids2 = zeros(cam2numberofframes, 2);
centroids3 = zeros(cam3numberofframes, 2);

% This section runs for each frame in the video of the first camera
for i = 1:cam1numberofframes
    % The current frame is converted to greyscale
    cam1frame = rgb2gray(cam1frames(:,:,:,i));

    % The greyscale frame has a gaussian filter applied to it to reduce noise
    blurredimage1 = imgaussfilt(cam1frame, 3);

    % The the blurred frame is converted to a binary image for easier tracking
    binaryimage1 = imbinarize(blurredimage1, 0.25);

    % Morphological operations are run to make the object easier to track by removing noise
    % This operation removes small objects in the binary image
    binaryimage1 = imopen(binaryimage1, strel('disk', 7));
    % This operation fills small gaps in the binary image
    binaryimage1 = imclose(binaryimage1, strel('disk', 10));

    % % This section finds the object in the binary image
    trackedposition1 = regionprops(binaryimage1, 'Centroid');
    % If the object is tracked successfully, it adds the coordinates of the object to the tracking variable
    if ~isempty(trackedposition1)
        centroids1(i, :) = trackedposition1(1).Centroid;
    % Otherwise the tracking variable is set to NaN
    else
        centroids1(i, :) = NaN;
    end
    % The unused code at the end was originally placed here but is not necessary once the settings are finalised
end

% This section runs for each frame in the video
for i = 1:cam2numberofframes
    % The current frame is converted to greyscale
    cam2frame = rgb2gray(cam2frames(:,:,:,i));


    % The greyscale frame has a gaussian filter applied to it to reduce noise
    blurredimage2 = imgaussfilt(cam2frame, 15);

    % The the blurred frame is converted to a binary image for easier tracking
    binaryimage2 = imbinarize(blurredimage2, 0.3);

    % Morphological operations are run to make the object easier to track by removing noise
    % This operation removes small objects in the binary image
    binaryimage2 = imopen(binaryimage2, strel('disk', 3));
    % This operation fills small gaps in the binary image
    binaryimage2 = imclose(binaryimage2, strel('disk', 5));

    % % This section finds the object in the binary image
    trackedposition2 = regionprops(binaryimage2, 'Centroid');
    % If the object is tracked successfully, it adds the coordinates of the object to the tracking variable
    if ~isempty(trackedposition2)
        centroids2(i, :) = trackedposition2(1).Centroid;
    % Otherwise the tracking variable is set to NaN
    else
        centroids2(i, :) = NaN;
    end
    % The unused code at the end was originally placed here but is not necessary once the settings are finalised
end

% This section runs for each frame in the video
for i = 1:cam3numberofframes
    % The current frame is converted to greyscale
    cam3frame = rgb2gray(cam3frames(:,:,:,i));

    % The greyscale frame has a gaussian filter applied to it to reduce noise
    blurredimage3 = imgaussfilt(cam3frame, 10);

    % The the blurred frame is converted to a binary image for easier tracking
    binaryimage3 = imbinarize(blurredimage3, 0.2);

    % Morphological operations are run to make the object easier to track by removing noise
    % This operation removes small objects in the binary image
    binaryimage3 = imopen(binaryimage3, strel('disk', 3));
    % This operation fills gaps in the binary image
    binaryimage3 = imclose(binaryimage3, strel('disk', 5));

    % This section finds the object in the binary image
    trackedposition3 = regionprops(binaryimage3, 'Centroid');
    % If the object is tracked successfully, it adds the coordinates of the object to the tracking variable
    if ~isempty(trackedposition3)
        centroids3(i, :) = trackedposition3(1).Centroid;
    % Otherwise the tracking variable is set to NaN
    else
        centroids3(i, :) = NaN;
    end
    % The unused code at the end was originally placed here but is not necessary once the settings are finalised
end

% This section extracts the x and y positions of the tracked object for each camera
cam1xposition = centroids1(:,1);
cam1yposition = centroids1(:,2);

cam2xposition = centroids2(:,1);
cam2yposition = centroids2(:,2);

cam3xposition = centroids3(:,1);
cam3yposition = centroids3(:,2);

% This section removes NaN values from the x and y positions using interpolation
% The NaN values are from when the tracking algorithm loses track of the object
% Interpolation is used to fill the values to avoid the position data being detached from the time data (frame number)
cam1xposition = fillmissing(cam1xposition, 'linear');
cam1yposition = fillmissing(cam1yposition, 'linear');

cam2xposition = fillmissing(cam2xposition, 'linear');
cam2yposition = fillmissing(cam2yposition, 'linear');

cam3xposition = fillmissing(cam3xposition, 'linear');
cam3yposition = fillmissing(cam3yposition, 'linear');

% This section plots the data for the tracked paint can
figure;
subplot(3,1,1);
title('Tracked Motion - Camera 1');
xlabel('Time'), ylabel('Position');
hold on;
plot(1:cam1numberofframes, cam1xposition, 'r-o');
plot(1:cam1numberofframes, cam1yposition, 'g-o');
legend('X Position', 'Y Position');

subplot(3,1,2);
title('Tracked Motion - Camera 2');
xlabel('Time'), ylabel('Position');
hold on;
plot(1:cam2numberofframes, cam2xposition, 'r-o');
plot(1:cam2numberofframes, cam2yposition, 'g-o');
legend('X Position', 'Y Position');

subplot(3,1,3);
title('Tracked Motion - Camera 3');
xlabel('Time'), ylabel('Position');
hold on;
plot(1:cam3numberofframes, cam3xposition, 'r-o');
plot(1:cam3numberofframes, cam3yposition, 'g-o');
legend('X Position', 'Y Position');

% This section transposes the position arrays to be used in the PCA
cam1xpositiontransposed = cam1xposition.';
cam1ypositiontransposed = cam1yposition.';

cam2xpositiontransposed = cam2xposition.';
cam2ypositiontransposed = cam2yposition.';

cam3xpositiontransposed = cam3xposition.';
cam3ypositiontransposed = cam3yposition.';

% Find the minimum length among the position arrays
min_length = min([length(cam1xposition), length(cam2xposition), length(cam3xposition)]);

% This section trims the position arrays to the shortest length so all arrays are the same length
cam1xpositiontransposed = cam1xpositiontransposed(1:min_length);
cam1ypositiontransposed = cam1ypositiontransposed(1:min_length);

cam2xpositiontransposed = cam2xpositiontransposed(1:min_length);
cam2ypositiontransposed = cam2ypositiontransposed(1:min_length);

cam3xpositiontransposed = cam3xpositiontransposed(1:min_length);
cam3ypositiontransposed = cam3ypositiontransposed(1:min_length);

% Combine matrices vertically
combinedmatrix = [cam1xpositiontransposed; cam1ypositiontransposed; cam2xpositiontransposed; cam2ypositiontransposed; cam3xpositiontransposed; cam3ypositiontransposed];

% Calculate the mean for each row of the combined matrix
mean_positions = mean(combinedmatrix, 2);

% Subtract the mean from each row of the combined matrix
B = combinedmatrix - mean_positions;

% Calculate the covariance matrix of B
covariance_matrix = cov(B.');

% Calculate the eigenvalues and eigenvectors of the covariance matrix
[eigenvectors, eigenvalues] = eig(covariance_matrix);

% Extract the diagonal of the eigenvalues matrix
eigenvalues = diag(eigenvalues);

% Sort the eigenvalues in ascending order and get the sorted indices
[sorted_eigenvalues, sorted_index] = sort(eigenvalues, 'descend');

% Sort the eigenvectors using the sorted indices
sorted_eigvectors = eigenvectors(:, sorted_index);

% Calculate the percentage variance explained by each principal component
percentage_variance = real(sorted_eigenvalues) / sum(sorted_eigenvalues);

% This section plots the percentage variance against the principal components
figure;
plot(percentage_variance, 'bo');
xlabel('PCA Principal Components');
ylabel('Variance in Percentage');
title('Principal Components of the Data');
axis tight;
grid on;

% Calculate the scores/modes
Y = sorted_eigvectors.' * B;

% This section plots the scores/modes
figure;
plot(Y(1, :), 'b');
hold on;
plot(Y(2, :), 'r');
plot(Y(3, :), 'g');
hold off;
xlabel('No of Readings');
ylabel('Motion');
title('Motion Readings');
legend('Mode 1', 'Mode 2', 'Mode 3');
grid on;

%% This code is unused in the final version, but was useful for visualing the tracking
% and helping to optimise the settings for the image processing

% This section is used to help visualise the object tracking
% This section shows the current frame and overlays where the tracking algorithm thinks the object is
% This allows the tracking accuracy as well as the image quality after filtering to be assessed

% One of the imshow statements can be uncommented to view either the original frame, the blurred frame, or the binary frame
    %imshow(frame);
    %imshow(blurredimage)
    %imshow(binaryimage)
    % This section plots the position of the tracked object over the currently viewed frame
    %hold on;
    %if ~isempty(trackedposition)
    %    plot(centroids(i, 1), centroids(i, 2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
    %end
    %hold off;
    % This section adds a delay, since this section was placed inside of the for loop, it would wait before
    % advancing to the next frame, this allows the preview to look like a videos
    %pause(0.001);