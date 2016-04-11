% DISPLAYFRAME - present a frame of an image
% Do not call directly, will be called by runexperiment

function [thistrial,experimentdata,breakfromloop,s] = displayFrame(s,e,frame,thistrial,experimentdata)

breakfromloop = 0;

codes = messagecodes;


% This is redrawing the image every
% frame. As it is using textures, it should be able
% keep up with the frame rate

todraw = -1;

if ~isempty(e) && ~isempty(s.stateTransitions)
    m = get(e,'devices');
    if isfield(m,'tablet')
        data = getsample(m.tablet);
        % lastsample(4) is the pressure (must be greater than 0)
        pressure = data(4);
        lastsample = getsampleVisual(m.tablet,thistrial,frame);
    else
        lastsample = getxyz(e);
        pressure = 1;  % i.e. ignore
    end
    [maxx,maxy] = getmaxxy(e);
    for m=1:numel(s.stateTransitions)
        if thistrial.imageState==s.stateTransitions{m}.currentState && ...
                (GetSecs - thistrial.stateSwitchTime) >= s.stateTransitions{m}.timeElapsed && ...
                sqrt(sum((lastsample(s.dimensionsToUse) - experimentdata.targetPosition(s.stateTransitions{m}.position,:)).^2)) < (s.stateTransitions{m}.distanceAllowed) && ...
                sqrt(sum((lastsample(s.dimensionsToUse) - experimentdata.targetPosition(s.stateTransitions{m}.position,:)).^2)) > (s.stateTransitions{m}.minimumDistance)
            if s.stateTransitions{m}.penTouching==0 || (s.stateTransitions{m}.penTouching==1 && pressure>0) || (s.stateTransitions{m}.penTouching==2 && pressure==0) 
                thistrial.imageState = s.stateTransitions{m}.newState;
                writetolog(e,sprintf('Transition to state %d',thistrial.imageState));
                markEvent(e,codes.imageState+thistrial.imageState);
                thistrial.stateSwitchTime = GetSecs;
                break;
            end
        end     
    end
    todraw = thistrial.imageState;
    if isempty(thistrial.imagerectangle)
        Screen('DrawTexture',experimentdata.screenInfo.curWindow,thistrial.textures(todraw));
    else
        Screen('DrawTexture',experimentdata.screenInfo.curWindow,thistrial.textures(todraw),[],thistrial.imagerectangle(todraw,:));
    end
else
     for k=1:length(thistrial.starttiming)
        if thistrial.starttiming(k)>=0
            thisstart = thistrial.starttiming(k);
        elseif thistrial.starttiming(k)==-Inf
            thisstart = -Inf;
        elseif thistrial.starttiming(k)<0
            % If movementonset.type is < 0, then movement onset has not yet been reached
            if isempty(thistrial.movementonset) || thistrial.movementonset.type < 0
                thisstart = inf;
            else
                % if starttiming is negative, this means it
                % should be relative to movement onset
                thisstart = thistrial.movementonset.type - thistrial.starttiming(k);
            end
        end
        if thistrial.endtiming(k)>=0
            thisend = thistrial.endtiming(k);
        elseif thistrial.endtiming(k)<0
            if isempty(thistrial.movementonset) || thistrial.movementonset.type < 0
                thisend = inf;
            else
                % if endtiming is negative, this means it
                % should be relative to movement onset
                thisend = thistrial.movementonset.type - thistrial.endtiming(k);
            end
        end
        
        %[frame thisstart thisend]
        if frame >= thisstart && frame <= thisend
            todraw = k;
            if isempty(thistrial.imagerectangle)
                Screen('DrawTexture',experimentdata.screenInfo.curWindow,thistrial.textures(todraw));
            else
                Screen('DrawTexture',experimentdata.screenInfo.curWindow,thistrial.textures(todraw),[],thistrial.imagerectangle(todraw,:));
            end
        end
    end
end

if todraw>0
    if experimentdata.recordingStimuli && mod(frame,4)==0
        thistrial.imageArray = [thistrial.imageArray; {Screen('GetImage', experimentdata.screenInfo.curWindow)}];
    end
end