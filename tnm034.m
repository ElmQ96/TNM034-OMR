function strout = tnm034(im)
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Im: Inputimage of captured sheet music. Im should be in
% double format, normalized to the interval [0,1]
%
% strout: The resulting character string of the detected
% notes. The string must follow a pre-defined format.
%
% Your program code.
%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Pre-processing (Grade 4/5)


%% Geometric transform (Denny)

    % Morphomoical operations

notesRotated = extractnotesfromphoto(loadimage('Images/im1s.jpg'));
notesRotated = alignstaffshorizontally(notesRotated);

notesBlurry = extractnotesfromphoto(loadimage('Images/im13c.jpg'));

figure;
subplot(1,2,1); imshow(notesRotated);
subplot(1,2,2); imshow(notesBlurry);


%% Segmentation (Thobbe)

% Staff 
    % identification
    % Locate and rotate to be horizontal
    % Horizontal projection
    % Save staff position
    % Staff removal

%Binary
    % Thresholding
    % level = graythrash(i);

% Cleaning up (remove false objects)

% Correlation and template matching

C = normxcorr2(template, 1-notesRotated);
    
% labeling (Elias)

% L = bwlabel(BW,n)
% Stats = regionprops(c,properties)


%% Classification (Elias) 

finalimage = findNotes('Images\im1s.jpg','Templates\templateLow.png');

% Decision theory

%% Symbolic description





end