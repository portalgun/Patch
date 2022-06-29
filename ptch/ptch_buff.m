classdef ptch_buff < handle & ptch_link
methods(Access= ?ptch_link)
%% CROP BUFMAPPS
    function obj=setMapBuff(obj,val,map,k)
        if ~isfield(obj.mapsBuff,map)
            obj.mapsBuff.(map)=cell(2);
        end
        obj.mapsBuff.(map){k}=val;
    end
    function map=getMapBuff(obj,mapName,k)
        if ~isfield(obj.mapsBuff,mapName);
            obj.mapsBuff.(mapName)=cell(1,2);
        end

        if isempty(obj.mapsBuffT.(mapName){k})
            obj.mapsBuff.(mapName){k}=obj.mapsBuff.(mapName){k};
        end
        map=obj.mapsBuff.(mapName){k};
    end
    function obj=crop_buffs(obj,rule,interpType,bXYZ,I)
        if nargin < 5
            I=1:2;
        end
        if nargin < 4
            bXYZ=[];
        end
        if nargin < 3
            interpType=[];
        end
        if nargin < 2
            rule=[];
        end

        flds=fieldnames(obj.mapsBuff);
        for k = I
        for m=1:numel(flds)
            fld=flds{m};
            if strcmp(fld,'CPs') || (~bXYZ && strcmp(fld,'xyz'))
                continue
            else
                obj.crop_buff(k,fld,rule,interpType);
            end
        end
        end
    end
    function obj=crop_buff(obj,k,fld,rule,interpType)
        if isempty(interpType)
            interpType=obj.cropInterpType;
        end
        PctrRC=obj.select_PctrRC_crop(k,rule);
        K=obj.srcInfo.K;
        im=obj.mapsBuff.(fld);
        if iscell(im{K})
            im=im{K}{k};
        elseif isempty(im{k})
            return
        else
            im=im{k};
        end

        obj.maps.(fld){k}=Map.crop_f(im,PctrRC,obj.PszRC,interpType);
    end
    function PctrRC=select_PctrRC_crop(obj,k,rule)
        if isempty(rule)
            rule=obj.cropRule;
        end
        if iscell(obj.PctrCPs{k})
            PctrRC=zeros(2,2);
            for i =1:2
                PctrRC(i,2)=obj.PctrCPs{i}{k}+obj.PszRCbuff/2;
            end

            if k == 1; nK=2; else; nk =1; end;
            switch rule
            case {'match','mtch'}
                out=PctrRC(k,:);
            case {'oppostie','opp'}
                out=PctrRC(nk,:);
            case {'med','median'}
                out=median(PctrRC,1);
            case 'mean'
                out=mean(PctrRC,1);
            end
            PctrRC=out;
        else
            PctrRC=obj.PctrCPs{k};
        end
    end
%% CPS
    function cps=get_buff_CPs(obj,I)
        if nargin < 2
            I=1:2;
            obj.CPsBuff=cell(2,1);
        end
        % make ptch center [0,0]
        cps=cell(1,2);

        for k = I
            [obj.CPsBuff{k}{1},obj.CPsBuff{k}{2}]=CPs.getPatchFast(obj.srcInfo.PctrRC{k}, obj.src.AitpRC0, k, obj.src.CPs, obj.srcInfo.db.IszRC,true);
        end
    end
    function obj=rm_CPs_outside_buff(obj,bHard,I)
        if nargin < 2 || isempty(bHard)
            bHard=false;
        end
        if nargin < 3
            I=1:2;
        end
        for i = I
        for k = 1:2
            if k==1; nk=2; elseif k==2; nk=1; end
            RA=abs(obj.CPsBuff{i}{k}(:,1)) > obj.PszRCbuff(1)/2;
            CA=abs(obj.CPsBuff{i}{k}(:,2)) > obj.PszRCbuff(2)/2;

            RB=abs(obj.CPsBuff{i}{nk}(:,1)) > obj.PszRCbuff(1)/2;
            CB=abs(obj.CPsBuff{i}{nk}(:,2)) > obj.PszRCbuff(2)/2;

            % if there is any point in either buff, keep it
            if bHard
                ind=(RA | CA) | (RB | CB);
            else
                ind=(RA & CA) | (RB & CB);
            end

            obj.CPsBuff{i}{k}(ind,:)=[];
            obj.CPsBuff{i}{nk}(ind,:)=[];
        end
        end
    end
end
end
