function [pointsFirstLine, pointsFifthLine, debugRegionsMask] = pp_detectPointsOnStaffLines(staffImage, blockWidth)
    % Default values
    pointsFirstLine = [];
    pointsFifthLine = [];
    debugRegionsMask = zeros(size(staffImage));
    height = size(staffImage, 1);
    width = size(staffImage, 2);

    % Recreate staffMask, but only with the top and bottom lines.
    staffImage = histeq(staffImage);
    mask = pp_getLinesBySearchAngle(staffImage, 1, 0.2, round(size(staffImage,2)*0.25));
    
    % Remove mask residue close to the image borders which can mess up
    % the next step
    padding = ceil(height*0.05);
    mask([1:padding, (height-padding):height], :) = 0;
    mask(:, [1:padding, (width-padding):width]) = 0;
    
    % Merge lines using morphological operations
    mask = imclose(mask, strel('disk', 20, 4));                     
    heightErode = round(height/8);
    temp = imerode(mask, strel('line', heightErode, 90));
    mask = mask & ~imdilate(temp, strel('line', heightErode, 0)); % remove chunk so that only the top and bottom lines remain
    staffImage(~mask) = 1;                                        % erase everything in the image except the two lines

    % Use the two lines to find key points
    scatterLines = pp_blockprocstruct(staffImage, [height, blockWidth], @pp_blockwiseScatterLines);
    
    % Generate midpoints for all lines
    scatterPoints = [];
    for k=1:size(scatterLines,1)
        line = scatterLines(k, :);
        x1 = line(1); y1 = line(2);
        x2 = line(3); y2 = line(4);

        % Get midpoint of each line instead of the endpoints.
        % (the midpoint is more likely to be in the middle of staff line
        %  than the endpoints)
        middleX = x1 + round((x2 - x1)/2);
        middleY = y1 + round((y2 - y1)/2);
        scatterPoints = [scatterPoints; middleX, middleY];

        % Also add points at the start and end of the staffs
        if x1 < blockWidth
            scatterPoints = [scatterPoints; x1, y1];
        elseif x2 > (width-blockWidth)
            scatterPoints = [scatterPoints; x2, y2];
        end
    end
    
    % Split scatterpoints between lower and upper part of the image
    upperPoints = [];
    lowerPoints = [];
    midHeight = round(height/2);
    for k=1:size(scatterPoints,1)
        p = scatterPoints(k,:);
        if p(2) <= midHeight
            upperPoints = [upperPoints; p];
        else
            lowerPoints = [lowerPoints; p];
        end
    end
    
    if isempty(upperPoints) || isempty(lowerPoints)
        return;
    end
    
    % Merge points per group
    averageUpperPoints = [];
    averageLowerPoints = [];
    stepCount = round(width/blockWidth);
    previousUpperX = 0;
    previousLowerX = 0;
    for k=0:stepCount
        leftLimit = k*blockWidth + 1;
        rightLimit = min(width, leftLimit+blockWidth);

        xMask = (leftLimit <= upperPoints(:,1)) & (upperPoints(:,1) <= rightLimit);
        averageUpper = upperPoints(xMask, :);
        pointCount = size(averageUpper, 1);
        if ~isempty(averageUpper)
            averageX = sum(averageUpper(:,1))/pointCount;
            averageY = sum(averageUpper(:,2))/pointCount;
            if averageX ~= previousUpperX
                previousUpperX = averageX;
                averageUpperPoints = [averageUpperPoints; averageX, averageY];
            end
        end

        xMask = (leftLimit <= lowerPoints(:,1)) & (lowerPoints(:,1) <= rightLimit);
        averageLower = lowerPoints(xMask, :);
        pointCount = size(averageLower, 1);
        if ~isempty(averageLower)
            averageX = sum(averageLower(:,1))/pointCount;
            averageY = sum(averageLower(:,2))/pointCount;
            if averageX ~= previousLowerX
                previousLowerX = averageX;
                averageLowerPoints = [averageLowerPoints; averageX, averageY];
            end
        end
        
        debugRegionsMask(1:height, leftLimit) = 1;
        debugRegionsMask(1:10:height, rightLimit-2) = 1;
    end
    debugRegionsMask(midHeight, 1:5:width) = 1;
    debugRegionsMask = debugRegionsMask(1:height, 1:width);
    
    
    % Repeat first and last points and push them to the corner of the image
    % (necessary so that the spline doesn't bend at the end)
    pointsFirstLine = [1, averageUpperPoints(1,2); averageUpperPoints; width, averageUpperPoints(end,2)];
    pointsFifthLine = [1, averageLowerPoints(1,2); averageLowerPoints; width, averageLowerPoints(end,2)];
end

