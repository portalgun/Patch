classdef  ptch_xyzT  < handle & ptch_link
methods
    function obj=get_xyz_transform(obj,k)
        bPlot=false;
        bStat=false;

        if isa(obj.Stats,'Stat')
            bStat=true;
            obj.Stats.next(obj);
        end
        if exist('stat','var') && isa(stat)
            bStat=true;
            obj.Stat=stat;
        end

        if ~exist('k','var') || isemty(k)
            k=obj.srcInfo.K;
        end
        % bScale
        % bSheer
        % bCenter
        % Shrink2
        N=6;

        if bStat; obj.Stats.appendV('Src',k); end;
        if bStat; obj.Stats.appendV('T',k); end;
        if bPlot; subPlot([1,N],1,1); obj.plotXYZBuffT(k); title('original'); end;

        %% GET BUFFT XYZ
        % CENTER
        if obj.bCenter
            obj.get_centered_xyz(k); % xyz -> xyz
        end
        if bStat; obj.Stats.appendV('T',k,'center'); end;
        if bPlot; subPlot([1,N],1,2); obj.plotXYZBuffT(k); title('center'); end;

        % SCALE
        if obj.bScale
            obj.get_scaled_xyz(k); % xyz -> xyz
        end
        if bStat; obj.Stats.appendV('T',k,'scale'); end;
        if bPlot; subPlot([1,N],1,3); obj.plotXYZBuffT(k); title('scale'); end;

        % SHEER
        if obj.bSheer
            obj.get_sheered_xyz(k);    % xyz -> xyz
        end
        if bStat; obj.Stats.appendV('T',k,'sheer'); end;
        if bPlot; subPlot([1,N],1,4); obj.plotXYZBuffT(k); title('sheer'); end;

        % CORRECT
        if obj.bCorrectCtrXYZ()
            obj.get_corrected_xyz(k,'mapsBuffT');
        end
        if bStat; obj.Stats.appendV('T',k,'correct'); end;
        if bPlot; subPlot([1,N],1,5); obj.plotXYZBuffT(k); title('correct'); end;

        % SHRINK
        if ~isempty(obj.shrinkTo)
            obj.get_shrunk_xyz(k);
        end
        if bStat; obj.Stats.appendV('T',k,'shrink'); end;
        if bPlot; subPlot([1,N],1,6); obj.plotXYZBuffT(k); title('shrink'); end;
        if bPlot; waitforbuttonpress(); end;

    end

%% PARTS
    function obj=get_centered_xyz(obj,k)
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
        xyz=obj.getMapBuff('xyzT',k);
        xyz=XYZ.center(xyz,obj.win.win.posXYZm);

        obj.setMapBuff(xyz,'xyzT',k);
    end
    function obj=get_scaled_xyz(obj,k)
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
        xyz=obj.getMapBuff('xyzT',k);
        xyz=XYZ.scale(xyz,obj.win.win.WHm,obj.PszRC);

        obj.setMapBuff(xyz,'xyzT',k);
    end
    function obj=get_sheered_xyz(obj,k)
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
        xyz=obj.getMapBuff('xyzT',k);

        xyz=XYZ.flatSheer(xyz,obj.win.win.WHm);

        obj.setMapBuff(xyz,'xyzT',k);
    end
    function obj=get_corrected_xyz(obj,k,type)
        xyz=obj.getCtrXYZ([],type);
        dsp=obj.win.xyzToDsp(xyz);
        obj.win.set_offsetDSP(dsp);
    end
    function obj=get_shrunk_xyz(obj,k)
        switch obj.shrinkTo
        case{'dsp2','DSP2'}
            obj.shrink_dsp2(k);
        otherwise
            error(['Unhandled shrinkTo ' obj.shrinkTo]);
        end
    end
    function obj=shrink_dsp2(obj,k)
        % getDSP2

        % DIFFERENCE
        E=obj.getDspRMSSrc(k);
        O=obj.getDspRMST(k);
        Emag=1/Num.mag(double(E));
        Omag=1/Num.mag(double(O));
        d=Emag/Omag;


        xyz=obj.getMapBuff('xyzT',k);
        %figure(10)
        %imagesc(xyz(:,:,3))
        %colorbar

        % GET CENTER Z
        ctr=floor(size(xyz)/2+1); % verified
        z=xyz(ctr(1),ctr(2),3);

        % Center
        xyz(:,:,3)=xyz(:,:,3)-z;
        obj.setMapBuff(xyz,'xyzT',k);
        C=obj.getDspRMST(k);


        % SET CONTRAST
        vrgImgX = vergenceFromRangeXYZVec('C',obj.subjInfo.IPDm,xyz,1);
        %figure(1)
        %imagesc(vrgImgX)
        %colorbar

        vrgImgX=(vrgImgX).*E./C;

        %figure(2)
        %imagesc(vrgImgX)
        %colorbar

        %[xyzB,z1,z2]=XYZ.vrgAndXToZ(vrgImg,xyz(:,:,1:2),obj.subjInfo.IPDm,2);
        [xyzX]=XYZ.vrgAndXToZ(vrgImgX,xyz(:,:,1:2),obj.subjInfo.IPDm,1);
        xyz(:,:,3)=xyzX;
        obj.setMapBuff(xyz,'xyzT',k);

        %figure(5)
        %imagesc(xyzX)
        %colorbar


        F1=obj.getDspRMST(k);
        % RECENTER
        xyz(:,:,3)=xyz(:,:,3)+z;
        obj.setMapBuff(xyz,'xyzT',k);

        F2=obj.getDspRMST(k);
        %figure(6)
        %imagesc(xyz(:,:,3))
        %colorbar

        %xyz1=xyz(:,:,3);
        %vrgImg = vergenceFromRangeXYZVec('C',obj.subjInfo.IPDm,xyz,[1,2]);
        %vrgImgY = vergenceFromRangeXYZVec('C',obj.subjInfo.IPDm,xyz,2);
        %elev=XYZ.elevation(xyz);

        %figure(1)
        %imagesc(xyz1)
        %c=caxis;
        %sgtitle('XY')
        %colorbar

        %figure(2)
        %imagesc(vrgImg)
        %sgtitle('vrgXY')
        %colorbar

        %figure(3)
        %imagesc(vrgImgX)
        %sgtitle('vrgX')
        %colorbar

        %figure(4)
        %subplot(1,3,1)
        %imagesc(real(vrgImgY))
        %axis square
        %title('real')
        %sgtitle('vrgY')
        %colorbar
        %subplot(1,3,2)
        %imagesc(imag(vrgImgY))
        %title('imag')
        %axis square
        %colorbar
        %subplot(1,3,3)
        %imagesc(elev)
        %title('elev')
        %axis square
        %colorbar

        %figure(5)
        %subplot(1,4,1)
        %imagesc(xyz1)
        %title('xyz1')
        %axis square
        %colorbar
        %subplot(1,4,2)
        %imagesc(xyz(:,:,3))
        %title('xyzX')
        %axis square
        %colorbar
        %subplot(1,4,3)
        %%imagesc(xyzB)
        %%title('xyzB')
        %%%title('z1')
        %%axis square
        %%colorbar
        %subplot(1,4,4)
        %title('xyz')
        %axis square
        %colorbar



    end
