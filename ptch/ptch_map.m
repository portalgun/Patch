classdef ptch_map < handle & ptch_link
%%- --PUBLIC--
methods
%%- XYZ
    function vrg=get_map_vrg(obj,I)
        if nargin < 2
            I = 1:2;
            obj.maps.vrg=cell(1,2);
            obj.maps.vrs=cell(1,2);
        end
        for i=I
            obj.maps.vrg{i}=cell(1,2);
            obj.maps.vrs{i}=cell(1,2);
            for k = 1:2
                [obj.maps.vrg{i}{k},obj.maps.vrs{i}{k}]=XYZ.vrg_vrs(obj.maps.xyz{i}{k},obj.subjInfo.LExzy,obj.subjInfo.RExyz);
            end
        end
        % XXX CROP?
    end
%%- WDW
    function wdw=gen_wdw_p(PszRC,opts)
        % XXX
        % shape % cos, rect
        % bFlt
        % WszPrcntRC
        % dskSzRC
        % rmpSzRC

        P=ptch.get_wdw_parse(PszRC,opts);
        opts=Args.parse([],P,opts);

        valshapes={'cos','rect'};
        if ~ismember(opts.shape,valshapes)
            error('invaldi wdw shape');
        end

    end
%%- MSK
%% GET
    function obj=get_tex(obj,interpType,bSame)
        if ~exist('interpType','var')
            interpType=[];
        end
        if ~exist('bSame','var')
            bSame=[];
        end

        obj.crop_srcs('tex',interpType);

        genNames=obj.texNames(~Tx.isgen(obj.texNames));
        for f = 1:length(genNames)
            genName=genNames{f};
            obj.gen_tex(genName,bSame);
        end
    end
%% SELECT
    function obj=select_mask(obj,k,mskName,I)
        if nargin < 4
            I=1:2;
        end
        for k=I
            obj.msk=obj.msks.(mskNames);
        end
    end
%% UPDATE
    function obj=get_masks(obj)
        if ~exist('interpType','var')
            interpType=[];
        end
        obj.crop_srcs('msk',interpType);
    end
%% RESET
    function obj= reset_mask_disp(obj,I)
        if nargin < 2
            I=1:2;
        end
        for k = I
            obj.msk{k}=true(size(obj.maps.pht));
        end
    end

%%- TEX
%% GEN
    function obj=gen_tex(obj,genName,bSame,I)
        if nargin < 4
            I=1:2;
        end
        if ~exist('bSame','var') || isempty(bSame)
            bSame=1;
        end
        for k = I
            if k ==2 & bSame
                obj.texs.(genName){2}=obj.texs.(genName){1};
            else
                obj.texs.(genName){k}=Tx.gen(obj.PszRCbuff,genName);
            end
        end
    end
%% APPLY
    function obj=apply_tex(obj,texName,mskName,I)
        if nargin < 4
            I=1:2;
        end
        if nargin < 3
            mskName=[];
        end
        for k = I
            tex=obj.texs.(texName){k};
            msk=obj.msks.(mksName){k};
            obj.im{k}=apply_to_msk(tex,msk,obj.im{k});
        end
    end
%% SELECT
    function obj=select_tex(obj,texName,I)
        if nargin < 3
            I=1:2;
        end
        for k = I
            obj.tex=obj.texs.(texNames);
        end
    end
%%  RESET
    function obj= reset_tex_disp(obj,I)
        if nargin < 2
            I=1:2;
        end
        for k = I
            obj.reset_tex_disp(k);
            obj.tex{k}=obj.texs.pht{k};
        end
    end
%% UPDATE
    function obj=get_maps(obj,interpType)
        if ~exist('bXYZ','var')
            bXYZ=[];
        end
        if ~exist('interpType','var')
            interpType=[];
        end
        obj.crop_srcs('map',interpType,bXYZ);
    end
