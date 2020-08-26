function   display = drawText(display,center,str,col)
% display = drawText(display,center,str,[col])
% 
% Draws text string 'str' centered at center = [x,y] in real-world coordinates. 
%
% Text attributes can be set by setting the fields in 'display.text'. This
% sets the attrubute using the corresponding Screen function.  These attributes 
% are reset to the orignal values at the end of the function.
%
%     FIELD NAME        DEFAULT          SCREEN FUNCTION
%       color           black [0,0,0]    TextColor
%       style           1 (bold).        TextStyle
%       size            18               TextSize
%       font            'Courier New'    TextFont
%
% See also: Screen('DrawText?')

% 3/23/09 Written by G.M. Boynton at the University of Washington

%% Deal with default values
if ~isfield(display,'text')
    display.text = [];
end

if ~isfield(display.text,'style')
    display.text.style = Screen(display.windowPtr,'TextStyle');
end


if ~isfield(display.text,'size')
    display.text.size = Screen(display.windowPtr,'TextSize');
end

if ~isfield(display.text,'font')
    display.text.font = Screen(display.windowPtr,'TextFont');
end

if ~isfield(display.text,'color')
    display.text.color = Screen(display.windowPtr,'TextColor');
end

%Set the attributes and save the old ones
oldStyle = Screen(display.windowPtr,'TextStyle',display.text.style);
oldSize = Screen(display.windowPtr,'TextSize',display.text.size);
oldColor = Screen(display.windowPtr,'TextColor',display.text.color);
oldFont = Screen(display.windowPtr,'TextFont',display.text.font);

%Determine the size of the text string (pixels)
rect= Screen('TextBounds',display.windowPtr,str);

%Determine the location of the center of the text (in pixels)
pixpos.x = angle2pix(display,center(1))+ display.resolution(1)/2-rect(3)/2;
pixpos.y = -angle2pix(display,center(2))+ display.resolution(2)/2-rect(4)/2;

%Draw the text.  Use 'col' for the color if available.
if exist('col','var')
    Screen(display.windowPtr,'DrawText',str,pixpos.x,pixpos.y,col);
else
    Screen(display.windowPtr,'DrawText',str,pixpos.x,pixpos.y);
end

%Reset the 'screen' properties to the way we found them.
Screen(display.windowPtr,'TextStyle',oldStyle);
Screen(display.windowPtr,'TextSize',oldSize);
Screen(display.windowPtr,'TextColor',oldColor);
Screen(display.windowPtr,'TextFont',oldFont);
