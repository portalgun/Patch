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
            bIm=false;
            if isempty(prp)
                continue
            elseif size(prp,1) > 1 && isprop(p,fld)
                P=prp(ind,:);
            elseif isprop(p,fld)
                P=prp;
            elseif size(prp,1) > 1 && isprop(p.im,fld)
                bIm=true;
                P=prp(ind,:);
            elseif isprop(p.im,fld)
                bIm=true;
                P=prp();
            else
                fld
                dk
            end


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
    end
%% EXP
%% BASIC LOAD
    function P=load_patches_as_4Darray(obj,inds)
        inds=inds(:);
        p=obj.get_patch(1);
        PszRC=size(p.im.img{1}).*[1,2];
        P=zeros([PszRC, 1, numel(inds)]);
        for i = 1:length(inds)
            p=obj.get_patch(inds(i));
            P(:,:,1,i)=[p.im.img{1} p.im.img{2}];
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
