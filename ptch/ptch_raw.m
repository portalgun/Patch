classdef ptch_raw < handle
properties
end
methods
%% GET CPS
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
        if k==1; nk=2; elseif k==2 nk=1; end
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
%% PTCH
end
end
