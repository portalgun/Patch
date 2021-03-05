classdef ptch_T < handle
methods
    function fnames=load_name_index(obj)
        fnames=ptch.load_name_index_f(obj.srcInfo.database,obj.srcInfo.hashes.smp)
    end
end
methods(Static=true)
    function fnames=load_name_index_f(database,hash)
        fnames=ptch.get_name_index_fname(database,hash);
    end
    function fname=get_name_index_fname(database,hash)
        dire=ptch.get_directory_p(database,hash);
        name=ptch.get_name_index_name_p();
        fname=[dire name];
    end
    function name=get_name_index_name_p()
        name='_ind_';
    end
end
end