%% APPLY
    function apply_map(obj,mapName,mskName,Opts,I)
        if nargin < 4
            I=1:2;
        end
        if ~exist('mskName','var') || isempty(mskName)
            mskName='all';
        end
        if obj.bDSP
            fldmap='maps';
            fldmsk='msks';
        else
            fldmap='mapsBuff';
            fldmsk='msksBuff';
        end
        for k = I
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
                obj.im=Map(obj.tmp{1},obj.tmp{2}); % SLOW
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
    end
    function obj=reapply_map(obj,I)
        if nargin < 2
            I=1:2;
        end
        if isempty(obj.im)
            return
        end
        Opts=obj.im.get_opts();
        obj.clear_im();
        imList=obj.imList;
        obj.clear_imList();
        for k = I
            for f = 1:size(imList{k},1)
                mapName=imList{k}{f,1};
                mskName=imList{k}{f,2};
                obj.apply_map(mapName,mskName,Opts,k);
            end
        end
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
%% CLEAR
    function obj=clear_im(obj)
        obj.im=[];
    end
    function obj=clear_imList(obj)
        obj.imList=cell(1,2);
    end
%% SELECT
    function map=select_map_bi(obj,mapName)
        map=obj.maps.(mapName);
        map=[map{1} map{2}];
    end
    function obj=select_map(obj,k,mapName)
        obj.map=obj.maps.(mapName);
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
    function obj=zero(obj)
        if obj.bZeroed
            return
        end

        obj.trgtDspOld=obj.trgtInfo.trgtDsp;
        obj.trgtInfo.trgtDsp=0;

        if obj.bDSP
            obj.update_dsp();
        end
        obj.bZeroed=true;
    end
    function obj=unzero(obj)
        if ~obj.bZeroed
            return
        end

        obj.trgtInfo.trgtDsp=obj.trgtDspOld;

        if obj.bDSP
            obj.update_dsp();
        end
        obj.bZeroed=true;
    end
    function obj=flatten(obj,flatAnchor)
        old=obj.flatAnchor;
        if isempty(old)
            old=0;
        end
        if nargin < 2 && isempty(obj.flatAnchor)
           flatAnchor=obj.srcInfo.LorR;
        elseif nargin < 2
            flatAnchor=obj.flatAnchor;
        end
        [k,nk]=CPs.getK(flatAnchor);
        if obj.bFlat && old == k
            return
        elseif obj.bFlat
            obj.unflatten();
        end

        for i = 1:length(obj.mapNames)
            name=obj.mapNames{i};
            obj.mapsBuffOld.(name){nk}=obj.mapsBuff.(name){nk};
            obj.mapsBuff.(name){nk}=obj.mapsBuff.(name){k};

            if isfield(obj.maps,name) && ~isempty(obj.maps.(name))
                obj.mapsOld.(name){nk}=obj.maps.(name){nk};
                obj.maps.(name){nk}=obj.maps.(name){k};
            end
        end
        for i = 1:length(obj.mskNames)
            name=obj.mskNames{i};
            mskb=obj.msksBuff.(name);
            if iscell(mskb) && ~isempty(mksb{nk})
                obj.msksBuffOld.(name){nk}=mskb{nk};
                obj.msksBuff.(name){nk}=mskb{k};
            end

            mskp=obj.msks.(name);
            if iscell(mskp) && ~isempty(mksp{nk})
                obj.msksOld.(name){nk}=msk{nk};
                obj.msks.(name){nk}=mskp{k};
            end
        end
        if obj.bDSP
            obj.update_dsp();
        else
            obj.reapply_map();
        end
        obj.flatAnchor=k;
        obj.bFlat=1;
        % XXX CPSbuff

        % XXX
        %for i = 1:length(obj.texNames)
        %    name=obj.texNames{i};
        %end

        %obj.bFlat=0;
    end
    function obj=unflatten(obj)
        if ~obj.bFlat
            return
        end
        [k,nk]=CPs.getK(obj.flatAnchor);
        for i = 1:length(obj.mapNames)
            name=obj.mapNames{i};
            obj.mapsBuff.(name){nk}=obj.mapsBuffOld.(name){nk};
            obj.mapsBuffOld.(name){nk}=[];
            if ~isempty(obj.mapsOld.(name))
                obj.maps.(name){nk}=obj.mapsOld.(name){nk};
                obj.mapsOld.(name){nk}=[];
            end
        end
        for i = 1:length(obj.mskNames)
            name=obj.mskNames{i};
            if iscell(obj.msksBuff.(name))
                obj.msksBuff.(name){nk}= obj.msksBuffOld.(name){nk};
                obj.msksBuffOld.(name){nk}=[];
            end

            if iscell(obj.msks.(name)) && ~isempty(obj.msksOld.(name))
                obj.msks.(name){nk}= obj.msksOld.(name){nk};
                obj.msksOld.(name){nk}=[];
            end
        end

        % XXX CPSbuff
        % XXX

        obj.bFlat=0;
    end

