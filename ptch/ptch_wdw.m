classdef ptch_wdw < handle
methods
end
methods(Static=true)
    function wdw=gen_wdw_p(PszRC,opts)
        % XXX
        % shape % cos, rect
        % bFlt
        % WszPrcntRC
        % dskSzRC
        % rmpSzRC

        P=ptch.get_wdw_parse(PszRC,opts);
        opts=parse([],opts,P);

        valshapes={'cos','rect'};
        if ~ismember(opts.shape,valshapes)
            error('invaldi wdw shape');
        end

    end
    function out=get_wdw_parse(PszRC,opts)
        P = {'shape',[],'ischar' ...
            ;'bFlt',[],'isbinary' ...
            ;'WszRPrcntRC',[],'is' ... % XXX
            ;'dskSzRC',[],'is'  ... % XXX
            ;'rmpSzRC',[],'is' ... % XXX
        }
    end
end
end
