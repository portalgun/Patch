classdef stim < handle
properties
    pixPerDegXY

    PszXY
    PszRC
    X
    Y

    stmType
    stmXYdeg
    stmXYdegOrig
    timeMult=1
    sizeMult=1
    windowType
    bFixRMS
    RMS
    RMSmonoORbino
    DC

    multFactorXY
    stmXYpix
    plyXYpix
    plySqrPix
    plySqrSizXYpix
    radius

end
methods
    function obj=get_psy(obj,ptb,stmXYdeg,PszXY)
        if exist('stmXYdeg','var')
            obj.stmXYdegOrig=stmXYdeg;
        elseif isempty(obj.stmXYdegOrig) && ~isempty(obj.stmXYdeg)
            obj.stmXYdegOrig=obj.stmXYdeg
        end
        if exist('PszXY','var')
            obj.PszXY=PszXY;
        end

        obj.stmXYdeg=obj.stmXYdegOrig.*obj.sizeMult;
        obj.pixPerDegXY=ptb.display.pixPerDegXY;
        obj.get_poly(ptb);
    end
    function obj=input_parser(obj,Opts);
        P=inputParser();
        P.addParameter('PszXY',[],@isnumeric);
        P.addParameter('stmXYdeg',[],@isnumeric);
        P.addParameter('stmType',[],@ischar);
        P.addParameter('timeMult',1,@isbinary);
        P.addParameter('sizeMult',1,@isbinary);
        P.addParameter('windowType',[],@ischar);
        P.addParameter('WszRCT',[],@isnumeric);
        P.addParameter('Wk',[],@isnumeric);
        P.addParameter('bFixRMS',0,isbinary);
        P.addParameter('RMS',[],@isnumeric);
        P.addParameter('RMSmonoORbino','bino',@(x) strcmp(x,'bino') | strcmp(x,'mono'));
        P.addParameter('DC',[],@isnumeric);
        out=parseStruct(Opts,P,1,1);
        flds=fieldnames(out)
        for i = 1:length(flds)
            fld=flds{i};
            obj.(fld)=out.(fld);
        end

        obj.PszXY=out.PszXY;
        obj.PszRC=fliplr(out.PszXY);
        [obj.X,obj.Y]  =meshgrid(1:obj.PszXY(1),1:obj.PszXY(2));
    end
    function obj=get_poly(obj,ptb)
        obj.stmXYpix       = obj.stmXYdeg.*obj.pixPerDegXY;
        obj.multFactorXY   = obj.stmXYpix./obj.PszXY;
        obj.plyXYpix       = bsxfun(@times,obj.stmXYdeg,obj.pixPerDegXY(1,:));
        if ~isempty(ptb.wdwXYpix)
            obj.plySqrPix      = CenterRect([0 0 obj.plyXYpix(1) obj.plyXYpix(2)], ptb.wdwXYpix);
            obj.plySqrSizXYpix = obj.plySqrPix(3:4)-obj.plySqrPix(1:2);   %Square in display
            obj.radius=abs(obj.plySqrPix(3) - obj.plySqrPix(1))/2;
        end
    end
    function obj=update_stim(obj,stmXYdeg)
        if exist('stmXYdeg','var')
            obj.stmXYdeg=stmXYdeg;
        end
        obj.getpoly;
    end
end
end
