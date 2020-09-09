%%This function was adapted from functions by G.M. Boynton at the
%%University of Washington. See his matlab courses and scripts at:
%%http://courses.washington.edu/matlab1/matlab/
% First, we'll define the Display and dot stimulus from scratch

clear all
close all

Screen('Preference','TextRenderer', 0); %
% Set Display parameters
Display.dist = 50;  %cm
Display.width = 30; %cm
Display.skipChecks = 1; %avoid Screen's timing checks and verbosity

% Set up dot parameters
Dots.nDots = 200;
Dots.speed = 5;
Dots.lifetime = 12;
Dots.apertureSize = [12,12];
Dots.center = [0,0];
Dots.color = [255,255,255];
Dots.size = 8;

nDots = sum([Dots.nDots]);

%Zero out the color and size vectors
colors = zeros(3,nDots);
sizes = zeros(1,nDots);

nRep = 18;

DotsDuration = 1; %seconds
ResponseDuration = 2;
nCoherence = Shuffle(repmat([.1 .5 .9],1,nRep));
nDirection = [];
%Start the trial
Display = OpenWindow(Display);
keys = {};
RT = [];
nKeys = 0;
correct = [];

%Instructions 1
drawText(Display,[0,6],'Moving dots will apear on your screen for 1 second'...
	,[255,255,255]);
drawText(Display,[0,5],'You have to detect as accurately as possible whether they are going up or down',...
	[255,255,255]);
Screen(Display.windowPtr,'Flip');
KbPressWait;

drawText(Display,[0,6],'You have two seconds to respond'...
	,[255,255,255]);
drawText(Display,[0,5],'You will have to perform 18 trials',...
	[255,255,255]);
Screen(Display.windowPtr,'Flip');
KbPressWait;

