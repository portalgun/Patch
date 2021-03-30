classdef ptchs_load < handle
methods
%% GET
    function p=get_patch(obj,ind)
        if ~exist('ind','var')
            ind=[];
        end
        if obj.bBlk && ~isempty(ind)
            p=obj.get_patch_blk(ind);
        else
            p=obj.get_patch_raw(ind);
        end
    end
    function p=get_loaded(obj)
        if obj.bBlk
            obj.get_loaded_blk();
        else
            obj.get_loaded_raw();
        end
    end
    function p=load_all_patches(obj)
        if obj.bBlk
            obj.load_all_patches_blk();
        else
            obj.load_all_patches_raw();
        end
    end
    function p=load_patches(obj,inds)
        if obj.bBlk
            obj.load_patches_blk(inds);
        else
            obj.load_patches_raw(inds);
        end
    end
    function p=load_patch(obj,ind)
        if obj.bBlk
            obj.load_patch_blk(ind);
        else
            obj.load_patch_raw(ind);
        end
    end
    function p=clear(obj,inds)
        if ~exist('inds','var')
            inds=[];
        end

        if obj.bBlk
            obj.clear_blk(inds);
        else
            obj.clear_raw(inds);
        end
    end
    function p=clear_loaded(obj,inds)
        if obj.bBlk
            obj.clear_loaded_blk();
        else
            obj.clear_loaded_raw();
        end
    end
%% CLEAR
    function p=apply_ptchOpts(obj,p,ind)
        if ~exist('ind','var')
            ind=[];
        end
        flds=fieldnames(obj.ptchOpts);

        ignore={'duration'};
        for i = 1:length(flds)
            fld=flds{i};
            prp=obj.ptchOpts.(fld);
            if isempty(prp) || ismember(fld,ignore)
                continue
            end
            [bIm,P]=prop_fun(p,prp,fld,ind);

            % handle meta vars
            if ischar(P) && startsWith('@')
                fld=P(2:end);
                if bIm
                    if isfield(p.im,fld)
                        P=p.im.(fld);
                    elseif isfield(p,fld)
                        P=p.(fld);
                    end
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
            else
                p.(fld)=P;
            end

        end
        if ~p.bDSP
            p.im.init2;
        else
            p.init_disp();
        end
        function [bIm,P]=prop_fun(p,prp,fld,ind)
            bIm=false;
            if isstruct(prp)
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
                if isprop(p.im,fld)
                    bIm=true;
                elseif ~isprop(p,fld)
                    fld
                    11
                    dk
                end

            elseif size(prp,1) > 1 && isprop(p.im,fld)
                bIm=true;
                P=prp(ind,:);
            elseif isprop(p.im,fld)
                bIm=true;
                P=prp();
            elseif size(prp,1) > 1 && isprop(p,fld)
                P=prp(ind,:);
            elseif isprop(p,fld)
                P=prp;
            elseif ~isprop(p,fld)
                fld
                22
                dk
            end
        end
    end
%% EXP
%% BASIC LOAD
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
    function P=load_patches_for_montage(obj,inds,bCrossed,bSpace)
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
        P=cell(numel(inds),1);
        for i = 1:length(inds)
            p=obj.get_patch(inds(i));
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
    function obj=load_all_patches_minimal(obj)
        % TODO
    end
%% RAW
    function p=get_patch_raw(obj,idx)
        % idx patch number

        dire=obj.get_dir();
        if isempty(obj.INDS{idx})
            fname=[dire obj.fnames{idx}];
            p=ptch.load(fname);
        else
            p=obj.INDS{idx};
        end
        p=obj.apply_ptchOpts(p,idx);
    end
    function ptchs=get_loaded_raw(obj)
        ptchs=obj.INDS(obj.bLoaded);
    end
    function obj=load_all_patches_raw(obj)
        inds=1:length(obj.fnames);
        obj.load_patches(inds);
    end
    function obj=load_patches_raw(obj,inds)
        for i = 1:length(inds)
            obj.load_patch(inds(i));
        end
    end
    function obj=load_patch_raw(obj,ind)
        p=obj.get_patch_raw(ind);

        obj.INDS{ind}=p;
        obj.bLoaded(ind)=true;
    end
    %% CLEAR
    function obj=clear_raw(obj,inds)
        for i = 1:inds
            ind=inds(i);
            obj.INDS{ind}=[];
            obj.bLoaded(ind)=false;
        end
    end
    function obj=clear_loaded_raw(obj)
        if ~any(obj.bLoaded)
            return
        end
        obj.INDS(obj.bLoaded)={[]};
        obj.bLoaded(obj.bLoaded)=false;
    end
end
methods(Static)
end
end
