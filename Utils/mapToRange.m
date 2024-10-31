function y = mapToRange(data, minVal, maxVal)
    % Map the normalized data to the specified range
    minData = min(data);
    maxData = max(data);
    y = minVal + (data - minData) * (maxVal - minVal) / (maxData - minData);
end