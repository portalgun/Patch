classdef ptchs_blk < handle & ptch_link
% TODO handle opts
% TODO
properties(Hidden=true)
    INDSB
    bLoadedB
    fnamesB

    Blk
    bBlk=0
    blkBins
    %key={'mode','lvlInd','blk','trl','intrvl','cmpInd','cmpNum','sel'};

    mode
    stdInd

    idxBlk
    blk
end
properties(Access=private)
end
methods(Hidden=true)
    function obj=clear_block_all(obj)
        obj.Blk=[];
        obj.bBlk=0;
        obj.mode=[];
        obj.stdInd=[];
        obj.blk=[];
        obj.blkBins=[];
        obj.INDSB=[];
        obj.bLoadedB=[];
        obj.fnamesB=[];
    end
    function obj=apply_block_all(obj,alias)
        obj.load_blk(alias);
        %g=obj.ptchOpts.genOpts;
        obj.get_opts_from_blk();
        obj.init_INDSB();
    end
    function obj=exp_init(obj,alias,mode,lvlInd,blocks)
        obj.load_blk(alias);
        p=obj.Blk('P');
        obj.select_block(mode,lvlInd,blocks);
        obj.get_opts_from_blk();
        obj.init_INDSB();
    end
    function obj=init_INDSB(obj)
        % XXX
        n=obj.Blk.get_nStm();
        obj.INDSB=cell(n,1);
        obj.bLoadedB=false(n,1);
        ind=obj.Blk.blk('P').ret();

        obj.fnamesB=obj.fnames(ind);
    end
    function obj=get_opts_from_blk(obj)
        S=obj.Blk.ret_opts_struct();
        flds=fieldnames(S);
        Sn=struct();
        Sn.trgtInfo=struct;
        Sn.focInfo=struct;
        Sn.subjInfo=struct;
        Sn.wdwInfo=struct;
        inds=[obj.Blk.blk('P').ret()];
        for i = 1:length(flds)
            fld=flds{i};
            val=S.(fld);
            switch fld
            case 'disparity'
                Sn.trgtInfo.trgtDsp=val;
            case 'trgtDispOrWin'
                Sn.trgtInfo.dispORwin=val;
            case 'trgtPosXYZm'
                Sn.trgtInfo.posXYZm=val;
            case 'focDispOrWin'
                Sn.focInfo.dispORwin=val;
            case 'focPosXYZm'
                Sn.focInfo.posXYZm=val;
            case 'stmPosXYZm'
                Sn.winInfo.posXYZm=val;
            case 'stmXYdeg'
                Sn.winInfo.WHdegRaw=val; % NOTE RAW
            case 'wdwPszRCT'
                Sn.wdwInfo.PszRCT=val;
            case 'wdwType'
                Sn.wdwInfo.type=val;
            case 'wdwRmpDm'
                Sn.wdwInfo.rmpDm=val;
            case 'wdwDskDm'
                Sn.wdwInfo.dskDm=val;
            case 'wdwSymInd'
                Sn.wdwInfo.symInd=val;
            case 'speed'
                % XXX
            case 'bins'
                obj.blkBins=val;
            otherwise
                Sn.(fld)=val;
            end
        end
        obj.ptchOpts=Sn;
    end
end
methods(Access=protected)
    function obj=load_blk(obj,aliasORblk)
        if isa(aliasORblk,'Blk')
            obj.Blk=aliasORblk;
        elseif ischar(aliasORblk);
            obj.Blk=Blk.load(aliasORblk);
        end
        obj.bBlk=1;
    end
end
methods
    function obj=select_block(obj,mode,lvlInd,blocks)
        obj.Blk=obj.Blk.select_block(mode,lvlInd,blocks);
    end
%%  INDECESS
    function idx=get_interval_idx(obj,trl,intrvl)
        ind=obj.Blk.blk('trl',trl,'intrvl',intrvl,'P').ret();

        if ind==obj.idx.P(ind);
            idx=ind;
        else
            idx=find(obj.idx.P==ind);
        end
    end
    function idx=get_cmp_idx(obj,trl,cmp)
        if ~exist('cmp','var') || isempty(cmp)
            cmp=1;
        end
        ind=obj.Blk.blk('trl',trl,'cmpInd',cmp,'P').ret();
        if ind==obj.idx.P(ind);
            idx=ind;
        else
            idx=find(obj.idx.P==ind);
        end
    end
    function idx=get_std_idx(obj,trl)
        ind=obj.Blk.blk('trl',trl,'cmpInd',0,'P').ret();
        if ind==obj.idx.P(ind);
            idx=ind;
        else
            idx=find(obj.idx.P==ind);
        end
    end
    function ind=get_stmInd(obj,trls,intrvls)
        if ~exist('intrvls','var') || isempty(intrvls)
            ind=obj.Blk.trial_to_stmInd(trls);
        else
            ind=obj.Blk.trial_intrvl_to_stmInd(trls,intrvls);
        end
    end
    function ind=get_opts_ind(obj,trl,intrvl)
        nTrial=obj.Blk.get_nTrial;
        nIntrvl=obj.Blk.get_nIntrvl;
        ind=sub2ind([nTrial nIntrvl],trl,intrvl);
    end
    function optsInd=get_opts_ind_from_stmInd(obj,stmInd)
        [trl,intrvl]=obj.Blk.stmInd_to_trial_interval(stmInd);
        optsInd=obj.get_opts_ind(trl,intrvl);
    end
