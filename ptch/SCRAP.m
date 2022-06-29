
    function obj=center_CPs_db(obj)
        if obj.ctrModeXY==1
            obj.center_CPs_on_patch();
        end
        if obj.ctrModeZ==1
            obj.bring_ctr_to_db_PP_bi_comb();
        elseif obj.ctrModeZ==2
            obj.bring_ctr_to_db_PP_bi();
        end
    end
    function obj=bring_ctr_to_db_PP_bi_comb(obj)
        cps=cell(2,1);
        cps{1}=[obj.CPs{1}{1};  obj.CPs{2}{1}];
        cps{2}=[obj.CPs{1}{2};  obj.CPs{2}{2}];
        vrgDeg=get_ptch_cntr_vr(cps);
        for i = 1:2
            obj.dspCPs{i}=obj.add_vrg(-1*vrgDeg,CPs{i});
        end
    end
    function obj=bring_ctr_to_db_PP_bi(obj)
        for i=1:2
            obj.dspCps{i}=obj.bring_cntr_to_db_PP_ind(i)
        end
    end
    function dspCps=bring_cntr_to_db_PP_ind(obj,i)
        vrgDeg=obj.get_ptch_cntr_vrg(CPs{i});
        obj.dspCPs{i}=obj.add_vrg(-1*vrgDeg,CPs{i});
    end

%% XXX
    function obj=get_map_CPs_bi(obj);
        for i=1:2
            obj.get_map_CPs(i);
        end
    end
    function obj=get_map_xyz_bi(obj)
        obj.maps.xyz=cell(1,2);
        for i = 1:2
            obj.get_map_xyz(i);
        end
    end

    function obj=get_map_CPs(obj,i);
    % PctrCPs
    % PszRC
    % PszRCbuff
    % Disp.scrnXYpix
    % win.win.WHPix

        bDebug=false;
        bCrop=false;
        if isempty(obj.PctrCPs)
            obj.PctrCPs{i}=cell(1,2);
            obj.PctrCPs{1}=[0,0];
            obj.PctrCPs{2}=[0,0];
        end

        if bDebug || bCrop
            obj.rm_CPs_outside_buff_bi(true);
        end

        % CPsBuff are already centered at 0
        psrc=obj.srcInfo.PctrRC;
        if obj.bXYZTransform
            CPsA=obj.CPsBuffT{i}{1};
            CPsB=obj.CPsBuffT{i}{2};
        else
            CPsA=obj.CPsBuff{i}{1};
            CPsB=obj.CPsBuff{i}{2};
        end

        if bDebug
            subplot(1,2,1)
            hist(CPsA(:,1));
            subplot(1,2,2)
            hist(CPsB(:,2));
        end

        % Patch pix to display pix, resize to window size
        % Psz is grown to fin win.WHpix
        R=fliplr(obj.win.win.WHpix)./obj.PszRC;
        CPsA=CPsA.*R;
        CPsB=CPsB.*R;

        if bDebug
            subplot(1,2,1)
            hist(CPsA(:,1));
            subplot(1,2,2)
            hist(CPsB(:,1));
        end

        scrnCtr=fliplr(obj.Disp.scrnXYpix./2);
        % Center at new center

        % NO DISPARITY ADDITY
        CPsA=CPsA+scrnCtr;
        CPsB=CPsB+scrnCtr;
        %CPs{1}=CPsA
        %CPs{2}=CPsB
        %
        buffCtr=obj.PszRCbuff./2;
        CPs{1}=CPsA-obj.PctrCPs{1}-buffCtr;
        CPs{2}=CPsB-obj.PctrCPs{2}-buffCtr;

        if bDebug
            subplot(1,2,1)
            hist(CPs{1}(:,1));
            subplot(1,2,2)
            hist(CPs{2}(:,1));
        end

        %%disp offset
        %obj.maps.CPs{i}=CPs;
        obj.CPs{i}=CPs;

    end
    function obj=get_map_xyz(obj,i)
        % CPs
        % subjInfo
        % DIsp
        % xyz

        bPlot=false;

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

        if i==1
            PPxyL=fliplr(obj.CPs{i}{1});
            PPxyR=fliplr(obj.CPs{i}{2});
        else
            PPxyL=fliplr(obj.CPs{i}{1});
            PPxyR=fliplr(obj.CPs{i}{2});
            %PPxyL=fliplr(obj.maps.CPs{i}{2});
            %PPxyR=fliplr(obj.maps.CPs{i}{1});
        end

        %magesc(obj.mapsBuff.xyz{2})
        out=XYZ.forward_project(LExyz, RExyz, PPxyL, PPxyR ,IppXm, IppYm, IppZm,X,Y);
        % XYZ ponts
        out=sortrows(out(any(~isnan(out),2),:));
        %[~,ind]=unique(out(:,1:2),'rows');


        x=obj.win.win.WHm(1);
        xp=obj.win.win.posXYZm(1)+x;
        xm=obj.win.win.posXYZm(1)-x;

        y=obj.win.win.WHm(2);
        yp=obj.win.win.posXYZm(2)-y;
        ym=obj.win.win.posXYZm(2)+y;

        zp=max(out(:,3),[],'all');
        zm=obj.win.win.posXYZm(3);

        nx=obj.PszRCbuff(2)*1.25;
        ny=obj.PszRCbuff(1)*1.25;
        nz=1000;

        PszXY=floor([nx/2 ny/2]+1);

        %%
        %Z
        [X,Y]=meshgrid( ...
            linspace(xm,xp,nx), ...
            linspace(ym,yp,ny) ...
        );
        F=scatteredInterpolant(out(:,1),out(:,2),out(:,3),'natural','none');
        img=F(X,Y);

        crp=Map.cropImgCtr(img,[],PszXY);
        z=imresize(crp,obj.PszRC);


        %% X
        %[Y,Z]=meshgrid( ...
        %    linspace(ym,yp,ny), ...
        %    linspace(zm,zp,nz) ...
        %);

        %warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
        F=scatteredInterpolant(out(:,1),out(:,2),out(:,1),'natural','none');
        %warning('on','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
        img=F(X,Y);

        crp=Map.cropImgCtr(img,[],PszXY);
        x=imresize(crp,obj.PszRC);

        % XXX
        %% Y
        %[X,Z]=meshgrid( ...
        %    linspace(xm,xp,nx), ...
        %    linspace(zm,zp,nz) ...
        %);
        F=scatteredInterpolant(out(:,1),out(:,2),out(:,2),'natural','none');
        img=F(X,Y);
        crp=Map.cropImgCtr(img,[],PszXY);
        y=imresize(crp,obj.PszRC);

        obj.maps.xyz{i}=cat(3,x,y,z);

        % XY
        %Xp=obj.win.win.posXYZm(1)+x/2;
        %Xm=obj.win.win.posXYZm(1)-x/2;
        %Yp=obj.win.win.posXYZm(2)-y/2;
        %Ym=obj.win.win.posXYZm(2)+y/2;
        %[x,y]=meshgrid( ...
        %    linspace(Xm,Xp,obj.PszRC(2)), ...
        %    linspace(Ym,Yp,obj.PszRC(1)) ...
        %);


        if bPlot
            subplot(1,4,1)
            imagesc(obj.mapsBuff.xyz{i}(:,:,3));
            axis square;

            subplot(1,4,3)
            Plot.RC3(out,'.');
            xlim([-0.020,0.020]);
            zlim([-0.020,0.020]);
            axis square;

            subplot(1,4,2)
            imagesc(img);
            colorbar;
            axis square;

            subplot(1,4,4)
            imagesc(crp);
            axis square;
        end

    end
%% XXX
