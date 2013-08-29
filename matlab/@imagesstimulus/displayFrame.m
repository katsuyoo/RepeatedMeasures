% DISPLAYFRAME - present a frame of an image
% Do not call directly, will be called by runexperiment

function [thistrial,experimentdata,breakfromloop,s] = displayFrame(s,e,frame,thistrial,experimentdata)

breakfromloop = 0;

% This is redrawing the image every
% frame. As it is using textures, it should be able
% keep up with the frame rate

todraw = -1;

if ~isempty(e) && ~isempty(s.stateTransitions)
    m = get(e,'devices');
    if isfield(m,'tablet')
        lastsample = getsample(m.tablet);
    else
        lastsample = getxyz(e);
        lastsample(4) = 1;
    end
    [maxx,maxy] = getmaxxy(e);
    for m=1:size(s.stateTransitions,1)
        if thistrial.imageState==s.stateTransitions(m,1) && ...
                sqrt(sum((lastsample(1:2).*[maxx maxy] - experimentdata.targetPosition(s.stateTransitions(m,2),:).*[maxx maxy]).^2)) < s.stateTransitions(m,3) && ...
                sign(lastsample(4)) >= s.stateTransitions(m,4)
            thistrial.imageState = s.stateTransitions(m,5);
            break;
        end     
    end
    todraw = thistrial.imageState;
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
            break;
        end
    end
end

if todraw>0
    if isempty(thistrial.imagerectangle)
        Screen('DrawTexture',experimentdata.screenInfo.curWindow,thistrial.textures(todraw));
    else
        Screen('DrawTexture',experimentdata.screenInfo.curWindow,thistrial.textures(todraw),[],thistrial.imagerectangle(todraw,:));
    end
    if experimentdata.recordingStimuli && mod(frame,4)==0
        thistrial.imageArray = [thistrial.imageArray; {Screen('GetImage', experimentdata.screenInfo.curWindow)}];
    end
end