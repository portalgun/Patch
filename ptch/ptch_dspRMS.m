classdef ptch_dspRMS < handle & ptch_link
methods
    function [map,src,buff,buffT]=getDspRMS(obj)
        src=obj.getDspRMSSrc();
        buffT=obj.getDspRMST();

        buff=obj.getDsp2Buff();
        buff0=obj.getDsp2Buff([],[],true);
        map=obj.getDsp2Map();
    end
    function dspRMS=getDspRMSD(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        if k==1
            LorR='L';
            nk=2;
        else
            LorR='R';
            nk=1;
        end
        obj.get_xyz_display();
        xyz=obj.maps.xyzD{k};

        %imagesc(xyz(:,:,1))
        %dk
        %imagesc(xyz(:,:,2))
        %dk
        %W=ones(size(xyz(:,:,1))); % XXX
        Wk=100; % XXX
        dim=0; % XXX
        Opts=struct('Wk',Wk,'IPDm',obj.win.subjInfo.IPDm,'LorRorC','C','bConv',false,'dnk',1,'dim',0,'winPosXYZm',obj.win.win.posXYZm);
        dspRMS=XYZ.disparity_contrast(xyz, obj.PszRC,Opts);
    end
    function dspRMS=getDspRMST(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        if k==1
            LorR='L';
            nk=2;
        else
            LorR='R';
            nk=1;
        end
        xyz=obj.getMapBuffT('xyz',k);
        Wk=100; % XXX
        Opts=struct('Wk',Wk,'IPDm',obj.win.subjInfo.IPDm,'LorRorC','C','bConv',false,'dnk',1);
        dspRMS=XYZ.disparity_contrast(xyz, obj.PszRC,Opts);
        %% NOTE IN ARCMIN
    end
    function dspRMS=getDspRMSSrc(obj,k)
        if nargin < 2 || isempty(k)
            k=obj.srcInfo.K;
        end
        name=obj.srcInfo.genOpts.type.name;
        imgName=obj.srcInfo.genOpts.type.setParams.imgName;
        if strcmp(name,'X_disparity_contrast') || (strcmp(name,'X_copy') && strcmp(imgName,'gen.DspRms'))
            dspRMS=obj.srcInfo.Val; % XXX
            %dspRMS=obj.srcInfo.binVal;
        else
            dspRMS=[];
        end
    end
end
end