for iTrial = 1:length(nCoherence)
	
	Dots.coherence = nCoherence(iTrial);
	%choose either up or down for the dot direction
	trialDirection = ceil(rand(1)+.5);  %50/50 chance of a 1 (up) or a 2 (down)
	nDirection = [nDirection, trialDirection];
	Dots.direction = (trialDirection-1)*180; %1 -> 0 degrees, 2 -> 180 degrees
	drawText(Display,[0,6],'Press "u" if Dots are moving upward and "d" if Dots are moving downward'...
		,[255,255,255]);
	drawText(Display,[0,5],'Press Any Key to Begin.',[255,255,255]);
	Display = drawFixation(Display);
	KbPressWait;
	keyIsDown = [];
	lastKey = [];
	try
		%Read the clock if no clock time was provided
		startTime = GetSecs;
		
		%Give a warning if the waiting interval is zero or less
		if GetSecs-startTime > DotsDuration + ResponseDuration
			disp('Warning! waitTill: waiting interval is less than zero')
		end
		
		%Turn off the output to the command window
		ListenChar(2);
		%% loop until DotsDuration + ResponseDuration seconds has passed since startTime was defined
		while GetSecs-startTime < DotsDuration + ResponseDuration
			while GetSecs-startTime < DotsDuration
				%%Moving Dots
				%Generate a random order to draw the Dots so that one field won't occlude
				%another field.
				order=  randperm(nDots);
				% Intitialize the dot positions and define some other initial parameters
				
				count = 1;
				for i=1:length(Dots) %Loop through the fields
					
					%Calculate the left, right top and bottom of each aperture (in degrees)
					l(i) = Dots(i).center(1)-Dots(i).apertureSize(1)/2;
					r(i) = Dots(i).center(1)+Dots(i).apertureSize(1)/2;
					b(i) = Dots(i).center(2)-Dots(i).apertureSize(2)/2;
					t(i) = Dots(i).center(2)+Dots(i).apertureSize(2)/2;
					
					%Generate random starting positions
					Dots(i).x = (rand(1,Dots(i).nDots)-.5)*Dots(i).apertureSize(1) + Dots(i).center(1);
					Dots(i).y = (rand(1,Dots(i).nDots)-.5)*Dots(i).apertureSize(2) + Dots(i).center(2);
					
					%Create a direction vector for a given coherence level
					direction = rand(1,Dots(i).nDots)*360;
					nCoherent = ceil(Dots(i).coherence*Dots(i).nDots);  %Start w/ all random directions
					direction(1:nCoherent) = Dots(i).direction;  %Set the 'coherent' directions
					
					%Calculate dx and dy vectors in real-world coordinates
					Dots(i).dx = Dots(i).speed*sin(direction*pi/180)/Display.frameRate;
					Dots(i).dy = -Dots(i).speed*cos(direction*pi/180)/Display.frameRate;
					Dots(i).life =    ceil(rand(1,Dots(i).nDots)*Dots(i).lifetime);
					
					%Fill in the 'colors' and 'sizes' vectors for this field
					id = count:(count+Dots(i).nDots-1);  %index into the nDots length vector for this field
					colors(:,order(id)) = repmat(Dots(i).color(:),1,Dots(i).nDots);
					sizes(order(id)) = repmat(Dots(i).size,1,Dots(i).nDots);
					count = count+Dots(i).nDots;
				end
				
				%Zero out the screen position vectors and the 'goodDots' vector
				pixpos.x = zeros(1,nDots);
				pixpos.y = zeros(1,nDots);
				goodDots = zeros(1,nDots);
				
				%Calculate total number of temporal frames
				nFrames = secs2frames(Display,DotsDuration);
				
				%% Loop through the frames
				
				for frameNum=1:nFrames
					count = 1;
					for i=1:length(Dots)  %Loop through the fields
						
						%Update the dot position's real-world coordinates
						Dots(i).x = Dots(i).x + Dots(i).dx;
						Dots(i).y = Dots(i).y + Dots(i).dy;
						
						%Move the Dots that are outside the aperture back one aperture width.
						Dots(i).x(Dots(i).x<l(i)) = Dots(i).x(Dots(i).x<l(i)) + Dots(i).apertureSize(1);
						Dots(i).x(Dots(i).x>r(i)) = Dots(i).x(Dots(i).x>r(i)) - Dots(i).apertureSize(1);
						Dots(i).y(Dots(i).y<b(i)) = Dots(i).y(Dots(i).y<b(i)) + Dots(i).apertureSize(2);
						Dots(i).y(Dots(i).y>t(i)) = Dots(i).y(Dots(i).y>t(i)) - Dots(i).apertureSize(2);
						
						%Increment the 'life' of each dot
						Dots(i).life = Dots(i).life+1;
						
						%Find the 'dead' Dots
						deadDots = mod(Dots(i).life,Dots(i).lifetime)==0;
						
						%Replace the positions of the dead Dots to random locations
						Dots(i).x(deadDots) = (rand(1,sum(deadDots))-.5)*Dots(i).apertureSize(1) + Dots(i).center(1);
						Dots(i).y(deadDots) = (rand(1,sum(deadDots))-.5)*Dots(i).apertureSize(2) + Dots(i).center(2);
						
						%Calculate the index for this field's Dots into the whole list of
						%Dots.  Using the vector 'order' means that, for example, the first
						%field is represented not in the first n values, but rather is
						%distributed throughout the whole list.
						id = order(count:(count+Dots(i).nDots-1));
						
						%Calculate the screen positions for this field from the real-world coordinates
						pixpos.x(id) = angle2pix(Display,Dots(i).x)+ Display.resolution(1)/2;
						pixpos.y(id) = angle2pix(Display,Dots(i).y)+ Display.resolution(2)/2;
						
						%Determine which of the Dots in this field are outside this field's
						%elliptical aperture
						goodDots(id) = (Dots(i).x-Dots(i).center(1)).^2/(Dots(i).apertureSize(1)/2)^2 + ...
							(Dots(i).y-Dots(i).center(2)).^2/(Dots(i).apertureSize(2)/2)^2 < 1;
						
						count = count+Dots(i).nDots;
					end
					if frameNum == 1; DisplayStart = GetSecs;end
					%Draw all fields at once
					Screen('DrawDots',Display.windowPtr,[pixpos.x(logical(goodDots));pixpos.y(logical(goodDots))], sizes(logical(goodDots)), colors(:,logical(goodDots)),[0,0],1);
					[ keyIsDown, timeSecs, keyCode ] = KbCheck;
					if keyIsDown && (timeSecs-startTime)> 0.2
						lastKey = keyCode;
					end
					%Draw the fixation point (and call Screen's Flip')
					drawFixation(Display);
				end
			end
			%clear the screen and leave the fixation point
			drawFixation(Display);
			if ~isempty(lastKey) %a key is down: record the key and time pressed
				nKeys = nKeys+1;
				RT = cat(1, RT, timeSecs-DisplayStart);
				keys = {keys{:}, KbName(lastKey)};
				%clear the keyboard buffer
				while KbCheck; end
				lastKey = [];
			else %If no response yet: wait for response until DotsDuration + ResponseDuration
				[ keyIsDown, timeSecs, keyCode ] = KbCheck;
				if keyIsDown
					lastKey = keyCode;
				end
			end
		end
		
		
		%Interpret the response provide feedback
		if length(keys)~=iTrial  %No key was pressed, yellow fixation
			correct = [correct, NaN];
			Display.fixation.color{1} = [255,255,0];
			nKeys = nKeys+1;
			keys = {keys{:}, ''};
		else
			%Correct response, green fixation
			if ((keys{end}(1)=='u' && Dots.direction == 0) || ...
				(keys{end}(1)=='d' && Dots.direction == 180)) && length(keys)==iTrial
				correct = [correct, 1];
				Display.fixation.color{1} = [0,255,0];
				%Incorrect response, red fixation
			elseif ((keys{end}(1)=='d' && Dots.direction == 0) || ...
					(keys{end}(1)=='u' && Dots.direction == 180)) && length(keys)==iTrial
				correct = [correct, 0];
				Display.fixation.color{1} = [255,0,0];
				%Wrong key was pressed, blue fixation
			else
				correct = [correct, NaN];
				Display.fixation.color{1} = [0,0,255];
			end
		end
		
		%Flash the fixation with color
		drawFixation(Display);
		waitTill(.5);
		Display.fixation.color{1} = [255,255,255];
		drawFixation(Display);
		waitTill(.5);
		
	catch ME
		Screen('CloseAll');
		rethrow(ME)
	end
end
Screen('CloseAll');


%% Process and display results
[~, idx] = sort(nCoherence);
correct = correct(idx);
avgCoh = [((sum(correct(1:nRep))/nRep)*100), ((sum(correct(nRep+1:2*nRep))/nRep)*100), ((sum(correct(2*nRep+1:end))/nRep)*100)];
figure(1)
acc = stem( unique(nCoherence(idx)), avgCoh);
xlim([0 0.6]); xticks(unique(nCoherence(idx))); xlabel('Coherence Level'); ylabel('Accuracy (%)');
mAcc = mean(avgCoh);

RT = RT(idx);
avgRT = mean(reshape(RT, [nRep, 3]),1)*100;
figure(2)
rt = boxplot(reshape(RT, [nRep, 3])*100);
xlabel('Coherence Level'); ylabel('RT (ms)');
