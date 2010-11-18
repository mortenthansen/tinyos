function generate_graphs()

%folder = '2b_smallramp1to128_lpl100_delay10_period1000_init9_battery200';
%folder = '2b_smallramp1to128_lpl500_delay10_period2000_init9_battery200';
folder = '2b_smallramp1to128_lpl512_delay10_period2048_init9_battery200';

files = what(folder);
files = files.mat;

for f=1:length(files)
    load(strcat(folder,'/',files{f}));
    [name ext] = strtok(files{f},'.');
    data.(name) = nodes;
end

importance_graph(data);