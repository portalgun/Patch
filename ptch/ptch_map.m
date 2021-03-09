classdef ptch_map < handle
methods
    function obj=get_maps(obj,interpType)
        if ~exist('interpType','var')
            interpType=[];
        end
        obj.crop_srcs_bi('map',interpType);
    end
%% APPLY
    function obj=apply_map_bi(obj,mapName,mskName)
        if ~exist('mskName','var')
            mskName=[];
        end
        for k = 1:min(2,(obj.bStereo+1))
            obj.apply_map(k,mapName,mskName);
        end
    end
    function obj=reapply_map_bi(obj)
        Opts=obj.im.get_opts();
        obj.clear_im();
        imList=obj.imList;
        obj.clear_imList();
        for k = 1:(obj.bStereo+1)
            for f=  1:size(imList{k},1)
                mapName=imList{k}{f,1};
                mskName=imList{k}{f,2};
                obj.apply_map(k,mapName,mskName,Opts);
            end
        end
    end
    function obj=apply_map(obj,k,mapName,mskName, Opts)
        if ~exist('mskName','var') || isempty(mskName)
            mskName='all';
        end
        if obj.bDSP
            fldmap='maps';
            fldmsk='msks';
        else
            fldmap='mapsbuff';
            fldmsk='msksbuff';
        end
        if iscell(obj.(fldmap).(mapName))
            map=obj.(fldmap).(mapName){k};
        else
            map=obj.(fldmap).(mapName);
        end
        if iscell(obj.(fldmsk).(mskName))
            msk=obj.(fldmsk).(mskName){k};
        else
            msk=obj.(fldmsk).(mskName);
        end

        obj.init_map(map,msk,k);
        if k==min(2,(obj.bStereo+1))
            obj.im=Map(obj.tmp{1},obj.tmp{2});
            obj.tmp=cell(1,2);
            if exist('Opts','var') && isstruct(Opts)
                obj.im.apply_opts(Opts);
            end
        end
        if isempty(obj.imList{k})
            obj.imList{k}=cell(0,2);
        end
        obj.imList{k}{end+1,1}=mapName;
        obj.imList{k}{end,2}=mskName;
    end
    function obj=init_map(obj,map,msk,k)
        nmap=map;
        map(~msk)=0;
        if  ~isempty(obj.im) && isa(obj,'Map')
            im=obj.im.img{k};
            im(msk)=0;
            obj.tmp{k}=map+im;
        elseif isempty(obj.im)
            obj.tmp{k}=map;
        end

    end
    function obj=clear_im(obj)
        obj.im=[];
    end
    function obj=clear_imList(obj)
        obj.imList=cell(1,2);
    end
%% SELECT
    function obj=select_map_bi(obj,k,mapName)
        for i = 1:min(2,(obj.bStereo+1))
            obj.select_map(k,mapName);
        end
    end
    function obj=select_map(obj,k,mapName)
        obj.map=obj.maps.(mapNames);
    end
%% RESET
    function obj= reset_map_disp_bi(obj)
        for k = 1: min(2,(obj.bStereo+1))
            obj.reset_map_disp(k);
        end
    end
    function obj=reset_map_disp(obj,k)
        obj.map{k}=obj.maps.pht{k};
    end
%% MAP STUFF

    function obj=fix_contrast(obj,RMSfix,DC,nChnl,monoORbino)
        if ~exist('nChnl','var')
            nCnhl=[];
        end
        if ~exist('monoORbino','var')
            monoORbino=[];
        end
        obj.im.fix_contrast(RMSfix,DC,nChnl,monoORbino);
    end
    function obj=faux_gamma_correct(obj)
        obj.im.faux_gamma_correct_bi();
    end
    function obj=faux_gamma_uncorrect(obj)
        obj.im.faux_gamma_uncorrect_bi();
    end

end
end
