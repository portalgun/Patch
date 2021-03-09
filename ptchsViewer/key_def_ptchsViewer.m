classdef key_def_ptchsViewer < handle & key_def_vim & key_def
methods
    function obj=key_def_ptchsViewer();
        obj@key_def_vim();

        %obj.n('\n')  ='';
        %obj.n('\]')  ='';

        obj.n('\B')  ='';
        obj.n('\t')  ={'run','fld_next'};
        obj.n('\tS') ={'run','fld_prev'};
        obj.n('\s')  ={'run','flag_next'};
        obj.n('\sS') ={'run','flag_prev'};

        obj.n('a')   = {{'run','mode','c'}, {'set','str','insert_str','disparity '}};;
        obj.n('b')   = {'run','b'};
        obj.n('c')   = {{'run','mode','c'}, {'set','str','insert_str','clim '}};;
        obj.n('d')   ='';
        obj.n('e')   ='';
        %obj.n('f')   = {{'run','mode','c'}, {'set','str','insert_str','filter '}};;
        obj.n('f')   = {{'run','mode','c'}, {'set','str','insert_str','filter '}};;
        %obj.n('g')   ='';
        %obj.n('h')   ={'run','left'};
        %obj.n('i')   ='';
        %obj.n('j')   ={'run','down'};
        %obj.n('k')   ={'run','up'};
        %obj.n('l')   ={'run','next'};
        obj.n('m')   ='';
        obj.n('n')   ='';
        obj.n('o')   = {{'run','mode','c'}, {'set','str','insert_str','sort '}};;
        obj.n('p')   ='';
        obj.n('q')   ='';
        obj.n('r')   ={'run','r'};
        obj.n('s')   ='';
        obj.n('t')   ='';
        obj.n('u')   ='';
        obj.n('v')   ='';
        obj.n('w')   ='';
        obj.n('x')   ='';
        obj.n('y')   ='';
        obj.n('z')   ='';

        obj.n('A')   ='';
        obj.n('B')   ='';
        obj.n('C')   ='';
        obj.n('D')   ={'run','clear_filter'};
        obj.n('E')   ='';
        obj.n('F')   ='';
        obj.n('G')   ='';
        obj.n('H')   ='';
        obj.n('I')   ='';
        obj.n('J')   ='';
        obj.n('K')   ='';
        obj.n('L')   ='';
        obj.n('M')   ='';
        obj.n('N')   ='';
        obj.n('O')   = {{'run','mode','c'}, {'set','str','insert_str','sortrev '}};;
        obj.n('P')   ='';
        obj.n('Q')   ='';
        obj.n('R')   ='';
        obj.n('S')   ='';
        obj.n('T')   ='';
        obj.n('U')   ='';
        obj.n('V')   ='';
        obj.n('W')   ='';
        obj.n('X')   ='';
        obj.n('Y')   ='';
        obj.n('Z')   ='';

        %obj.n('1')   ='';
        %obj.n('2')   ='';
        %obj.n('3')   ='';
        %obj.n('4')   ='';
        %obj.n('5')   ='';
        %obj.n('6')   ='';
        %obj.n('7')   ='';
        %obj.n('8')   ='';
        %obj.n('9')   ='';
        %obj.n('0')   ='';

        obj.n('!')   ='';
        obj.n('?')   ='';
        obj.n('@')   ='';
        obj.n('#')   ='';
        obj.n('$')   ='';
        obj.n('%')   ='';
        obj.n('^')   ='';
        obj.n('*')   ='';
        obj.n('(')   ='';
        obj.n(')')   ='';
        obj.n('[')   ='';
        obj.n(']')   ='';
        obj.n('{')   ='';
        obj.n('}')   ='';
        obj.n('+')   ='';
        obj.n('-')   ={'run','zoom_out'};
        obj.n('=')   ={'run','zoom_in'};
        obj.n(':')   ={{'run','mode','c'}, {'set','str','insert_str',''}};;
        obj.n('.')   ='';
        obj.n(',')   ='';
        obj.n('\')   ='';

        obj.n('\R')  ='';
        obj.n('\L')  ='';
        obj.n('\U')  ='';
        obj.n('\D')  ='';


    end
end
end
