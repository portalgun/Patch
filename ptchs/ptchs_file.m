classdef ptchs_file < handle
methods
%% 1
    function obj=save(obj)
        obj.clear_loaded_patches();
        fname=obj.get_fname();
        P=obj;
        save(fname,'P');
    end
    function fname=get_fname(obj)
        if obj.MODE==-1
            fname=obj.get_dmp_fname();
        elseif obj.MODE==1
            fname=obj.get_tst_fname();
        elseif obj.MODE==2
            fname=obj.get_trn_fname();
        elseif obj.MODE==3
            fname=obj.get_pil_fname();
        end
    end
    function dire=get_dir(obj)
        if obj.MODE==-1
            dire=obj.get_dmp_dir();
        elseif obj.MODE==1
            dire=obj.get_tst_dir();
        elseif obj.MODE==2
            dire=obj.get_trn_dir();
        elseif obj.MODE==3
            dire=obj.get_pil_dir();
        end
    end
%% 2
    function fname=get_trn_fname(obj)
        ptchs.get_fname_p('trn',obj.hashes.database,obj.name,mode);
    end
    function fname=get_tst_fname(obj)
        ptchs.get_fname_p('tst',obj.hashes.database,obj.name);
    end
    function fname=get_pil_fname(obj)
        ptchs.get_fname_p('pil',obj.hashes.database,obj.name);
    end
    function dire=get_tst_dir(obj)
        dire=ptchs.get_dir_p(obj.hashes.database);
    end
    function dire=get_trn_dir(obj)
        dire=ptchs.get_dir_p(obj.hashes.database);
    end
    function dire=get_pil_dir(obj)
        dire=ptchs.get_dir_p(obj.hashes.database);
    end
    function fname=get_dmp_fname(obj)
        dire=obj.get_dmp_dir;
        fname=[dire '_P_'];
    end
    function dire=get_dmp_dir(obj)
        if isfield(obj.hashes,'dsp') && ~isempty(obj.hashes.dsp)
            dire=ptch.get_directory_dsp_p(obj.hashes.database, obj.hashes.dsp );
        else
            dire=ptch.get_directory_p(obj.hashes.database, obj.hashes.pch);
        end

    end
end
methods(Static=true)
% TRN/TST
    function dire=get_dir_p(database,name)
        database=[database 'exp'];
        rootDBdir=imapCommon.get_rootDBdir(database);
        dire=[rootDBdir name filesep];
    end
%% DMP
    function dire=get_dmp_dir_p(database,hash)
        dire=ptch.get_directory_p(database,hash);
    end
end
end
