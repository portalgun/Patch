classdef ptch_dsp < handle
methods
    %% INIT 2
    function obj=init_disp(obj,trgtInfo,focInfo,Disp,winInfo,subjInfo)
        % NOTE EVERYTHING IN BASE UNITS (DEGREES)
        % from ptchs, called on by apply_ptchOpts
        if exist('trgtInfo','var') && ~isempty(trgtInfo)
            obj.trgtInfo=trgtInfo;
        end

        if exist('Disp','var') && isa(Disp,'DISPLAY')
            obj.Disp=Disp;
            obj.DispInfo=DISPLAY.get_name_from_display(obj.Disp);
        elseif  exist('Disp','var') && ischar(Disp)
            obj.DispInfo=Disp;
            obj.Disp=DISPLAY(Disp);
        elseif isempty(obj.Disp)
            obj.Disp=DISPLAY.get_display_from_hostname();
            obj.DispInfo=DISPLAY.get_name_from_display(obj.Disp);
        end
        if exist('winInfo','var') && ~isempty(winInfo)
            obj.winInfo=winInfo;
        elseif isempty(obj.winInfo)
            obj.winInfo.posXYZm=[0 0 0];
            obj.winInfo.WHm=obj.Disp.scrnXYmm./1000;
        end
        if exist('focInfo','var') && ~isempty(focInfo)
            obj.focInfo=focInfo;
        elseif isempty(obj.focInfo)
            obj.focInfo=struct();
            obj.focInfo.posXYZm=obj.winInfo.posXYZm;
            obj.focInfo.dispORwin='disp';
        end
        if exist('subjInfo','var') && ~isempty(subjInfo)
            obj.subjInfo=subjInfo;
        elseif isempty(obj.subjInfo)
            obj.subjInfo.IPDm=0.065;
            obj.subjInfo.LExyz=[-0.065/2 0 0];
            obj.subjInfo.RExyz=[ 0.065/2 0 0];
        end

        if ~isempty(obj.Disp) && ~isempty(obj.trgtInfo) && ~isempty(obj.focInfo)
            obj.bDSP=1;
            obj.update_dsp();
        end
    end
    function obj=update_dsp(obj)
        % NOTE EVERYTHING IN BASE UNITS (DEGREES)

        obj.get_win();
        obj.get_trgt_CPs();

        yesmaps={'CPs','xyz','vrg','vrs'};
        if any(ismember(obj.mapNames,yesmaps));
            obj.get_map_CPs_bi();
        end
        if ismember('xyz',obj.mapNames)
            obj.get_map_xyz_bi();
        end
        if ismember('vrg',obj.mapNames)
            obj.get_map_vrg_bi();
        end
        obj.crop_mapsbuff_bi();

        % IM
        obj.get_default_masks();

        obj.reapply_map_bi();
        obj.im.init2();
        obj.bDSP=1;
    end
%% GET
    function obj=get_win(obj)
        trgtInfo=obj.get_trgt_base();
        focInfo=obj.get_foc_base();
        winInfo=obj.get_win_base();

        obj.win=DspDispWin(    ....
                               obj.trgtInfo.trgtDsp,...
                               obj.Disp,...
                               winInfo,...
                               obj.trgtInfo.dispORwin,...
                               trgtInfo,...
                               obj.focInfo.dispORwin,...
                               focInfo);
    end
    function trgtInfo=get_trgt_base(obj)
        trgtInfo=rmfield(obj.trgtInfo,'trgtDsp');
        trgtInfo=rmfield(trgtInfo,'dispORwin');
    end
    function focInfo=get_foc_base(obj)
        focInfo=rmfield(obj.focInfo,'dispORwin');
    end
    function winInfo=get_win_base(obj)
        winInfo=obj.winInfo;
        winInfo.subjInfo=obj.subjInfo;
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
    %% WIN
    function obj=set_win_WHm(obj,val)
        obj.set_winWH('WHm',val);
    end
    function obj=set_win_WHpix(obj,val)
        obj.set_win_WH('WHpix',val);
    end
    function obj=set_win_WHdeg(obj,val)
        obj.set_win_WH('WHdeg',val);
    end
    function obj=set_win_WHdegRaw(obj,val)
        obj.set_win_WH('WHdegRaw',val);
    end
    function obj=set_win_posXYZm(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('win','posXYZm',pos,dispORwin);
    end
    function obj=set_win_posXYZpix(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('win','posXYZm',pos,dispORwin);
    end
    function obj=set_win_posXYZpixRaw(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('win','posXYZm',pos,dispORwin);
    end
    function obj=set_win_vrg(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('win','vrg',pos,dispORwin);
    end
    function obj=set_win_vrs(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('win','vrs',pos,dispORwin);
    end
    %% TRGT
    function obj=set_disparity(obj,disparity)
        % NOTE EVERYTHING IN BASE UNITS (DEGREES)
        if ~obj.bDSP
            obj.trgtInfo.trgtDsp=disparity;
            return
        end
        trgtInfo=obj.trgtInfo;
        trgtInfo.trgtDsp=disparity;
        obj.set_trgtInfo(trgtInfo);
    end
    function obj=set_trgt_posXYZm(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('trgt','posXYZm',pos,dispORwin);
    end
    function obj=set_trgt_posXYZpix(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('trgt','posXYZm',pos,dispORwin);
    end
    function obj=set_trgt_posXYZpixRaw(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('trgt','posXYZm',pos,dispORwin);
    end
    function obj=set_trgt_vrg(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('trgt','vrg',pos,dispORwin);
    end
    function obj=set_trgt_vrs(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('trgt','vrs',pos,dispORwin);
    end
    %% FOC
    function obj=set_foc_posXYZm(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('foc','posXYZm',pos,dispORwin);
    end
    function obj=set_foc_posXYZpix(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('foc','posXYZm',pos,dispORwin);
    end
    function obj=set_foc_posXYZpixRaw(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('foc','posXYZm',pos,dispORwin);
    end
    function obj=set_foc_vrg(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('foc','vrg',pos,dispORwin);
    end
    function obj=set_foc_vrs(pos,dispORwin)
        if ~exist('dispORwin','var'); dispORwin=[]; end
        obj.set_pos('foc','vrs',pos,dispORwin);
    end
    %% HELPERS
%%  UDPATE DISP
end
methods(Access=private)
    function obj=set_win_WH(obj,fld,WH)
        obj.winInfo.WHm=[];
        obj.winInfo.WHpix=[];
        obj.winInfo.WHdegRaw=[];
        obj.winInfo.WHdeg=[];
        obj.winInfo.(fld)=WH;

        obj.winInfo.dispORwin=dispORwin;
        obj.set_winInfo(obj.winInfo);
    end
    function obj=set_pos(obj,trgtORfocORwin,fld, pos,dispORwin)
        name=[trgtORfocORwin 'Info'];
        if (~exist('dispORwin','var') || isempty(dispORwin)) && isfield(obj.(name),'dispORwin') && ~isempty(obj.(name).dispORwin)
            dispORwin=obj.(name).dispORwin;
        elseif  (~exist('dispORwin','var') || isempty(dispORwin))
            dispORwin='disp';
        end
        obj.(name).posXYZm=[];
        obj.(name).posXYpix=[];
        if ~strcmp(fld,'vrs')
            obj.(name).vrg=[];
        end
        if ~strcmp(fld,'vrg')
            obj.(name).vrs=[];
        end
        obj.(name).(fld)=pos;
        obj.(name).dispORwin=dispORwin;
        obj.(['set_' name]).(obj.(name));
    end
end
end
