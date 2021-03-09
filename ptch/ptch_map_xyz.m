classdef ptch_map_xyz < handle
properties
end
methods
%% UPDATE
    function obj=get_trgt_CPs(obj)
        % TRGT INFO
        % NOTE: pointW not pointD ->
        %    we want to know how much to shift the patch
        dsp=obj.win.diffDSP;
        CPs=cellfun(@fliplr, obj.win.trgt.pointW.posXYpix(), UO,false);
        % IN CORNER COORDINATES (RIGHT?)

        [obj.PctrCPs{1}, obj.PctrCPs{2}]= ...
        XYZ.add_dsp(CPs{1},...
                    CPs{2},...
                    dsp,...
                    'C',...
                    obj.Disp.CppXm,...
                    obj.Disp.CppYm,...
                    obj.Disp.CppZm,...
                    obj.subjInfo.IPDm ...
        );

        scrnCtr=(fliplr(obj.Disp.scrnXYpix)./2);
        buffCtr=(obj.PszRCbuff./2);
        for i = 1:2
            % from scrn corner to central coordinates...
            obj.PctrCPs{i}=obj.PctrCPs{i}-scrnCtr;
            % ... to buff corner coordinates
            obj.PctrCPs{i}=obj.PctrCPs{i}+buffCtr;

        end
    end
    function obj=get_map_CPs_bi(obj);
        for i=1:2
            obj.get_map_CPs(i);
        end
    end
    function obj=get_map_CPs(obj,i);
        if isempty(obj.PctrCPs)
            obj.PctrCPs{i}=cell(1,2);
            obj.PctrCPs{1}=[0,0];
            obj.PctrCPs{2}=[0,0];
        end
        % SHIFT CPS BY APPLIED DISPARITY
        CPs{1}=obj.CPsBuff{i}{1}-obj.PctrCPs{1};
        CPs{2}=obj.CPsBuff{i}{2}-obj.PctrCPs{2};
        %CPs{1}
        %CPs{2}

        % Patch pix to display pix, resize to window size
        R=fliplr(obj.Disp.scrnXYmm/1000)./obj.win.win.WHm;
        CPs{1}=CPs{1}.*R;
        CPs{2}=CPs{2}.*R;

        %%disp offset
        obj.maps.CPs{i}=CPs;

    end
%% XYZ
    function obj=get_map_xyz_bi(obj)
        obj.maps.xyz=cell(1,2);
        for i = 1:2
            obj.get_map_xyz(i);
        end
    end
    function obj=get_map_xyz(obj,i)
        LExyz=obj.subjInfo.LExyz;
        RExyz=obj.subjInfo.RExyz;
        IppXm=obj.Disp.CppXm;
        IppYm=obj.Disp.CppYm;
        IppZm=obj.Disp.CppZm;
        X=obj.Disp.CppXpix;
        Y=obj.Disp.CppYpix;

        if ~iscell(obj.maps.xyz)
            obj.maps.xyz=cell(1,2);
        end

        for k = 1:2
            if k ==1
                PPxyL=obj.maps.CPs{i}{k};
                PPxyR=obj.maps.CPs{i}{2};
            elseif k==2
                PPxyL=obj.maps.CPs{i}{1};
                PPxyR=obj.maps.CPs{i}{k};
            end
            obj.maps.xyz{i}{k}=XYZ.forward_project(LExyz, RExyz, PPxyL, PPxyR ,IppXm, IppYm, IppZm,X,Y);
        end
        % XXX CROP?

    end
%% VRG ALL
   function obj=get_map_vrg_bi(obj)
        obj.maps.vrg=cell(1,2);
        obj.maps.vrs=cell(1,2);
        for i = 1:2
            obj.get_vrg(i);
        end
    end
    function vrg=get_map_vrg(obj,i)
        obj.maps.vrg{i}=cell(1,2);
        obj.maps.vrs{i}=cell(1,2);
        for k = 1:2
            [obj.maps.vrg{i}{k},obj.maps.vrs{i}{k}]=XYZ.vrg_vrs(obj.maps.xyz{i}{k},obj.subjInfo.LExzy,obj.subjInfo.RExyz);
        end
        % XXX CROP?
    end
%% STATS

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
            Ximg=imapGenModules.(meth)(setOpts,maps{:},set{:},ob{:},db{:},lr{:});

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
%% UPDATE
    function obj=change_display(obj)
        % TODO
    end
    function obj=change_win_WH(obj,mORpixORdegORraw,WH,val,val2)
        % TODO
    end
    function obj=change_win_loc(obj,mORpixORdegORraw,val,val2)
        % TODO
    end
    function obj=change_target_loc(obj,dspORwin,mORpixORdegORraw,val,val2)
        % TODO
    end
    function obj=change_focus_loc(obj,dspORwin,mORpixORdegORraw,val,val2)
        % TODO
    end
    function obj=change_subj(obj,IPDm,LExyz,RExyz)
        % XXX defaults before
        % XXX
    end
end
end
