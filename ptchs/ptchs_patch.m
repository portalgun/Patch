classdef ptchs_patch < handle & ptch_link
properties(Hidden)
    ptchProps
    imProps
    imPropsPub
end
methods
%% GET
    function p=get_patch(obj,ind,opts,bRaw,bForce)
        if nargin < 5; bForce=false; end
        if nargin < 4 || isempty(bRaw); bRaw=~obj.bBlk; end
        if nargin < 3; opts=[]; end
        if isempty(obj.ptchProps)
            obj.ptchProps=fieldnames(Obj.struct(ptch));
            obj.imProps=fieldnames(Obj.struct(Map));
            obj.imPropsPub=fieldnames(Map);
        end

        if isempty(obj.dire)
            dire=obj.get_dir();
        else
            dire=obj.dire;
        end

        if ~obj.bBlk || bRaw
            ffld='fnames';
            ifld='INDS';
            pidx=ind;
            lind=ind;
        else
            ffld='fnames';
            ifld='INDSB';

            %B=obj.Blk.blk;
            %PIND=ismember_cell('P', B.KEY);
            %pidx=B.TABLE{PIND}(ind);

            s=substruct('.','Blk','.','blk','.','TABLE'); %,'{}','end','()',ind);
            t=builtin('subsref',obj,s);
            pidx=t{end}(ind);

            lind=ind;
        end
        if ~isempty(obj.(ifld){lind}) && ~bForce
            obj.ptch=obj.(ifld){lind};
        else
            fname=[dire obj.(ffld){pidx} '.mat'];
            obj.ptch=ptch.load(fname,obj.dbInfo,obj.genOpts); %% SLOW 2
            obj.ptch=obj.apply_ptchOpts(obj.ptch,ind,opts);  %% SLOW 1
        end
        if nargout > 0
            p=obj.ptch;
        end
    end
%% LOAD
    function p=load_patch(obj,inds,opts,bRaw,bForce)
        if nargin < 5; bForce=false; end
        if nargin < 4; bRaw=~obj.bBlk; end
        if nargin < 3; opts=[]; end

        if bRaw
            ifld='INDS';
            lfld='bLoaded';
        else
            ifld='INDSB';
            lfld='bLoadedB';
        end
        for i = 1:length(inds)
            if obj.(lfld)(inds(i))
                continue
            end
            obj.(ifld){inds(i)}=obj.get_patch(inds(i),opts,bRaw,bForce);
            obj.(lfld)(inds(i))=true;
        end
    end
%% CLEAR
    function p=clear(obj,inds,bRaw)
        if nargin < 3; bRaw=~obj.bBlk; end

        if bRaw
            if ischar(inds) && strcmp(inds,'all')
                inds=find(obj.bLoaded);
            end
            for i = 1:inds
                ind=inds(i);
                obj.INDS{ind}=[];
                obj.bLoaded(ind)=false;
            end
        else
            if ischar(inds) && strcmp(inds,'all')
                inds=find(obj.bLoadedB);
            end
            for i = 1:length(inds)
                ind=inds(i);
                obj.INDSB{ind}=[];
                obj.bLoadedB(ind)=false;
            end
        end
    end
