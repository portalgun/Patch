classdef ptch_xyzD < handle & ptch_link
methods
    function obj=get_xyz_display(obj,offset,I)
        if nargin < 3
            I=1:2;
        end
        if nargin < 2
            offset=obj.WszRCPixOffset;
        end
        for k = I
            %[~,nk]=CPs.getK(k);
            LitpRC=obj.CPsBuff{k}{1};
            RitpRC=obj.CPsBuff{k}{2};
            %LitpXY=fliplr(LitpRC);
            %RitpXY=fliplr(RitpRC);

            WszRCpix=fliplr(obj.win.win.WHpix)+offset;

            PszRCpix=obj.PszRC;
            PszRCpixBuff=obj.PszRCbuff;

            Sctr=obj.win.VDisp.ctrRCpix;

            %LExyz=obj.subjInfo.LExyz;
            %RExyz=obj.subjInfo.RExyz;

            %winPosRCpix=cellfun(@(x) fliplr(x)-obj.win.win.scrnCtrRCpix,obj.win.win.posXYpix,'UniformOutput',false);
            %winPosRCpix=cellfun(@(x) fliplr(x),obj.win.win.posXYpix,'UniformOutput',false);

            %AitpRC0=CPs.getAitpRC0(PszRCpixBuff);
            %db=obj.srcInfo.db;
            %[LitpRC,RitpRC]=CPs.getPatchFast(obj.srcInfo.PctrRC{k}, AitpRC0, k, obj.CPsBuff, db.IszRC, true);

            %winPosRCpix{1}
            %winPosRCpix{2}
            %LitpRCw=LitpRC;
            %RitpRCw=RitpRC;

            %obj.srcInfo.PctrRC{1}
            %obj.srcInfo.PctrRC{2}

            WszRCpixBuff=(WszRCpix.*PszRCpixBuff./PszRCpix);
            WctrRC=WszRCpixBuff/2;
            BctrRC=PszRCpixBuff/2;
            %nX=WszRCpixBuff(2);
            %nY=WszRCpixBuff(1);
            %WX=(0:nX)'-Wctr(2);
            %WY=(0:nY)'-Wctr(1);

            res=1000;

            BX=linspace(0,PszRCpixBuff(2),res)'-BctrRC(2);
            BY=linspace(0,PszRCpixBuff(1),res)'-BctrRC(1);
            WX=linspace(0,WszRCpixBuff(2),res)'-WctrRC(2);
            WY=linspace(0,WszRCpixBuff(1),res)'-WctrRC(1);


            %% size(WX)
            %% size(WY)
            %% size(BX)
            %% size(BY)

            LitpRCw=zeros(size(LitpRC));
            RitpRCw=zeros(size(RitpRC));
            %LitpRCw(:,1)=interp1(BY,WY,LitpRC(:,1),'linear')+Sctr(1);
            %RitpRCw(:,1)=interp1(BY,WY,RitpRC(:,1),'linear')+Sctr(1);
            %LitpRCw(:,2)=interp1(BX,WX,LitpRC(:,2),'linear')+Sctr(2);
            %RitpRCw(:,2)=interp1(BX,WX,RitpRC(:,2),'linear')+Sctr(2);
            %BX
            %WX
            %LitpRC(:,1)

            LitpRCw(:,1)=XYZ_project.interp1qr(BY,WY,LitpRC(:,1))+Sctr(1);
            RitpRCw(:,1)=XYZ_project.interp1qr(BY,WY,RitpRC(:,1))+Sctr(1);
            LitpRCw(:,2)=XYZ_project.interp1qr(BX,WX,LitpRC(:,2))+Sctr(2);
            RitpRCw(:,2)=XYZ_project.interp1qr(BX,WX,RitpRC(:,2))+Sctr(2);

            %% subplot(2,2,1)
            %% Plot.RC(LitpRC,'.')
            %% subplot(2,2,2)
            %% Plot.RC(RitpRC,'.')
            %% subplot(2,2,3)
            %% Plot.RC(RitpRCw,'.')
            %% subplot(2,2,4)
            %% Plot.RC(RitpRCw,'.')


            %[LitpRCw,RitpRCw]=CPs.patchPixToWinPixBuff(LitpRC,RitpRC, ...
            %                                      WszRCpix, ...
            %                                      PszRCpix,PszRCpixBuff, ...
            %                                      winPosRCpix{1},winPosRCpix{2});


            xyzRC=obj.Disp.PP.forward_project(LitpRCw,RitpRCw);
            %xyzRC=XYZ.forward_project(...
            %                    LExyz,RExyz,...
            %                    ... %fliplr(LitpRC)+obj.Disp.scrnCtrXY,fliplr(RitpRC)+obj.Disp.scrnCtrXY,...
            %                    fliplr(LitpRCw),fliplr(RitpRCw),...
            %                    obj.Disp.CppXm, obj.Disp.CppYm, obj.Disp.CppZm);
            %% % CHECK PP
            %% subplot(1,2,1)
            %% imagesc(obj.Disp.CppYm)
            %% colorbar
            %% subplot(1,2,2)
            %% imagesc(obj.Disp.CppXm)
            %% colorbar
            %% dk

            %% numel(LitpRC)
            %% numel(LitpRCw)
            %% numel(RitpRCw)
            %% numel(RitpRC)
            %% numel(xyzRC(:,:,1))

            %% figure(2)
            %% subplot(1,5,1)
            %% Plot.RC(LitpRC,'.')
            %% axis square
            %% subplot(1,5,2)
            %% Plot.RC(RitpRC,'.')
            %% axis square
            %% subplot(1,5,3)
            %% Plot.RC(LitpRCw,'.')
            %% axis square
            %% subplot(1,5,4)
            %% Plot.RC(RitpRCw,'.')
            %% axis square
            %% subplot(1,5,5)
            %% Plot.RC(xyzRC(:,[1:2]),'.')
            %% %Plot.RC3(xyzRC,'.')
            %% xlim([-.015 .015])
            %% ylim([-.015 .015])
            %% %zlim([-.015 .015])
            %% %ylim([-0 1.5])
            %% axis square

            if ~isfield(obj.mapsBuff,'xyzD')
                obj.mapsBuff.xyzD=cell(1,2);
            end
            obj.mapsBuff.xyzD{k}=permute(reshape(xyzRC,[PszRCpixBuff 3]),[2 1 3]);

            %% subplot(1,3,1)
            %% imagesc(obj.mapsBuff.xyzD{k}(:,:,1))
            %% colorbar
            %% subplot(1,3,2)
            %% imagesc(obj.mapsBuff.xyzD{k}(:,:,2))
            %% colorbar
            %% subplot(1,3,3)
            %% imagesc(obj.mapsBuff.xyzD{k}(:,:,3))
            %% colorbar

            %% xyz
            %% size(xyz)
            %% dk

            %3.7229

            if ~isfield(obj.maps,'xyzD')
                obj.maps.xyzD=cell(1,2);
                obj.mapNames{end+1}='xyzD';
            end
            obj.maps.xyzD{k}=Map.crop_f(obj.mapsBuff.xyzD{k},BctrRC,obj.PszRC,'linear');

            %% Num.minMax(obj.mapsBuff.xyzD{k}(:,:,1))
            %% w=sum(abs(Num.minMax(obj.maps.xyzD{k}(:,:,1))));
            %% h=sum(abs(Num.minMax(obj.maps.xyzD{k}(:,:,2))));
            %% w*obj.Disp.degPerMxy(1);
            %% h*obj.Disp.degPerMxy(2);
        end
    end
end
end
