classdef ptch_src < handle
%% SRC
methods
    function obj=get_map_srcs(obj)
        for i = 1:length(obj.mapNames)
            name=obj.mapNames{i};
            if iscell(name)
                if strcmp(name,'xyz')
                    continue
                end
                if length(name) > 1
                    type=name{2};
                end
                name=name{1};
            else
                type=[];
            end
            obj.get_src(name,type);
        end

    end
    function obj=get_src(obj,hash,type)
        if ~exist('type','var') || isempty(type)
            type='img';
        end

        obj.src.(hash)=cell(1,2);
        tmp=dbImg(obj.srcInfo.database, type, hash, obj.srcInfo.I, 'L',1,obj.srcInfo.db);
        obj.src.(hash){1}=tmp.im.(hash);

        tmp=dbImg(obj.srcInfo.database, type, hash, obj.srcInfo.I, 'R',1,obj.srcInfo.db);
        obj.src.(hash){2}=tmp.im.(hash);
    end
    function obj=get_src_xyz(obj)
        LR='LR';
        LorR=LR(obj.srcInfo.K);
        if isempty(obj.srcInfo.db)
            obj.srcInfo.get_db();
        end

        if isempty(obj.src)
            obj.src=struct();
        end
        obj.src.XYZ=XYZ(obj.srcInfo.database, obj.srcInfo.I);
        obj.src.xyz=obj.src.XYZ.xyz;
    end
    function obj=get_src_pht(obj)
        LR='LR';
        LorR=LR(obj.src.K);
        obj.src.pht=dbImg(obj.database, 'img', 'pht', obj.src.I, LorR,0, obj.src.db);
    end
    function obj=get_src_phtGamma(obj)
        LR='LR';
        LorR=LR(obj.src.K);
        obj.src.pht=dbImg(obj.database, 'img', 'phtGamma', obj.src.I, LorR,0, obj.src.db);
    end

%% CROP
    function obj=crop_srcs_bi(obj,type,interpType)
        if ~exist('interpType','var')
            interpType=[];
        end
        for i = 1:(min([obj.bStereo+1,2]))
            obj.crop_srcs(i,type,interpType);
            if obj.badflag; return; end
        end
    end
    function obj=crop_srcs(obj,i,type,interpType)
        nomaps={'CPs','vrg','vrs'};
        if ~exist('interpType','var')
            interpType=[];
        end
        flds=fieldnames(obj.src);
        for m=1:length(flds)
            fld=flds{m};

            if ismember(fld,nomaps) || ~ismember(fld,obj.([type 'Names']))
                continue
            else
                obj.crop_src(i,fld,type,interpType);
            end
            if obj.badflag; return; end
        end
    end
    function obj=crop_src(obj,i,fld,type,interpType)
        if ~exist('interpType','var')
            interpType=[];
        end
        if (obj.srcInfo.K==1 & i==1) || (obj.srcInfo.K==2 & i==2)
            k=1;
        elseif  (obj.srcInfo.K==1 & i==2) || (obj.srcInfo.K==2 & i==1)
            k=2;
        end

        name=[type 'sbuff'];
        im=obj.src.(fld){i};

        % PCTRRC
        PctrRC=obj.srcInfo.PctrRC;
        if iscell(PctrRC)
            PctrRC=PctrRC{i};
        end

        % GET K

        if iscell(im)
            for j= 1:length(im)
                im=Im{j};
                if iscell(PctrRC)
                    pctrRC=PctrRC{j};
                else
                    pctrRC=PctrRC;
                end
                try
                    obj.(name).(fld){i}{j}=Map.crop(im,pctrRC,obj.PszRCbuff,interpType);
                catch
                    obj.badflag=1;
                    %display(['warning: bad ptch ' num2str(i) ':' num2str(j)]);
                    return
                end
            end
        else
            try
                obj.(name).(fld){i}=Map.crop_f(im,PctrRC,obj.PszRCbuff,interpType);
            catch
                obj.badflag=1;
                %display(['warning: bad ptch ' num2str(i) ]);
                return
            end
        end

    end
end
end
