classdef ptch_src < handle & ptch_link
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
        if (nargin < 2 || isempty(hash))  && ~strcmp(type,'img')
            hash=obj.srcInfo.hashes.(type);
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
    function obj=crop_srcs(obj,type,interpType,bXYZ,I)
        if nargin < 5
            I=1:(min([obj.bStereo+1,2]));
        end
        if nargin < 4 || isempty(bXYZ)
            bXYZ=true;
        end
        nomaps={'CPs','vrg','vrs'};
        if nargin < 3
            interpType=[];
        end
        flds=fieldnames(obj.src);
        for m=1:length(flds)
            fld=flds{m};

            if ismember(fld,nomaps) || ~ismember(fld,obj.([type 'Names'])) || (~bXYZ && strcmp(fld,'xyz'))
                continue
            else
                for k=I
                    obj.crop_src(k,fld,type,interpType);
                end
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

        name=[type 'sBuff'];
        im=obj.src.(fld){i};

        % PCTRRC
        PctrRC=obj.srcInfo.PctrRC;
        if iscell(PctrRC)
            PctrRC=PctrRC{i};
        end

        if strcmp(fld,'xyz')
            fld='xyzS';
            if ~ismember('xyzS',obj.mapNames)
                obj.mapNames{end+1}='xyzS';
                obj.mapNames(ismember(obj.mapNames,'xyz'))=[];
            end
        end

        if iscell(im)
            for j= 1:length(im)
                im=Im{j};
                if iscell(PctrRC)
                    pctrRC=PctrRC{j};
                else
                    pctrRC=PctrRC;
                end
                %try
                    obj.(name).(fld){i}{j}=Map.crop(im,pctrRC,obj.PszRCbuff,interpType);
                %catch
                    %obj.badflag=1;
                    %display(['warning: bad ptch ' num2str(i) ':' num2str(j)]);
                    %return
                %end
            end
        else

            if ~isfield(obj.(name),fld)
                obj.(name).(fld)=cell(1,2);
            end

            %% PctrRC
            %% obj.PszRCbuff
            %% i
            %% fld
            %% disp(newline)

            %try
                obj.(name).(fld){i}=Map.crop_f(im,PctrRC,obj.PszRCbuff,interpType);
            %catch ME
            %    obj.badflag=1;
                %display(['warning: bad ptch ' num2str(i) ]);
            %    disp(ME)
            %    return
            %end

        end

    end
%%- RAW
    function obj=get_raw_CPs_bi(obj)
        for k=1:2
            [obj,exitflag]=obj.get_raw_CPs(k);
            if exitflag==1
                break
            end
        end
    end
    function [obj,exitflag]=get_raw_CPs(obj,k)
        % XXX BAD
        dk
        if k==1; nk=2; elseif k==2 nk=1; end;
        ActrRC=obj.srcInfo.PctrRC{k};
        if isempty(obj.srcInfo.db)
            obj.srcInfo.get_db();
        end

        if isempty(obj.PszRCbuff) && ~isempty(obj.PszRC)
            PszRC=obj.PszRC;
        elseif ~isempty(obj.PszRCbuff)
            PszRC=obj.PszRCbuff;
        end


        [AitpRC,BitpRC, BctrRC]=obj.src.XYZ.get_CPs_patch(k,ActrRC,PszRC);

        if isempty(obj.srcInfo.PctrRC{nk})
            obj.srcInfo.PctrRC{nk}=BctrRC;
            exitflag=1;
        else
            exitflag=0;
        end

        obj.src.CPs=cell(2,1);
        obj.src.CPs{k}=cell(1,2);
        obj.src.CPs{k}{k}=AitpRC{1};
        obj.src.CPs{k}{nk}=AitpRC{2};

        obj.src.CPs{nk}{nk}=BitpRC{1};
        obj.src.CPs{nk}{k}=BitpRC{2};
    end
%% VRG
    function obj=get_raw_vrg_bi(obj)
        for k=1:2
            obj.get_raw_vrg(k);
        end
    end
    function obj=get_raw_vrg(obj,i)
        xyz=obj.src.xyz{i};
        LExyz=obj.srcInfo.db.LExyz;
        RExyz=obj.srcInfo.db.RExyz;

        [vrgDeg,vrsDeg]=XYZ.get_vrg_vrs_map(xyz,LExyz,RExyz);

        obj.src.vrg{i}=vrgDeg;
        obj.src.vrs{i}=vrsDeg;
    end
%% DISPARITY
    function obj=add_raw_disparity_bi(obj,vrgDeg)
        obj.dCPs=cell(2,1);
        for i = 1:2
            obj.dCPs{i}=obj.add_raw_disparity(vrgDeg,i);
        end
    end
    function dspCps=add_raw_dispary(obj,vrgDeg,i)
        CPs=obj.src.CPs;
        db=obj.srcInfo.db;

        dspCPs=cell(1,2);
        [dspCPs{i},dspCP{i},~]=XYZ.add_disparity(CPs{1},CPs{2},vrgDeg{i}*60,db.IppXm{1},db.IppYm{1},db.IppXm{2},db.IppYm{2},db.IppZm,db.IPDm);

    end
end
methods(Static)
    function src=getSrc(database,imgNames,I, db, AitpRC0)
        src=struct();

        if ~exist('db','var') || isempty(db)
            db=dbInfo(database);
        end

        for i = 1:length(imgNames)
            name=imgNames{i};
            if strcmp(name,'xyz')
                continue
            end
            src.(name)=cell(1,2);
            for k = 1:2
                src.(name){k}=dbImg.getImg(database,'img',name,I,k);
            end
        end

        % XYZ
        src.xyz=dbImg.getImg(database,'img','xyz',I,'B',1,db);
        % NOTE DO NOT USE XYZ CP lookup FOR PATCH CROPPING!
        src.CPs=CPs.loadLookup(database,I,0,0);
        src.AitpRC0=AitpRC0;
    end
    function [Opts]=get_src_opts(defName)
        [~,modOpts]=ImapOpts.get(defName,'tbl');
        Opts=modOpts.tbl;
    end
end
end