%% PTCH OPTS
    function p=apply_ptchOpts(obj,p,ind,opts)

        if ~exist('ind','var')
            ind=[];
        end

        if isfield(opts,'bCrp')
            bCrp=opts.bCrp;
            opts=rmfield(opts,'bCrp');
        else
            bCrp=[];
        end
        if isfield(opts,'bZer')
            bZer=opts.bZer;
            opts=rmfield(opts,'bZer');
        else
            bZer=0;
        end


        if exist('opts','var') && ~isempty(opts) && isstruct(opts)
            Opts=opts;
            if ~isempty(obj.ptchOpts) && isstruct(obj.ptchOpts)
                Opts=obj.ptchOpts;
                if isfield(Opts,'bDSP')
                    Opts=rmfield(Opts,'bDSP');
                end
                Opts=Struct.combinePref(opts,Opts);
            end
        else
            Opts=obj.ptchOpts;
            if isfield(Opts,'bDSP')
                Opts=rmfield(Opts,'bDSP');
            end
        end
        if ~isfield(Opts,'subjInfo') || isempty(Opts.subjInfo) || numel(fieldnames(Opts.subjInfo)) < 1
            global VDISP;
            if ~isempty(VDISP)
                Opts.subjInfo=VDISP.SubjInfo;
            else
                Opts.subjInfo=SubjInfo();
            end
        end

        if isfield(Opts,'flatAnchor')
            flatAnchor=Opts.flatAnchor;
            %Opts=rmfield(Opts,'flatAnchor');
        else
            flatAnchor='';
        end
        if isfield(Opts,'genOpts')
            p.srcInfo.genOpts=Opts.genOpts;
            Opts=rmfield(Opts,'genOpts');
        end


        ignore={'duration'};
        flds=fieldnames(Opts);
        bIms=ismember_cell(flds,obj.imPropsPub); % SLOW
        bPtchs=ismember_cell(flds,obj.ptchProps);
        bIgnore=ismember_cell(flds,ignore);
        for i = 1:length(flds)
            fld=flds{i};
            prp=Opts.(fld);
            if isempty(prp) || bIgnore(i)
                continue
            end

            bIm=bIms(i);
            bPtch=bPtchs(i);

            P=prop_fun(prp,ind,bIm,bPtch);

            % handle meta vars
            if ischar(P) && startsWith(P,'@')
                fld=P(2:end);
                if bIm
                    if isfield(p.im,fld)
                        P=p.im.(fld);
                    elseif isfield(p,fld)
                        P=p.(fld);
                    end
                elseif bOther
                    P=p.other.(fld);
                else
                    if isfield(p,fld)
                        P=p.(fld);
                    elseif isfield(p.im,fld)
                        P=p.im.(fld);
                    end
                end
            end

            if bIm
                p.im.(fld)=P;
            end
            if bPtch
                p.(fld)=P;
            end

        end

        if bZer
            p.trgtInfo.trgtDsp=0;
        end

        if ~isfield(Opts,'bXYZTransform')
            flds={'bCenter','bScale','bSheer','bCorrectCtrXYZ','shrinkTo'};
            for i = 1:length(flds)
                if ~isempty(p.(flds{i})) && any(p.(flds{i}))
                    p.bXYZTransform=true;
                    break
                end
            end
        end
        if isempty(p.srcInfo.Val)
            p.srcInfo.Val=obj.idx.val(p.srcInfo.P);
        end

        % ptchs.bDSP = crop patch when laoded
        % ptch.bDSP  = cropped
        % bCrp       = override ptchs.bDSP
        if isempty(bCrp) && isfield(obj.ptchOpts,'bDSP')
            bCrp=obj.ptchOpts.bDSP;
        elseif ~isfield(obj.ptchOpts,'bDSP')
            bCrp=false;
        end

        if ~isempty(flatAnchor)
            p.flatten();
        end
        if isfield(Opts,'DispInfo')
            if isempty(obj.VDisp)
                obj.VDisp=VDisp(Opts.DispInfo);
            end
            p.Disp=obj.VDisp;
        end

        if obj.bAppliedOpt && obj.bSameWdw
            W=obj.W;
        else
            W=[];
        end

        if bCrp
            p.init_disp();
            if ~obj.bSameWin || ~obj.bAppliedOpt
                p.update_dsp(obj.bXYZ,W);
            else
                % TODO MORE OPTIONS HERE
               % d=p.trgtInfo.trgtDsp-obj.Win.obsDsp;
                d=obj.Win.obsDsp-p.trgtInfo.trgtDsp;
                p.win=obj.Win;
                p.win.Dsp=d;
                p.im.init2([],W);
            end
        else
            p.im.init2([],W);
        end
        if ~obj.bAppliedOpt && obj.bSameWin
            obj.W=p.im.W;
        end
        if obj.bSameWin
            obj.Win=p.win;
        end

        obj.bAppliedOpt=true;

        function [P]=prop_fun(prp,ind,bIm,bPtch)
            if isstruct(prp)
                if ~bIm && ~bPtch
                    dk
                end
                P=struct();
                fs=fieldnames(prp);
                for ii = 1:length(fs)
                    f=fs{ii};
                    if size(prp.(f),1) > 1
                        P.(f)=prp.(f)(ind,:);
                    else
                        P.(f)=prp.(f);
                    end
                end

            elseif size(prp,1) > 1 && (bIm || bPtch)
                P=prp(ind,:);
            else
                P=prp;
            end

        end
    end
