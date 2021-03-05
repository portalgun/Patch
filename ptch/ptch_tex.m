classdef ptch_tex < handle
methods
    function obj=get_tex(obj,interpType,bSame)
        if ~exist('interpType','var')
            interpType=[];
        end
        if ~exist('bSame','var')
            bSame=[];
        end

        obj.crop_srcs_bi('tex',interpType);

        genNames=obj.texNames(~obj.imapPtch.isgentex(obj.texNames))
        for f = 1:length(genNames)
            genName=genNames{f};
            obj.gen_tex_bi(genName,bSame);
        end
    end
%% GEN
    function obj=gen_tex_bi(obj,genName,bSame)
        if ~exist('bSame','var') || isempty(bSame)
            bSame=1;
        end
        for k = 1:(obj.bStereo+1)
            if k ==2 & bSame
                obj.texs.(genName){2}=obj.texs.(genName){1};
            else
                obj.gen_tex(genName,k);
            end
        end
    end
    function obj=gen_tex(obj,k,genName)
        obj.texs.(genName){k}=obj.gen_tex_p(obj.PszRCbuff,genName);
    end
%% APPLY
    function obj=apply_tex_bi(obj,texName,mskName)
        if ~exist('mskName','var')
            mskName=[];
        end
        for k = 1:(obj.bSetereo+1)
            obj.apply_tex(k,texName,mskName);
        end
    end
    function obj=apply_tex(obj,k,texName,mskName)
        if ~exist('mskName','var')
            mskName=[];
        end
        tex=obj.texs.(texName){k};
        msk=obj.msks.(mksName){k};
        obj.im{k}=apply_to_msk(tex,msk,obj.im{k});
    end
%% SELECT
    function obj=select_tex_bi(obj,k,texName)
        for i = 1:(obj.bStereo+1)
            obj.select_tex(k,texName);
        end
    end
    function obj=select_tex(obj,k,texName)
        obj.tex=obj.texs.(texNames);
    end
%%  RESET
    function obj= reset_tex_disp_bi(obj)
        for k = 1:(obj.bSetereo+1)
            obj.reset_tex_disp(k);
        end
    end
    function obj=reset_tex_disp(obj,k)
        obj.tex{k}=obj.texs.pht{k};
    end


end
methods(Static=true, Hidden=true)
    function out=isgentex(list)
        %0.5
        %f2.0.5
        out=cellfun(@fun,list);
        function out=fun(in)
            out=isnum(in(2:end));
        end
    end
    function tex=gen_tex_p(PszRC,genName)
        % exp
        % rms
        % dc
        % sd
        opts=parse_str(genName);

        if inan(opts.f) && isnan(opts.rms)
            tex=ones(PszRC).*opts.dc;
            return
        elseif ~inan(opts.f) && isnan(opts.rms)
            error('tex: if no exponent specific, cannot set rms');
        elseif ~isnan(opts.f)
            tex=coloredNoise(fliplr(PszRC),opts.f,0,opt.sd);
        end

        if ~isnan(obj.rms)
            % TODO
        end

        function opts=parse_str(genName)
            opts=struct();
            opts.f=nan;
            opts.dc=0.5;
            opts.rms=nan;
            opts.sd=[];

            spl=strsplit(genName,'_')

            for i = 1:length(spl)
                opt=spl{i};
                if beginsWith(opt,'f')
                    opts.f=opt(2:end);
                elseif beginsWith(opt,'dc')
                    opts.dc=opt(3:end);
                elseif beginsWith(opt,'rms')
                    opts.rms=opt(4:end);
                elseif beginsWith(opt,'sd')
                    opts.sd=opt(3:end);
                else
                    error(['invalid tex opt ' opt])
                end
            end

        end
    end
end
end