end
%%- --PROTECTED--
methods(Access= ?ptch_link)
    function obj=get_default_masks(obj)
        obj.msksBuff.all=true(obj.PszRCbuff);
        obj.msks.all=true(obj.PszRC);
        obj.mskNames{end+1}='all';
        %if ~ismember_cell('all',obj.mskNames)
        %end

        obj.msksBuff.none=false(obj.PszRCbuff);
        obj.msks.none=false(obj.PszRC);
        obj.mskNames{end+1}='none';
        %if ~ismember_cell('none',obj.mskNames)
        %end
    end
    function obj=get_gen_stats(obj)
        % UNPACK
        genOpts=obj.srcInfo.genOpts;

        X=get_X(obj,genOpts.type);
        XL=get_XL(obj,genOpts.typeL);

        function XL=get_XL(obj,typeL)
            XL=cell(numel(typeL),1);
            for l = 1:numel(typeL)
                XL{l}=cell(1,2);
                for k = 1:2
                    XL{l}{k}=get_X_bi(obj,typeL{l},k);
                end
            end
        end

        function Ximg=get_X(obj,type,k)
            meth=type.name;
            if startsWith(meth,'X_')
                meth=meth(3:end);
            end
            maps=obj.get_maps(type.maps,k);
            set=type.setOpts;
            ob=obj.get_ob(type.objParams);
            db=obj.get_db(type.dbParams);
            lr=obj.get_lorr(type.bLorR,k);
            Ximg=ImapGenModules.(meth)(setOpts,maps{:},set{:},ob{:},db{:},lr{:});

            function maps=get_maps(obj,mapsN,k)
                maps=cell(numel(mapsN),1);
                for i = 1:numel(mapsN)
                    % NOTE CHANGE TO WIN?
                    maps{i}=obj.maps.(mapsN{i}){k};
                end
            end

            function db=get_db(obj,dbParams)
                db=cell(numel(dbParams),1);
                for i = 1:numel(dbParams)
                    % NOTE CHANGE TO WININFO?
                    db{i}=obj.srcInfo.db.(dbParams{i});
                end
            end
            function db=get_ob(obj,objParams)
                db=cell(numel(objParams),1);
                for i = 1:numel(dbParams)
                    % NOTE CHANGE TO WININFO?
                    db{i}=obj.srcInfo.(objParams{i});
                end
            end
            function lr=get_lorr(obj,bLorR,k)
                if bLorR
                    lr={k};
                else
                    lr={};
                end
            end
        end
    end
%%- MAP
%%- TEX
%%- BUFF
end
methods(Static)
    function out=apply_to_mask(A,msk,bg)
        % XXX
    end
    function out=get_wdw_parse(PszRC,opts)
        P = {'shape',[],'ischar' ...
            ;'bFlt',[],'isbinary' ...
            ;'WszRPrcntRC',[],'is' ... % XXX
            ;'dskSzRC',[],'is'  ... % XXX
            ;'rmpSzRC',[],'is' ... % XXX
        }
    end
end
end
