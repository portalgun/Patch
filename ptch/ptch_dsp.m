classdef ptch_dsp < handle & ptch_link
methods
    %% INIT 2
    function init_disp(obj,trgtInfo,focInfo,Disp,winInfo,subjInfo)
        % NOTE EVERYTHING IN BASE UNITS (DEGREES)
        % from ptchs, called on by apply_ptchOpts
        if exist('trgtInfo','var') && ~isempty(trgtInfo)
            obj.trgtInfo=trgtInfo;
        end

        if nargin >= 4 && ~isempty(Disp)
            if isa(Disp,'VDisp')
                obj.Disp=Disp;
                obj.DispInfo=VDisp.get_name_from_display(obj.Disp);
            elseif schar(Disp)
                obj.DispInfo=Disp;
                obj.Disp=VDisp(Disp);
            end
        elseif ~isempty(obj.DispInfo) && isempty(obj.Disp)
            obj.Disp=VDisp(obj.DispInfo);
        elseif isempty(obj.DispInfo) && isempty(obj.Disp)
            obj.Disp=VDisp();
            obj.DispInfo=VDisp.get_name_from_display(obj.Disp);
        end

        if exist('winInfo','var') && ~isempty(winInfo)
            obj.winInfo=winInfo;
        elseif isempty(obj.winInfo) && (~exist('winInfo','var') || isempty(winInfo))
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
            obj.subjInfo=SubjInfo.get_default;
        end

        if ~isempty(obj.trgtInfo)
            obj.bDSP=1;
            %obj.update_dsp();
        end
    end
    function obj=update_dsp(obj,bXYZ,W)
        % NOTE EVERYTHING IN BASE UNITS (DEGREES)
        if nargin < 2 || isempty(bXYZ)
            bXYZ=true;
        end
        if nargin < 3
            W=[];
        end

        % CENTRAL GEOMETRY
        obj.get_win(); % NOTE BOTTLENECK 1 60&
                       % (win3D, then PointDispWin3D creation)
        obj.win_to_patch_CPs();

        if bXYZ
            obj.select_xyz(); % 15%
        end
        obj.select_pht();
        obj.get_default_masks();

        % IM
        obj.reapply_map();
        if ~isempty(obj.im)
            obj.im.init2([],W); % 15%
        end

        obj.bDSP=1;
    end
    function obj=select_xyz(obj)
        % TRANSFORM
        obj.bPhtTransform=obj.bPhtTransform || strcmp(obj.primaryPht,'t');
        obj.bXYZTransform=obj.bXYZTransform || strcmp(obj.primaryXYZ,'t') || obj.bPhtTransform;

        if obj.bXYZTransform
            obj.get_xyz_transform();
            obj.get_transform_CPs(k); % xyz -> CP
        end

        % DISPLAY
        if obj.bXYZDisplay || strcmp(obj.primaryXYZ,'d')
            obj.get_xyz_display(obj.srcInfo.K);
        end

        switch obj.primaryXYZ
        case 'd'
            obj.maps.xyz=obj.maps.xyzD;
        case 't'
            obj.maps.xyz=obj.maps.xyzT;
        case 's'
            obj.maps.xyz=obj.maps.xyzS;
        end

        % VRG MAP
        if ismember_cell('vrg',obj.mapNames)
            obj.get_map_vrg();
        end
    end
    function obj=select_pht(obj)
        % TRANSFORM
        if obj.bPhtTransform
            obj.get_transform_maps(k); % CP -> pht
        end
        % DISPLAY
        if obj.bPhtSource
            obj.crop_buffs(obj.cropRule,obj.cropInterpType,false); % NOTE considers bTransform
        end
    end
    function obj=win_to_patch_CPs(obj)
        obj.PctrCPs=obj.win.get_patch_CPs(obj.PszRC,obj.PszRCbuff);
    end
%% GET

    function obj=get_win(obj)
        %trgtInfo=obj.get_trgt_base();

        %winInfo=obj.winInfo;
        %if ~isa(winInfo,'Win3D')
        %    winInfo.subjInfo=obj.subjInfo;
        %end

        % BOTTLENECK
        obj.win=DspDispWin( ...
                               obj.Disp, ...
                               obj.winInfo,...
                               obj.trgtInfo,...
                               obj.focInfo);
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

    function out=getCtrZDiff(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        t=obj.getCtrTrgtXYZ;
        c=obj.getCtrXYZ(k);
        out=c(3)-t(3);
    end
    function out=getCtrXYZArcmin(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        xyz=obj.getCtrXYZ(k);
        out=obj.win.xyzToDspArcmin(xyz);
    end
    function out=getCtrTrgtXYZ(obj)
        out=obj.win.trgt.pos.posXYZm;
    end
    function out=getCtrXYZ(obj,k,type)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        if ~exist('type','var') || isempty(type)
            type='maps';
        end
        xyz=obj.(type).xyz{k};
        ctr=floor(size(xyz(:,:,1))/2);
        out=transpose(squeeze(xyz(ctr(1),ctr(2),:)));
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
