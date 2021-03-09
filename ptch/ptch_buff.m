classdef ptch_buff < handle
properties
end
methods
%% CPS
    function obj=get_buff_CPs_bi(obj)
        % Pctr becomes center of patch, zero disparity at center
        obj.CPsBuff=cell(2,1);
        for i = 1:2
            obj.CPsBuff{i}=obj.get_buff_CPs(i);
        end
        obj.rm_CPs_outside_buff_bi();
    end
    function CPs=get_buff_CPs(obj,i)
        % make ptch center [0,0]
        CPs=cell(1,2);
        for j = 1:2
            PctrRC=obj.srcInfo.PctrRC;
            if iscell(PctrRC)
                PctrRC=PctrRC{j};
            end
            CPs{j}=shiftFun(PctrRC, obj.src.CPs{i}{j});
        end
        function CPs=shiftFun(PctrRC,CPs)
            CPs=CPs-PctrRC;
        end
    end
    function obj=rm_CPs_outside_buff_bi(obj)
    % remove CPs outside of buff
        for i = 1:2
            obj.rm_CPs_outside_buff(i);
        end
    end
    function obj=rm_CPs_outside_buff(obj,i)
        for k = 1:2
            if k==1; nk=2; elseif k==2; nk=1; end
            RA=abs(obj.CPsBuff{i}{k}(:,1)) > obj.PszRCbuff(1)/2;
            CA=abs(obj.CPsBuff{i}{k}(:,2)) > obj.PszRCbuff(2)/2;

            RB=abs(obj.CPsBuff{i}{nk}(:,1)) > obj.PszRCbuff(1)/2;
            CB=abs(obj.CPsBuff{i}{nk}(:,2)) > obj.PszRCbuff(2)/2;

            % if there is any point in either buff, keep it
            ind=(RA & CA) | (RB & CB);

            obj.CPsBuff{i}{k}(ind,:)=[];
            obj.CPsBuff{i}{nk}(ind,:)=[];
        end
    end
%% CROP
    function obj=crop_mapsbuff_bi(obj,rule,interpType)
        if ~exist('rule','var')
            rule=[];
        end
        if ~exist('interpType','var')
            interpType=[];
        end
        for i = 1:2
            obj.crop_mapsbuff(i,rule,interpType);
        end
    end
    function obj=crop_mapsbuff(obj,i,rule,interpType)
        if ~exist('rule','var')
            rule=[];
        end
        if ~exist('interpType','var')
            interpType=[];
        end

        flds=fieldnames(obj.mapsbuff);
        for m=1:numel(flds)
            fld=flds{m};
            if strcmp(fld,'CPs')
                continue
            else
                obj.shift_maps(i,fld,rule,interpType);
            end
        end
    end
    function obj=shift_maps_bi(obj,fld,rule,interpType)
        for k = 1:(obj.bStereo+1)
            obj.shift_maps(k,fld);
        end
    end
    function obj=shift_maps(obj,k,fld,rule,interpType)
        if isempty(interpType)
            interpType='linear';
        end
        if isempty(rule)
            rule='match';
        end
        if iscell(obj.PctrCPs{k})
            PctrRC=zeros(2,2);
            for i =1:2
                PctrRC(i,2)=obj.PctrCPs{i}{k};
            end

            if k == 1; nK=2; else; nk =1; end
            switch rule
            case {'match','mtch'}
                PctrRC=PctrRC(k,:);
            case {'oppostie','opp'}
                PctrRC=PctrRC(nk,:);
            case {'med','median'}
                PctrRC=median(PctrRC,1);
            case 'mean'
                PctrRC=mean(PctrRC,1);
            end
        else
            PctrRC=obj.PctrCPs{k};
        end

        im=obj.mapsbuff.(fld){k};
        obj.maps.(fld){k}=Map.crop_f(im,PctrRC,obj.PszRC,interpType);
    end
%% VRG
end
end
