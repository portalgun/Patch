classdef ptchs_load < handle
methods
%% GET
    function ptchs=get_loaded(obj)
        ptchs=obj.INDS(obj.bLoaded);
    end
    function p=get_patch(obj,ind)
        dire=obj.get_dir();
        if isempty(obj.INDS{ind})
            fname=[dire obj.fnames{ind}];
            p=ptch.load(fname);
        else
            p=obj.INDS{ind};
        end
        p=obj.apply_ptchOpts(p,ind);
    end
    function p=apply_ptchOpts(obj,p,ind)
        flds=fieldnames(obj.ptchOpts);
        for i = 1:length(flds)
            fld=flds{i};
            prp=obj.ptchOpts.(fld);
            if isempty(prp)
                continue
            elseif size(prp,1) > 1 && isprop(p,fld)
                p.(fld)=prp(ind,:);
            elseif isprop(p,fld)
                p.(fld)=prp;
            elseif size(prp,1) > 1 && isprop(p.im,fld)
                p.im.(fld)=prp(ind,:);
            elseif isprop(p.im,fld)
                p.im.(fld)=prp();
            else
                fld
                dk
            end

        end
        p.init_disp();
        if ~p.bDSP
            p.im.init2;
        end
    end
%% EXP
    function obj=load_interval(obj,trl,intrvl)
        inds=find(obj.idx.trls==trl & obj.idx.intrvl==intrvl);
        obj.load_patches(obj.inds);
    end
    function obj=load_cmp(obj,trl,cmp)
        if ~exist('cmp','var') || isempty(cmp)
            cmp=1;
        end
        inds=find(obj.idx.trls==trl & obj.idx.cmp==0);
        obj.load_patches(obj,inds);
    end
    function obj=load_std(obj,trl)
        inds=find(obj.idx.trls==trl & obj.idx.cmp==0);
        obj.load_patches(obj,inds);
    end
    function obj=load_trials(obj,trls)
        inds=find(ismember(obj.idx.trls,trls));
        obj.load_patches(obj,inds);
    end
    function obj=load_trial(obj,trl)
        inds=find(obj.idx.trls==trl);
        obj.load_patches(obj,inds);
    end
%% BASIC LOAD
    function obj=load_all_patches_minimal(obj)
        % TODO
    end
    function obj=load_all_patches(obj)
        inds=1:length(obj.fnames);
        obj.load_patches(inds);
    end
    function obj=load_patches(obj,inds)
        for i = 1:inds
            obj.load_patch(inds(i));
        end
    end
    function obj=load_patch(ind)
        p=obj.get_patch(ind);

        obj.INDS{ind}=p;
        obj.bLoaded(ind)=true;
    end
%% CLEAR
    function obj=clear_patches(obj,inds)
        for i = 1:inds
            ind=inds(i);
            obj.INDS{ind}=[];
            obj.bLoaded(ind)=false;
        end
    end
    function obj=clear_loaded_patches(obj)
        if ~any(obj.bLoaded)
            return
        end
        obj.INDS{obj.bLoaded}=[];
        obj.bLoaded(obj.bLoaded)=false;
    end
end
end
