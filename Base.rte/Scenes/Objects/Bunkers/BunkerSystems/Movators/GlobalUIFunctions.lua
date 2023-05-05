-----------------------------------------------------------------------------------------
-- Global UI Functions Here
-----------------------------------------------------------------------------------------
local _localUIFunctions = {};
_localUIFunctions.LINE_HEIGHT = {};
_localUIFunctions.LINE_HEIGHT[true] = 10;
_localUIFunctions.LINE_HEIGHT[false] = 15;

function DrawTextBox(textDataTable, maxSizeBoxOrCenterPoint, config)
	config = _localUIFunctions:setupTextBoxConfigIfNeeded(config, maxSizeBoxOrCenterPoint);
	local centerPoint, maxSize = _localUIFunctions:setupCenterPointAndMaxSizeAndFixTextDataTableIfNecessary(textDataTable, maxSizeBoxOrCenterPoint, config);
	local topLeft = Vector(centerPoint.X - maxSize.X * 0.5, centerPoint.Y - maxSize.Y * 0.5);
	PrimitiveMan:DrawBoxFillPrimitive(Vector(topLeft.X - config.boxPadding, topLeft.Y - config.boxPadding), Vector(topLeft.X + maxSize.X + config.boxPadding, topLeft.Y + maxSize.Y + config.boxPadding), config.boxOutlineColour);
	PrimitiveMan:DrawBoxFillPrimitive(Vector(topLeft.X - config.boxPadding + config.boxOutlineWidth, topLeft.Y - config.boxPadding + config.boxOutlineWidth), Vector(topLeft.X + maxSize.X + config.boxPadding - config.boxOutlineWidth, topLeft.Y + maxSize.Y + config.boxPadding - config.boxOutlineWidth), config.boxBGColour);

	for i, textDataEntry in ipairs(textDataTable) do
		local linePos = Vector(topLeft.X, topLeft.Y + (i - 1) * _localUIFunctions.LINE_HEIGHT[config.useSmallText]);
		local alignment = type(textDataEntry.alignment) ~= "nil" and textDataEntry.alignment or 1;
		if alignment == 1 then
			linePos.X = linePos.X + maxSize.X * 0.5;
		elseif alignment == 2 then
			linePos.X = linePos.X + maxSize.X;
		end
		PrimitiveMan:DrawTextPrimitive(linePos, textDataEntry.text, config.useSmallText, alignment);
	end
end

-----------------------------------------------------------------------------------------
-- Local UI Functions Here
-----------------------------------------------------------------------------------------
function _localUIFunctions:setupTextBoxConfigIfNeeded(config, maxSizeBoxOrCenterPoint)
	if type(config) == "nil" then
		config = {};
	end
	if type(config.useSmallText) == "nil" then
		config.useSmallText = false;
	end
	if type(config.boxScalesToFitText) == "nil" or maxSizeBoxOrCenterPoint.ClassName == "Vector" then
		config.boxScalesToFitText = (maxSizeBoxOrCenterPoint.ClassName == "Vector");
	end
	if type(config.boxSnapSize) == "nil" then
		config.boxSnapSize = config.useSmallText and 2 or 4;
	end
	if type(config.boxPadding) == "nil" then
		config.boxPadding = config.useSmallText and 2 or 4;
	end
	if type(config.boxBGColour) == "nil" then
		config.boxBGColour = 127;
	end
	if type(config.boxOutlineWidth) == "nil" then
		config.boxOutlineWidth = 2;
	end
	if type(config.boxOutlineColour) == "nil" then
		config.boxOutlineColour = 71;
	end
	return config;
end

function _localUIFunctions:setupCenterPointAndMaxSizeAndFixTextDataTableIfNecessary(textDataTable, maxSizeBoxOrCenterPoint, config)
	local centerPoint = maxSizeBoxOrCenterPoint;
	local maxSize = Vector(math.huge, math.huge);
	if maxSizeBoxOrCenterPoint.ClassName == "Box" then
		centerPoint = maxSizeBoxOrCenterPoint.Center;
		maxSize = Vector(maxSizeBoxOrCenterPoint.Width - config.boxPadding * 2, maxSizeBoxOrCenterPoint.Height - config.boxPadding * 2);
	end
	maxSize = _localUIFunctions:getScaledMaxSizeAndFixTextDataTableIfNecessary(textDataTable, maxSize, config);
	return centerPoint, maxSize;
end

function _localUIFunctions:getScaledMaxSizeAndFixTextDataTableIfNecessary(textDataTable, maxSize, config)
	local numberOfLines = 0;
	local maxSizeIfBoxScalesToFitText = Vector(0, 0);
	for i = 1, #textDataTable do
		if type(textDataTable[i]) == "string" then
			textDataTable[i] = { text = textDataTable[i] };
		end
		numberOfLines = numberOfLines + _localUIFunctions:getNumberOfLinesForText(textDataTable[i].text, maxSize.X, config.useSmallText);
		if config.boxScalesToFitText then
			local textWidth = FrameMan:CalculateTextWidth(textDataTable[i].text, config.useSmallText);
			maxSizeIfBoxScalesToFitText.X = math.max(maxSizeIfBoxScalesToFitText.X, textWidth);
		end
	end
	local totalHeight = numberOfLines * _localUIFunctions.LINE_HEIGHT[config.useSmallText];
	for i = #textDataTable, 1, -1 do
		if totalHeight > maxSize.Y then
			totalHeight = totalHeight - _localUIFunctions.LINE_HEIGHT[config.useSmallText] * _localUIFunctions:getNumberOfLinesForText(textDataTable[i].text, maxSize.X, config.useSmallText);
			table.remove(textDataTable, i);
		else
			break;
		end
	end
	maxSizeIfBoxScalesToFitText.Y = totalHeight;

	if config.boxScalesToFitText then
		maxSizeIfBoxScalesToFitText.X = maxSizeIfBoxScalesToFitText.X + config.boxSnapSize - maxSizeIfBoxScalesToFitText.X % config.boxSnapSize;
		maxSizeIfBoxScalesToFitText.Y = maxSizeIfBoxScalesToFitText.Y + config.boxSnapSize - maxSizeIfBoxScalesToFitText.Y % config.boxSnapSize;
		maxSize = Vector(math.min(maxSize.X, maxSizeIfBoxScalesToFitText.X), math.min(maxSize.Y, maxSizeIfBoxScalesToFitText.Y));
	end
	return maxSize;
end

function _localUIFunctions:getNumberOfLinesForText(textString, maxWidth, useSmallText)
	local numberOfLines = 1;
	local stringWidth = FrameMan:CalculateTextWidth(textString, useSmallText);
	if stringWidth > maxWidth then
		numberOfLines = numberOfLines + math.modf(stringWidth / maxWidth);
	end
	return numberOfLines;
end
