classdef ptch_msk < handle
methods
    function obj=get_default_masks(obj)
        obj.msksbuff.all=true(obj.PszRCbuff);
        obj.msks.all=true(obj.PszRC);

        obj.msksbuff.none=false(obj.PszRCbuff);
        obj.msks.none=false(obj.PszRC);
    end
    function obj=get_masks(obj)
        if ~exist('interpType','var')
            interpType=[];
        end
        obj.crop_srcs_bi('msk',interpType);
    end
%% SELECT
    function obj=select_mask_bi(obj,k,mskName)
        for i = 1:(obj.bStereo+1)
            obj.select_map(k,mskName);
        end
    end
    function obj=select_msk(obj,k,mskName)
        obj.msk=obj.msks.(mskNames);
    end
%% RESET
    function obj= reset_mask_disp_bi(obj)
        for k = 1:(obj.bSetereo+1)
            obj.reset_mask_disp(k);
        end
    end
    function obj=reset_mask_disp(obj,k)
        obj.msk{k}=true(size(obj.maps.pht));
    end
end
methods(Static=true)
    function out=apply_to_mask(A,msk,bg)
        % XXX
    end
end
end