%% BY SHAPE
    function P=load_patches_as_4Darray(obj,inds,bCrossed,bSpace)
        inds=inds(:);
        p=obj.get_patch(1);
        sz=size(p.im.img{1});
        if ~exist('bCrossed','var') || isempty(bCrossed)
            bCrossed=1;
        end
        if ~exist('bSpace','var') || isempty(bSpace)
            bSpace=0;
        elseif bSpace
            space=ones(sz)*.4;
        end
        PszRC=sz.*[1,2+bCrossed+bSpace];
        P=zeros([PszRC, 1, numel(inds)]);
        for i = 1:length(inds)
            p=obj.get_patch(inds(i));
            if bCrossed & bSpace
                P(:,:,1,i)=[p.im.img{1} p.im.img{2} p.im.img{1} space];
            elseif bSpace
                P(:,:,1,i)=[p.im.img{1} p.im.img{2}];
            elseif bCrossed
                P(:,:,1,i)=[p.im.img{1} p.im.img{2} p.im.img{1}];
            else
                P(:,:,1,i)=[p.im.img{1} p.im.img{2}];
            end
        end
    end
    function P=load_patches_as_3Darray(obj,inds,bCrossed,bSpace)
        inds=inds(:);
        p=obj.get_patch(1);
        sz=size(p.im.img{1});
        if ~exist('bCrossed','var') || isempty(bCrossed)
            bCrossed=1;
        end
        if ~exist('bSpace','var') || isempty(bSpace)
            bSpace=0;
        elseif bSpace
            space=ones(sz)*.4;
        end
        PszRC=sz.*[1,2+bCrossed+bSpace];
        P=zeros([PszRC, numel(inds)]);
        for i = 1:length(inds)
            p=obj.get_patch(inds(i));
            if bCrossed & bSpace
                P(:,:,i)=[p.im.img{1} p.im.img{2} p.im.img{1} space];
            elseif bSpace
                P(:,:,i)=[p.im.img{1} p.im.img{2}];
            elseif bCrossed
                P(:,:,i)=[p.im.img{1} p.im.img{2} p.im.img{1}];
            else
                P(:,:,i)=[p.im.img{1} p.im.img{2}];
            end
        end
    end
    function [P,bad]=load_patches_for_montage(obj,inds,bCrossed,bSpace,opts)
        inds=inds(:);
        p=obj.get_patch(inds(2),opts);
        sz=size(p.im.img{1});
        if ~exist('bCrossed','var') || isempty(bCrossed)
            bCrossed=1;
        end
        if ~exist('bSpace','var') || isempty(bSpace)
            bSpace=0;
        elseif bSpace
            space=ones(sz)*.4;
        end
        PszRC=sz.*[1,2+bCrossed+bSpace];
        P=cell(numel(inds),1);
        em=[ones(p.PszXY) ones(p.PszXY) zeros(p.PszXY)];
        bad=[];
        for i = 1:length(inds)
            try
                p=obj.get_patch(inds(i),opts);
            catch
                disp(inds(i))
                bad(end+1,1)=inds(i);
                continue
            end
            if bCrossed & bSpace
                P{i}=[p.im.img{1} p.im.img{2} p.im.img{1} space].^.4;
            elseif bSpace
                P{i}=[p.im.img{1} p.im.img{2} space].^.4;
            elseif bCrossed
                P{i}=[p.im.img{1} p.im.img{2} p.im.img{1}].^.4;
            else
                P{i}=[p.im.img{1} p.im.img{2}].^.4;
            end
        end
    end
    function obj=load_patches_as_cell(obj,inds)
        P=cell(length(inds),2);
        for i = 1:inds
            p=obj.get_patch(inds(i));
            p{i,1}=p.im.img{1};
            p{i,2}=p.im.img{2};
        end
    end
%% MISC
    function p=get_loaded(obj,bRaw)
        if nargin < 2; bRaw=~obj.bBlk; end
        if bRaw
            p=obj.INDS(obj.bLoaded);
        else
            p=obj.INDSB(obj.bLoadedB);
        end
    end
    function obj=getPatchStats(obj,name,titl,nORind,Popts)
        % PARSE
        statDet=ptchs.getStatDetails(name);
        if ~exist('titl','var') || isempty(titl)
            titl='';
        end
        if ~exist('nORind','var') || isempty(nORind)
            n=obj.length();
            ind=1:n;
        elseif numel(nORind)==1
            n=nORind;
            ind=1:n;
        else
            ind=Vec.row(nORind);
            n=max(ind);
        end
        if ~exist('Popts','var')
            Popts=[];
        end


        pr=Pr(n,1,'Processing Patches');
        statTable={statDet{1},statDet{2},statDet{3},'Patch','N'};
        obj.Stats=Stat(statTable,2,n);

        for i = ind
            pr.u();
            obj.iter_patch_stats(i,Popts);
        end
        pr.c();
    end
    function obj=iter_patch_stats(obj,ind,opts)
        % XXX MAKE PRIVATE
        obj.ptchOpts.Stats=obj.Stats;
        p=obj.get_patch(ind, opts);
        obj.Stats=p.Stats;

    end
    function obj=set_subj(obj,subjInfo)
        obj.ptchOpts.subjInfo=subjInfo;
    end
end
methods(Static)
    function out=getStatDetails(varargin)
        if nargin==1 && iscell(varargin{1})
            names=varargin{1};
        else
            names=varargin;
        end

        out={};
        for i = 1:length(names)
            name=names{i};
            switch name
                case 'dspRMS'
                    out=[out; {'getDspRMS','Disparity Contrast','arcmin'}];
                otherwise
                    error(['Unhandled stat case ' name ]);
            end
        end

    end
end
end
