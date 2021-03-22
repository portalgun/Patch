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
    end
    function obj=exp_init(obj,alias,mode,lvlInd,blocks)
        obj.load_blk(alias);
        obj.select_blk(mode,lvlInd,block);
        obj.get_opts_from_blk();
    end
    function obj=get_opts_from_blk(obj)
        S=obj.Blk.ret_opts_struct();
        flds=fieldnames(S);
        Sn=struct();
        Sn.trgtInfo=struct;
        Sn.focInfo=struct;
        Sn.subjInfo=struct;
        Sn.wdwInfo=struct;
        inds=obj.Blk.blk('P').ret();
        for i = 1:length(flds)
            fld=flds{i};
            if size(S.(fld),1) > 2
                sz=size(S.(fld));
                val=nan([size(obj.fnames), sz(2:end)]);
                val(inds,:,:,:,:)=S.(fld);
            else
                val=S.(fld);
            end
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
    function obj=select_block(obj,BLK,mode,lvlInd,block)
        obj.Blk=obj.Blk.select_block(mode,lvlInd,blocks);
    end
%%  INDECESS
    function idx=get_interval_idx(obj,trl,intrvl)
        ind=obj.Blk.blk('trl',trl,'intrvl',intvl,'P').ret();
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
    function idx=get_trl_idx(obj,trl)
        ind=obj.Blk.blk('trl',trl,'sel').ret();
        idx=find(obj.P.idx==ind);
        if ind==obj.idx.P(ind);
            idx=ind;
        else
            idx=find(obj.idx.P==ind);
        end
    end
%% LOAD
    function out=load_interval_im(obj,trl,intrvl)
        idx=get_intrvl_idx(trl,intrvl);
        p=obj.get_ptch(idx);
        out=p.im.img;
    end
    function obj=load_trials(obj,trls)
        idx=obj.get_trl_idx(trls);
        obj.load_patches(idx);
    end
    function obj=load_trial(obj,trl)
        idx=find(obj.idx.trls==trl);
        obj.load_patches(obj,idx);
    end

end
end
