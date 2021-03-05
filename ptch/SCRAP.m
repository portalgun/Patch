
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
