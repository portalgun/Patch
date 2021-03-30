classdef ptchs_blk < handle
% TODO handle opts
% TODO
properties(Hidden=true)
    Blk
    bBlk=0
    blkBins
    %key={'mode','lvlInd','blk','trl','intrvl','cmpInd','cmpNum','sel'};

    mode
    stdInd
    blk

end
methods
    function obj=apply_block_all(obj,alias)
        obj.load_blk(alias);
        obj.get_opts_from_blk();
        obj.init_INDSB();
    end
    function obj=exp_init(obj,alias,mode,lvlInd,blocks)
        obj.load_blk(alias);
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
                Sn.winInfo.WHdeg=val;
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
    function obj=load_blk(obj,alias)
        obj.Blk=Blk.load(alias);
        obj.bBlk=1;
    end
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
    function out=get_interval_im(obj,trl,intrvl)
        stmInd=obj.get_stmInd(trl,intrvl);
        p=obj.get_patch_blk(stmInd);
        out=p.im.img;
    end
    function p=get_patch_blk(obj,stmInd)
        optsInd=obj.get_opts_ind_from_stmInd(stmInd);
        dire=obj.get_dir();
        if isempty(obj.INDSB{stmInd})
            fname=[dire obj.fnamesB{stmInd}];
            p=ptch.load(fname);
        else
            p=obj.INDSB{stmInd};
        end
        p=obj.apply_ptchOpts(p,optsInd);
    end
    function ptchs=get_loaded_blk(obj)
        ptchs=obj.INDSB(obj.bLoadedB);
    end
    function obj=load_all_patches_blk(obj)
        inds=1:length(obj.fnamesB);
        obj.load_patches_blk(inds);
    end
    function obj=load_patches_blk(obj,inds)
        for i = 1:length(inds)
            obj.load_patch_blk(inds(i));
        end
    end
    function obj=load_patch_blk(obj,ind)
        p=obj.get_patch_blk(ind);

        obj.INDSB{ind}=p;
        obj.bLoadedB(ind)=true;
    end
%% CLEAR
    function obj=clear_not_needed(obj,trls,intrvls)
        loadedInd=find(obj.bLoadedB);
        if isempty(loadedInd)
            return
        end
        if ~exist('intrvls','var')
            intrvls=[];
        end
        stmInd=obj.get_stmInd(trls,intrvls);
        inds=loadedInd(~ismember(loadedInd,stmInd));

        obj.clear_blk(inds);
    end
    function obj=clear_blk(obj,inds)
        if ~exist('inds','var') || isempty(inds)
            obj.clear_loaded_blk();
        end
        for i = 1:inds
            ind=inds(i);
            obj.INDSB{ind}=[];
            obj.bLoadedB(ind)=false;
        end
    end
    function obj=clear_loaded_blk(obj)
        if ~any(obj.bLoadedB)
            return
        end
        obj.INDSB(obj.bLoadedB)={[]};
        obj.bLoadedB(obj.bLoadedB)=false;
    end
%% GET FROM BLK
    function bMotion=get_bMotion(obj)
        bMotion=obj.Blk.get_bMotion();
    end
    function val=get_stmXYdeg(obj,trl,intrvl)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('intrvl','var')
            intrvl=[];
        end
        val=obj.get_interval_opt(trl,intrvl,'winInfo','WHdeg');
    end
    function nStm=get_nStm(obj)
        nStm=obj.Blk.get_nStm();
    end
    function nTrl=get_nTrial(obj)
        nTrl=obj.Blk.get_nTrial();
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
        stdX=obj.Blk.get_stdX(trl);
    end
    function intrvl=get_cmpIntrvl(obj,trl,cmpNum)
        if ~exist('trl','var')
            trl=[];
        end
        if ~exist('cmpNum','var')
            cmpNum=[];
        end
        intrvl=obj.Blk.get_cmpIntrvl(trl,cmpNum);
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

end
end
