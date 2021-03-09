classdef ptchs_dsp < handle
methods
    function obj=init_disp(obj,trgtInfo,focInfo,Disp,winInfo,subjInfo)
        if exist('trgtInfo','var') && ~isempty(trgtInfo)
            obj.ptchOpts.trgtInfo=trgtInfo;
        end

        if exist('focInfo','var') && ~isempty(focInfo)
            obj.ptchOpts.focInfo=focInfo;
        end

        if exist('Disp','var') && isa(Disp,'DISPLAY')
            obj.ptchOpts.Disp=Disp;
            obj.ptchOpts.DispInfo=DISPLAY.get_name_from_display(Disp);
        elseif  exist('Disp','var') && ischar(Disp)
            obj.ptchOpts.DispInfo=Disp;
            obj.ptchOpts.Disp=DISPLAY(Disp);
        elseif isempty(obj.ptchOpts.Disp)
            obj.ptchOpts.Disp=DISPLAY.get_display_from_hostname();
            obj.ptchOpts.DispInfo=DISPLAY.get_name_from_display(obj.ptchOpts.Disp);
        end

        if exist('winInfo','var') && ~isempty(winInfo)
            obj.ptchOpts.winInfo=winInfo;
        elseif isempty(obj.ptchOpts.winInfo)
            obj.ptchOpts.winInfo.posXYZm=[0 0 obj.ptchOpts.Disp.scrnZmm./1000];
            obj.ptchOpts.winInfo.WHm=obj.ptchOpts.Disp.scrnXYmm./1000;
        end
        if exist('subjInfo','var') && ~isempty(subjInfo)
            obj.ptchOpts.subjInfo=subjInfo;
        elseif isempty(obj.ptchOpts.subjInfo)
            obj.ptchOpts.subjInfo.IPDm=0.065;
            obj.ptchOpts.subjInfo.LExyz=[-0.065/2 0 0 ];
            obj.ptchOpts.subjInfo.RExyz=[ 0.065/2 0 0 ];
        end
        if ~isempty(obj.ptchOpts.focInfo) && ~isempty(obj.ptchOpts.trgtInfo)
            obj.bDSP=1;
        end
    end
%% APPLY
    function p=apply_disparity_ptch(obj,p,disparity)
        if ~obj.bDSP
            error('Trgt/Display etc. not initialized');
        end
        p.apply_disparity(disparity);
    end
    function obj=apply_winInfo(obj,winInfo)
        p.apply_window(winInfo);
    end
    function obj=apply_trgtInfo(obj,trgtInfo)
        p.apply_trgtInfo(trgtInfo);
    end
    function obj=apply_focInfo(obj,focInfo)
        p.apply_focInfo(focInfo);
    end
    function obj=apply_subjInfo(obj,subjInfo)
        p.apply_focInfo(subjInfo);
    end

%% SET INFO
    function obj=set_trgtInfo(obj,trgtInfo)
        obj.init_disp(trgtInfo);
    end
    function obj=set_focInfo(obj,focInfo)
        obj.init_disp([],focInfo);
    end
    function obj=set_display(obj,Disp)
        obj.init_disp([],[],Disp);
    end
    function obj=set_winInfo(obj,winInfo)
        obj.init_disp([],[],[],winInfo);
    end
    function obj=set_subjInfo(obj,subjInfo)
        obj.init_disp([],[],[],[],subjInfo);
    end
%% SET INFO VALS
    function obj=set_disparity(obj,disparity)
        % NOTE EVERYTHING IN BASE UNITS (DEGREES)
        if ~obj.bDSP
            obj.ptchOpts.trgtInfo.trgtDsp=disparity;
            return
        end
        trgtInfo=obj.ptchOpts.trgtInfo;
        trgtInfo.trgtDsp=disparity;
        obj.set_trgtInfo(trgtInfo);
    end
end
end