%% LOAD BY
    function obj=load_trials(obj,trls)
        inds=obj.get_stmInd(trls);
        obj.load_patches_blk(inds);
    end
    function obj=load_trial(obj,trl)
        if ~exist('trl','var')
            trl=[];
        end
        idx=obj.get_stmInd(trl);
        obj.load_patches(obj,idx,trl);
    end
%% LOAD
    function out=is_stm_loaded(obj,trl,intrvl)
        stmInd=obj.get_stmInd(trl,intrvl);
        out=obj.bLoadedB(stmInd);
    end
    function [im,varargout]=get_interval_im(obj,trl,intrvl)
        stmInd=obj.get_stmInd(trl,intrvl);
        p=obj.get_patch_blk(stmInd);
        im=p.im.img;
        if nargout == 1
            return
        end
        if p.bDSP
            varargout{1}=p.maps.xyz;
        else
            varargout{1}=p.mapsBuff.xyz;
        end
        if nargout == 2
            return
        end
        varargout{3}=p;
    end
%% GET FROM BLK
    function bMotion=get_bMotion(obj)
        if ~isempty(obj.Blk)
            bMotion=obj.Blk.get_bMotion();
        else
            bMotion=0;
        end
    end
    function nStm=get_nStm(obj)
        nStm=obj.Blk.get_nStm();
    end
    function nTrl=get_nTrial(obj)
        if ~isempty(obj.Blk)
            nTrl=obj.Blk.get_nTrial();
        else
            nTrl=length(obj.fnames);
        end
    end
    function cmpX=get_cmpX(obj,trl,cmpNum)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('cmpNum','var')
            cmpNum=[];
        end
        cmpX=obj.Blk.get_cmpX(trl,cmpNum);
    end
    function stdX=get_stdX(obj,trl)
        if ~exist('trl','var')
            trl=[];
        end
        if ~isempty(obj.Blk)
            stdX=obj.Blk.get_stdX(trl);
        else
            stdX=zeros(numel(trl),1);
        end
    end
    function intrvl=get_cmpIntrvl(obj,trl,cmpNum)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('cmpNum','var')
            cmpNum=[];
        end
        if ~isempty(obj.Blk)
            intrvl=obj.Blk.get_cmpIntrvl(trl,cmpNum);
        else
            intrvl=0;
        end
    end
%% GET OPTS
    function val=get_duration(obj,trl,intrvl)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('intrvl','var')
            intrvl=[];
        end
        val=obj.get_interval_opt(trl,intrvl,[],'duration');
    end
    function val=get_stmXYdeg(obj,trl,intrvl)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('intrvl','var')
            intrvl=[];
        end
        val=obj.get_interval_opt(trl,intrvl,'winInfo','WHdegRaw');
    end
    function [X,Y]=get_stmXYpos(obj,trl,intrvl)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('intrvl','var')
            intrvl=[];
        end
        % XXX NOTE NEEDS TO BE CALCULATED
        stmXYpos=obj.P.ptch.win.win.posXYpix;
        TODO
        val=obj.get_interval_opt(trl,intrvl,'trgtInfo','posXYpix');
        X=val{1};
        Y=val{2};
    end
    function val=get_interval_opt(obj,trl,intrvl,fld,opt)
        if ~isempty(fld) && ~endsWith(fld,'Info')
            fld=[fld 'Info'];
        end
        if isempty(fld)
            vals=obj.ptchOpts.(opt);
        else
            vals=obj.ptchOpts.(fld).(opt);
        end
        if size(vals,1)==1
            val=vals;
            return
        else
            ind=obj.get_opts_ind(trl,intrvl);
            val=vals(ind,:,:,:,:);
        end
    end
    function [dims,names]=get_dims(obj)
        out=fldsMatchDims(obj.ptchOpts,1,size(obj.fnamesB,1));
        inds=vertcat(out{:,2});
        dims=out(inds,1);

        names=cellfun(@(x) Blk_con.ptchOpts_struct_names_to_blk_names(x),dims,'UniformOutput',false);
    end
end
end