%% CPS
    function [PPxyL,PPxyR]=getCPsBuffT(obj,k)
        if isempty(obj.CPsBuffT);
            obj.CPsBuffT=cell(1,2);
        end
        if isempty(obj.CPsBuffT{k})
            obj.CPsBuffT{k}=cell(1,2);
        end
        PPxyL=obj.CPsBuffT{k}{1};
        PPxyR=obj.CPsBuffT{k}{2};
    end
    function out=get_transform_CPs(obj,I)
        if nargin < 2
            I=1:2;
        end
        for k=I
            Axyz=obj.getMapBuff('xyzT',k);

            IPDm=obj.win.subjInfo.IPDm;
            AExyz=[0 0 0];

            f=obj.PszRCbuff./obj.PszRC;
            [AppXm,AppYm,AppZm] =obj.win.getWinPP('C');
            %[AppXm,AppYm,AppZm] =obj.win.getWinPP(LorR);
            %AppXm=imresize(AppXm,obj.PszRCbuff);
            %AppYm=imresize(AppYm,obj.PszRCbuff);
            xyz=reshape(Axyz,[prod(size(Axyz(:,:,1))),3]);
            if k==1
                CExyz     = [+IPDm/2 0 0];
                BExyz     = [+IPDm   0 0];
                Axyz(:,:,1)=Axyz(:,:,1)+CExyz(1)-AExyz(1);
                Bxyz(:,:,1)=Axyz(:,:,1)+CExyz(1)-BExyz(1);
            else
                CExyz     = [-IPDm/2 0 0];
                BExyz     = [-IPDm   0 0];
                Axyz(:,:,1)=Axyz(:,:,1)-IPDm/2;
                Bxyz(:,:,1)=Axyz(:,:,1)+IPDm/2;
            end
            M=bsxfun(@plus,Bxyz,reshape(BExyz,1,1,3));
            IszRC=size(AppXm);

            %BP METHOD
            [X,Y]=meshgrid(1:IszRC(2),1:IszRC(1));
            [PPxyL,PPxyR]=XYZ.back_project(obj.subjInfo.LExyz,obj.subjInfo.RExyz,xyz,AppXm,AppYm,AppZm,X,Y);
            obj.CPsBuffT{k}{1}=PPxyL;
            obj.CPsBuffT{k}{2}=PPxyR;
            obj.mapsBuffT.xyz{k}=Axyz;
        end

    end
%% MAPS
    function out=get_transform_maps(obj,k)
        if ~exist('k','var') || isempty(k)
            k=obj.srcInfo.K;
        end
        yesmaps={'CPs','xyz','vrg','vrs'};
        for i = 1:length(obj.mapNames)
            if ismember(obj.mapNames{i},yesmaps)
                continue
            else
                obj.get_transform_map(k,obj.mapNames{i});
            end
        end
    end

    function out=get_transform_map(obj,k,mapName)

        IszRC=obj.PszRCbuff;
        map=obj.getMapBuff(mapName,k);
        [PPxyL,PPxyR]=obj.getCPsBuff(k);

        % SCATTERRED
        [pnL,pnR]=XYZ.interpScattered(PPxyL,PPxyR,IszRC,map);

        obj.mapsBuff.(mapName){k}=cell(1,2);
        obj.mapsBuff.(mapName){k}{1}=pnL;
        obj.mapsBuff.(mapName){k}{2}=pnR;
    end
    function plot_transform_map(obj,k,map)
        pnL=obj.mapsBuff.(map){k}{1};
        pnR=obj.mapsBuff.(map){k}{2};


        figure(1)
        obj.plotXYZ();

        figure(10)
        imagesc([pnL pnR]);
        Fig.formatIm;
        figure(11)
        imagesc([pht]);
        Fig.formatIm;

    end
end
end
