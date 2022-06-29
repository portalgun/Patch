classdef ptchs_dsp < handle & ptch_link
methods
    function out = getDsp2(obj,inds)
        if nargin < 2 || isempty(inds)
            inds=1:obj.length;
        end
        num=length(inds);

        %buff=zeros(num,1);
        %map=zeros(num,1);
        %buffT=zeros(num,1);
        out=struct();
        out.src=nan(num,1);
        out.B=nan(num,1);
        out.d=nan(num,1);
        out.gen=nan(num,1);

        pr=Pr(num,1);
        for i = 1:num
            pr.u();

            try
                p=obj.get_patch(inds(i));
            catch ME
                if strcmp(ME.identifier,'MATLAB:load:couldNotReadFile') || strcmp(ME.identifier,'MATLAB:getReshapeDims:notSameNumel')
                    pr.append_msg(ME.message);
                    continue
                else
                    rethrow(ME);
                end
            end

            ind=p.srcInfo.P;

            out.src(i)=obj.idx.val(ind);
            out.B(i)=obj.idx.B(ind);

            assert(out.B(i)==p.srcInfo.B);
            assert(p.srcInfo.P==obj.Blk.blk(inds(i),'P').ret());

            %buffT(i)=p.getDspRMST();
            out.d(i)=p.getDspRMSD()/60;

        end
        %out=struct('map',map,'src',src,'buff',buff,'buff0',buff0);
        pr.c();
    end
    function obj=init_disp(obj,trgtInfo,focInfo,Disp,winInfo,subjInfo)
        if exist('trgtInfo','var') && ~isempty(trgtInfo)

            obj.set_trgtIinfo(trgtInfo);
        end

        if exist('focInfo','var') && ~isempty(focInfo)
            obj.set_focInfo(focInfo);
        end

        if exist('Disp','var') && isa(Disp,'VDisp')
            obj.set_display(Disp);
        end

        if exist('winInfo','var') && ~isempty(winInfo)
            obj.set_winInfo(winInfo);
        end

        if exist('subjInfo','var') && ~isempty(subjInfo)
            obj.set_subjInfo(subjInfo);
        end
    end
%% APPLY
    function obj=apply_display(obj,hostn,subjName)
        global VDISP;
        if isempty(hostn) && ~isempty(VDISP)
            hostn=VDISP.hostname;
        elseif isempty(hostn)
            hostn=Sys.hostname;
        end
        if isempty(VDISP)
            Error.warnSoft(['Applying default display to patches: ' hostn ]);
            obj.VDisp=VDisp(subjName,hostn);
        else
            obj.VDisp=VDISP;
        end
        obj.ptchOpts.DispInfo=hostn;
        obj.ptchOpts.subjInfo=obj.VDisp.SubjInfo;
    end
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

        obj.ptchOpts.focInfo=focInfo;
    end
    function obj=apply_subjInfo(obj,subjInfo)
        p.apply_subjInfo(subjInfo);
    end

%% SET INFO
    function check_dsp(obj)
        if ~isempty(obj.ptchOpts.focInfo) && ~isempty(obj.ptchOpts.trgtInfo)
            obj.bDSP=1;
        end
    end
    function obj=set_trgtInfo(obj,trgtInfo)
        obj.ptchOpts.trgtInfo=trgtInfo;
        obj.check_dsp();
    end
    function obj=set_focInfo(obj,focInfo)
        obj.ptchOpts.focInfo=focInfo;
        obj.check_dsp();
    end
    function obj=set_display(obj,Disp)

        if  exist('Disp','var') && ~isempty(Disp) && ischar(Disp)
            obj.ptchOpts.DispInfo=Disp;
            obj.ptchOpts.Disp=VDisp(Disp);
        elseif isa(Disp,'VDisp')
            obj.ptchOpts.Disp=Disp;
            obj.ptchOpts.DispInfo=VDisp.get_name_from_display(obj.ptchOpts.Disp);
        elseif isempty(obj.ptchOpts.Disp) && (~exist('Disp','var') || isempty(Disp))
            obj.ptchOpts.Disp=VDisp();
            obj.ptchOpts.DispInfo=VDisp.get_name_from_display(obj.ptchOpts.Disp);
        end
        obj.check_dsp();
    end
    function obj=set_winInfo(obj,winInfo)
        obj.ptchOpts.winInfo=winInfo;

        if isempty(obj.ptchOpts.winInfo)
            obj.ptchOpts.winInfo.posXYZm=[0 0 obj.ptchOpts.Disp.scrnZmm./1000];
            obj.ptchOpts.winInfo.WHm=obj.ptchOpts.Disp.scrnXYmm./1000;
        end
        obj.check_dsp();
    end
    function obj=set_subjInfo(obj,subjInfo)
        if ~exist('subjInfo','var') || isempty(subjInfo)
            subjInfo=SubjInfo.get_default();
        end
        obj.ptchOpts.subjInfo=subjInfo;
        obj.check_dsp();
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
